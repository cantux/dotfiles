import contextlib
import io
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest
from unittest import mock

import configure


class ConfigurationTest(unittest.TestCase):

  def setUp(self):
    directory = tempfile.TemporaryDirectory(prefix='dns-configuration-test-')
    self.addCleanup(directory.cleanup)
    self.root = Path(directory.name)
    self.resolv_conf = self.root / 'etc/resolv.conf'
    self.resolv_conf.parent.mkdir()
    self.original_resolver = b'nameserver 192.168.0.1\n'
    self.resolv_conf.write_bytes(self.original_resolver)
    self.state_dir = self.root / 'var/lib/dotfiles-dns'
    self.stub_resolv = self.root / 'run/systemd/resolve/stub-resolv.conf'
    self.files = tuple((name, self.root / target.relative_to('/'))
                       for name, target in configure.FILES)
    self.enterContext(
        mock.patch.multiple(configure,
                            STATE_DIR=self.state_dir,
                            RESOLV_CONF=self.resolv_conf,
                            STUB_RESOLV=self.stub_resolv,
                            FILES=self.files))
    self.commands = []
    self.installed = False
    self.active = False
    self.enabled = 'not-found'
    self.install_mutation = None
    self.install_failure = False
    self.query_failure = False
    self.system_lookup_failure = False
    self.missing_stub = False
    self.interrupt_activation = False
    self.src_valid_mark = '0'
    self.sysctl_load_failure = False
    self.tls_output = 'Global: yes\nLink 2 (wlp0s1): yes\n'
    self.dns_output = (
        'Global: 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com '
        '2606:4700:4700::1111#cloudflare-dns.com '
        '2606:4700:4700::1001#cloudflare-dns.com\n'
        'Link 2 (wlp0s1):\n')
    self.command_mock = self.enterContext(
        mock.patch.object(configure, 'command', side_effect=self.run_command))
    self.tls_mock = self.enterContext(
        mock.patch.object(configure, 'verify_tls'))
    self.enterContext(mock.patch.object(configure.os, 'chown'))
    self.enterContext(contextlib.redirect_stdout(io.StringIO()))
    self.enterContext(contextlib.redirect_stderr(io.StringIO()))

  def run_command(self, arguments, check=True):
    arguments = tuple(arguments)
    self.commands.append(arguments)
    returncode = 0
    stdout = ''
    if arguments[:3] == ('rpm', '-q', '--quiet'):
      returncode = 0 if self.installed else 1
    elif arguments[0] == 'dnf':
      self.installed = True
      self.enabled = 'enabled'
      self.active = True
      if self.install_mutation:
        self.install_mutation()
      returncode = 1 if self.install_failure else 0
    elif arguments[:2] == ('systemctl', 'is-enabled'):
      stdout = self.enabled + '\n'
      returncode = 0 if self.enabled in ('enabled', 'enabled-runtime',
                                         'static', 'indirect') else 1
    elif arguments[:2] == ('systemctl', 'is-active'):
      if arguments[-1] == 'systemd-resolved':
        returncode = 0 if self.active else 3
    elif arguments[:2] == ('systemctl', 'enable'):
      self.enabled = 'enabled-runtime' if '--runtime' in arguments else 'enabled'
    elif arguments[:2] == ('systemctl', 'disable'):
      self.enabled = 'disabled'
    elif arguments[:2] == ('systemctl', 'restart'):
      if self.interrupt_activation:
        self.interrupt_activation = False
        raise KeyboardInterrupt()
      self.active = True
      if not self.missing_stub:
        self.stub_resolv.parent.mkdir(parents=True, exist_ok=True)
        self.stub_resolv.write_text('nameserver 127.0.0.53\n')
    elif arguments[:2] == ('systemctl', 'stop'):
      self.active = False
    elif arguments == ('systemctl', 'daemon-reload'):
      pass
    elif arguments == ('nmcli', 'general', 'reload'):
      pass
    elif arguments[0] == 'restorecon':
      pass
    elif arguments == ('resolvectl', 'dnsovertls'):
      stdout = self.tls_output
    elif arguments == ('resolvectl', 'dns'):
      stdout = self.dns_output
    elif arguments == ('resolvectl', '--cache=no', '--synthesize=no',
                       '--type=A', 'query', 'example.com'):
      returncode = 1 if self.query_failure else 0
      stdout = 'example.com IN A 93.184.215.14\n'
    elif arguments == ('getent', 'ahosts', 'example.com'):
      returncode = 2 if self.system_lookup_failure else 0
      stdout = '93.184.215.14 STREAM example.com\n'
    elif arguments == ('sysctl', '-n', configure.SRC_VALID_MARK_KEY):
      stdout = self.src_valid_mark + '\n'
    elif arguments[:2] == ('sysctl', '-p'):
      if self.sysctl_load_failure:
        returncode = 1
      else:
        for line in Path(arguments[2]).read_text().splitlines():
          key, _, value = line.partition('=')
          if key.strip() == configure.SRC_VALID_MARK_KEY:
            self.src_valid_mark = value.strip()
    elif arguments[:2] == ('sysctl', '-w'):
      key, _, value = arguments[2].partition('=')
      self.assertEqual(key, configure.SRC_VALID_MARK_KEY)
      self.src_valid_mark = value
    else:
      raise AssertionError(f'Unexpected host command: {arguments}')
    result = subprocess.CompletedProcess(arguments, returncode, stdout,
                                         'Simulated host failure.\n')
    if check and returncode:
      raise subprocess.CalledProcessError(returncode,
                                          arguments,
                                          output=result.stdout,
                                          stderr=result.stderr)
    return result

  def assert_original_resolver(self):
    self.assertFalse(self.resolv_conf.is_symlink())
    self.assertEqual(self.resolv_conf.read_bytes(), self.original_resolver)

  def assert_no_managed_files(self):
    for _, target in self.files:
      self.assertFalse(target.exists() or target.is_symlink(), str(target))

  def test_install_and_undo_restore_original_file_and_remove_new_configuration(
      self):
    self.resolv_conf.chmod(0o640)
    configure.apply_configuration()
    self.assertTrue(self.resolv_conf.is_symlink())
    self.assertEqual(self.resolv_conf.readlink(), self.stub_resolv)
    self.assertTrue(self.active)
    self.assertEqual(self.enabled, 'enabled')
    self.assertEqual(self.src_valid_mark, '1')
    self.assertTrue((self.state_dir / 'baseline/state.json').is_file())
    self.assertFalse((self.state_dir / 'transaction').exists())
    configure.undo_configuration()
    self.assert_original_resolver()
    self.assertEqual(stat.S_IMODE(self.resolv_conf.stat().st_mode), 0o640)
    self.assert_no_managed_files()
    self.assertFalse(self.active)
    self.assertEqual(self.enabled, 'disabled')
    self.assertEqual(self.src_valid_mark, '0')
    self.assertTrue(self.installed)
    self.assertFalse((self.state_dir / 'baseline').exists())

  def test_undo_restores_prior_symlinks_files_and_service_state(self):
    self.installed = True
    self.active = True
    self.enabled = 'enabled-runtime'
    original = self.root / 'run/original-resolv.conf'
    original.parent.mkdir()
    original.write_bytes(self.original_resolver)
    self.resolv_conf.unlink()
    self.resolv_conf.symlink_to('../run/original-resolv.conf')
    originals = {}
    for name, target in self.files:
      target.parent.mkdir(parents=True, exist_ok=True)
      target.write_text(f'Original {name}\n')
      target.chmod(0o600)
      originals[target] = target.read_bytes()
    configure.apply_configuration()
    configure.undo_configuration()
    self.assertEqual(os.readlink(self.resolv_conf),
                     '../run/original-resolv.conf')
    self.assertEqual(self.resolv_conf.read_bytes(), self.original_resolver)
    for target, data in originals.items():
      self.assertEqual(target.read_bytes(), data)
      self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)
    self.assertTrue(self.active)
    self.assertEqual(self.enabled, 'enabled-runtime')

  def test_tls_preflight_failure_does_not_change_files_or_install_packages(
      self):
    self.tls_mock.side_effect = RuntimeError(
        'TLS certificate verification failed')
    with self.assertRaisesRegex(RuntimeError, 'certificate verification'):
      configure.apply_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertFalse(self.state_dir.exists())
    self.assertFalse(any(command[0] == 'dnf' for command in self.commands))

  def test_package_failure_restores_state_from_before_package_mutation(self):

    def change_resolver():
      self.resolv_conf.unlink()
      self.resolv_conf.symlink_to(self.stub_resolv)

    self.install_mutation = change_resolver
    self.install_failure = True
    with self.assertRaises(subprocess.CalledProcessError):
      configure.apply_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertFalse(self.active)
    self.assertEqual(self.enabled, 'disabled')
    self.assertFalse((self.state_dir / 'baseline').exists())
    self.assertFalse((self.state_dir / 'transaction').exists())

  def test_baseline_copy_failure_preserves_original_error_and_configuration(
      self):
    with mock.patch.object(
        configure.shutil,
        'copytree',
        side_effect=OSError('Simulated baseline copy failure')):
      with self.assertRaisesRegex(OSError, 'Simulated baseline copy failure'):
        configure.apply_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertFalse((self.state_dir / 'baseline').exists())
    self.assertFalse((self.state_dir / 'transaction').exists())

  def test_partial_baseline_copy_failure_removes_incomplete_snapshot(self):

    def fail_copy(source, destination, symlinks):
      self.assertTrue(source.is_dir())
      self.assertTrue(symlinks)
      destination.mkdir()
      (destination / 'partial').write_text('Incomplete snapshot\n')
      raise OSError('Simulated partial baseline copy failure')

    with mock.patch.object(configure.shutil, 'copytree',
                           side_effect=fail_copy):
      with self.assertRaisesRegex(OSError, 'partial baseline copy failure'):
        configure.apply_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertFalse((self.state_dir / 'baseline').exists())
    self.assertFalse((self.state_dir / 'transaction').exists())

  def test_failed_network_query_restores_original_files(self):
    self.query_failure = True
    with self.assertRaises(subprocess.CalledProcessError):
      configure.apply_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertFalse(self.active)

  def test_failed_system_lookup_restores_original_files(self):
    self.system_lookup_failure = True
    with self.assertRaises(subprocess.CalledProcessError):
      configure.apply_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertFalse(self.active)

  def test_missing_stub_file_restores_original_files(self):
    self.missing_stub = True
    with self.assertRaisesRegex(RuntimeError, 'local stub'):
      configure.apply_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()

  def test_activation_interrupt_restores_original_files(self):
    self.interrupt_activation = True
    with self.assertRaises(KeyboardInterrupt):
      configure.apply_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertFalse(self.active)

  def test_repeated_apply_keeps_initial_baseline_for_undo(self):
    configure.apply_configuration()
    saved = (self.state_dir / 'baseline/state.json').read_bytes()
    configure.apply_configuration()
    self.assertEqual((self.state_dir / 'baseline/state.json').read_bytes(),
                     saved)
    configure.undo_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertFalse(self.active)

  def test_failed_reapply_restores_last_working_configuration(self):
    configure.apply_configuration()
    saved = (self.state_dir / 'baseline/state.json').read_bytes()
    self.query_failure = True
    with self.assertRaises(subprocess.CalledProcessError):
      configure.apply_configuration()
    self.assertTrue(self.resolv_conf.is_symlink())
    self.assertEqual(self.resolv_conf.readlink(), self.stub_resolv)
    for name, target in self.files:
      self.assertEqual(target.read_bytes(),
                       (configure.SCRIPT_DIR / name).read_bytes())
    self.assertTrue(self.active)
    self.assertEqual(self.enabled, 'enabled')
    self.assertEqual((self.state_dir / 'baseline/state.json').read_bytes(),
                     saved)
    configure.undo_configuration()
    self.assert_original_resolver()

  def test_failed_rollback_keeps_snapshots_for_explicit_undo(self):
    self.query_failure = True
    with mock.patch.object(configure,
                           'restore_configuration',
                           side_effect=RuntimeError('Restore failed')):
      with self.assertRaisesRegex(RuntimeError,
                                  'saved files remain available'):
        configure.apply_configuration()
    self.assertTrue((self.state_dir / 'baseline/state.json').is_file())
    self.assertTrue((self.state_dir / 'transaction/state.json').is_file())
    configure.undo_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()

  def test_interrupted_transaction_prevents_overwriting_recovery_files(self):
    transaction = self.state_dir / 'transaction'
    transaction.mkdir(parents=True)
    recovery = transaction / 'recovery'
    recovery.write_text('Original recovery data\n')
    with self.assertRaisesRegex(RuntimeError, 'interrupted installation'):
      configure.apply_configuration()
    self.assertEqual(recovery.read_text(), 'Original recovery data\n')
    self.assert_original_resolver()
    self.assertEqual(self.commands, [])
    self.tls_mock.assert_not_called()

  def test_wrapped_global_dns_servers_pass_verification(self):
    self.dns_output = (
        'Global: 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com\n'
        '        2606:4700:4700::1111#cloudflare-dns.com\n'
        '        2606:4700:4700::1001#cloudflare-dns.com\n'
        'Link 2 (wlp0s1):\n')
    configure.apply_configuration()
    configure.verify_configuration()

  def test_non_strict_tls_modes_fail_verification(self):
    configure.apply_configuration()
    for mode in ('no', 'opportunistic', ''):
      with self.subTest(mode=mode):
        self.tls_output = f'Global: {mode}\n'
        with self.assertRaisesRegex(RuntimeError, 'require DNS over TLS'):
          configure.verify_configuration()

  def test_foreign_global_and_per_link_dns_fail_verification(self):
    configure.apply_configuration()
    valid = self.dns_output
    invalid = (
        valid.replace('1.1.1.1#cloudflare-dns.com', '192.168.0.1'),
        valid + 'Link 3 (vpn0): 10.0.0.1\n',
        valid + 'Link 3 (vpn0):\n        10.0.0.1\n',
    )
    for output in invalid:
      with self.subTest(output=output):
        self.dns_output = output
        with self.assertRaises(RuntimeError):
          configure.verify_configuration()

  def test_modified_browser_policy_fails_verification(self):
    configure.apply_configuration()
    target = next(target for name, target in self.files
                  if name == 'brave-policy.json')
    target.write_text('{"DnsOverHttpsMode": "automatic"}\n')
    with self.assertRaisesRegex(RuntimeError,
                                'installed configuration differs'):
      configure.verify_configuration()

  def test_failed_src_valid_mark_load_restores_prior_value_and_files(self):
    self.sysctl_load_failure = True
    with self.assertRaises(subprocess.CalledProcessError):
      configure.apply_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertEqual(self.src_valid_mark, '0')

  def test_disabled_src_valid_mark_fails_verification(self):
    configure.apply_configuration()
    self.src_valid_mark = '0'
    with self.assertRaisesRegex(RuntimeError, 'Source-mark validation is off'):
      configure.verify_configuration()

  def test_undo_from_version_1_baseline_removes_sysctl_file_and_resets_value(
      self):
    baseline = self.state_dir / 'baseline'
    baseline.mkdir(parents=True)
    targets = [
        target for name, target in self.files
        if name != configure.SRC_VALID_MARK_SOURCE
    ] + [self.resolv_conf]
    entries = []
    for index, target in enumerate(targets):
      entry = {'path': str(target), 'present': target == self.resolv_conf}
      if entry['present']:
        entry.update(uid=0, gid=0)
        shutil.copy2(target, baseline / str(index), follow_symlinks=False)
      entries.append(entry)
    (baseline / 'state.json').write_text(
        json.dumps({
            'version': 1,
            'enabled': 'not-found',
            'active': False,
            'files': entries
        }))
    self.src_valid_mark = '1'
    configure.apply_configuration()
    self.assertEqual(
        json.loads((baseline / 'state.json').read_text())['version'], 1)
    configure.undo_configuration()
    self.assert_original_resolver()
    self.assert_no_managed_files()
    self.assertEqual(self.src_valid_mark, '0')

  def test_saved_state_with_unknown_path_fails_restoration(self):
    configure.apply_configuration()
    state_path = self.state_dir / 'baseline/state.json'
    state = json.loads(state_path.read_text())
    state['files'].append({
        'path': str(self.root / 'etc/unknown.conf'),
        'present': False
    })
    state_path.write_text(json.dumps(state))
    with self.assertRaisesRegex(RuntimeError,
                                'does not match the managed paths'):
      configure.undo_configuration()


if __name__ == '__main__':
  unittest.main()
