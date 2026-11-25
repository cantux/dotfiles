import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import socket
import ssl
import subprocess
import sys
import tempfile

SCRIPT_DIR = Path(__file__).resolve().parent
STATE_DIR = Path('/var/lib/dotfiles-dns')
LOCK_PATH = Path('/run/dotfiles-dns.lock')
RESOLV_CONF = Path('/etc/resolv.conf')
STUB_RESOLV = Path('/run/systemd/resolve/stub-resolv.conf')
TLS_SERVER = 'cloudflare-dns.com'
DNS_ADDRESSES = ('1.1.1.1', '1.0.0.1', '2606:4700:4700::1111',
                 '2606:4700:4700::1001')
FILES = (
    ('networkmanager.conf',
     Path('/etc/NetworkManager/conf.d/90-dotfiles-dns.conf')),
    ('resolved.conf',
     Path('/etc/systemd/resolved.conf.d/90-dotfiles-dns.conf')),
    ('brave-policy.json',
     Path('/etc/brave/policies/managed/dotfiles-dns.json')),
)


def command(arguments, check=True):
  environment = os.environ.copy()
  environment['LC_ALL'] = 'C'
  result = subprocess.run(arguments,
                          capture_output=True,
                          text=True,
                          env=environment,
                          check=check)
  return result


def managed_paths():
  return [target for _, target in FILES] + [RESOLV_CONF]


def replace_file(source, target, preserve=False):
  target.parent.mkdir(parents=True, exist_ok=True)
  with tempfile.TemporaryDirectory(prefix='.dotfiles-dns-',
                                   dir=target.parent) as directory:
    temporary = Path(directory) / 'file'
    if preserve:
      shutil.copy2(source, temporary, follow_symlinks=False)
    else:
      temporary.write_bytes(source.read_bytes())
      temporary.chmod(0o644)
    temporary.replace(target)


def replace_resolver_symlink():
  with tempfile.TemporaryDirectory(prefix='.dotfiles-dns-',
                                   dir=RESOLV_CONF.parent) as directory:
    temporary = Path(directory) / 'resolv.conf'
    temporary.symlink_to(STUB_RESOLV)
    temporary.replace(RESOLV_CONF)


def verify_tls():
  context = ssl.create_default_context()
  failures = []
  for address in DNS_ADDRESSES:
    try:
      with socket.create_connection((address, 853), timeout=5) as connection:
        with context.wrap_socket(connection,
                                 server_hostname=TLS_SERVER) as encrypted:
          print(f'Verified {encrypted.version()} to {address}:853.',
                flush=True)
          return
    except OSError as error:
      failures.append(f'{address}: {error}')
  raise RuntimeError('Authenticated DNS over TLS is unreachable. ' +
                     '; '.join(failures))


def snapshot_configuration(directory):
  enabled = command(['systemctl', 'is-enabled', 'systemd-resolved'],
                    check=False).stdout.strip() or 'not-found'
  if enabled not in ('enabled', 'enabled-runtime', 'disabled', 'not-found',
                     'static', 'indirect'):
    raise RuntimeError(f'Unsupported prior resolver service state: {enabled}')
  active = command(['systemctl', 'is-active', '--quiet', 'systemd-resolved'],
                   check=False).returncode == 0
  state = {'version': 1, 'enabled': enabled, 'active': active, 'files': []}
  directory.mkdir(mode=0o700)
  try:
    for index, target in enumerate(managed_paths()):
      present = target.exists() or target.is_symlink()
      entry = {'path': str(target), 'present': present}
      if present:
        if not target.is_file() and not target.is_symlink():
          raise RuntimeError(f'Expected a file or symlink: {target}')
        metadata = target.lstat()
        entry.update(uid=metadata.st_uid, gid=metadata.st_gid)
        shutil.copy2(target, directory / str(index), follow_symlinks=False)
      state['files'].append(entry)
    (directory / 'state.json').write_text(json.dumps(state, indent=2) + '\n')
  except BaseException:
    shutil.rmtree(directory)
    raise


def restore_configuration(directory=None):
  if directory is None:
    directory = STATE_DIR / 'baseline'
  state = json.loads((directory / 'state.json').read_text())
  if state['version'] != 1 or [entry['path'] for entry in state['files']
                               ] != [str(path) for path in managed_paths()]:
    raise RuntimeError(
        'The saved configuration does not match the managed paths.')
  for index, entry in enumerate(state['files']):
    target = Path(entry['path'])
    if entry['present']:
      replace_file(directory / str(index), target, preserve=True)
      os.chown(target, entry['uid'], entry['gid'], follow_symlinks=False)
    else:
      target.unlink(missing_ok=True)
  restored_paths = [
      str(path) for path in managed_paths()
      if path.exists() or path.is_symlink()
  ]
  if restored_paths:
    command(['restorecon', '-F', *restored_paths])
  command(['systemctl', 'daemon-reload'])
  if command(['rpm', '-q', '--quiet', 'systemd-resolved'],
             check=False).returncode == 0:
    command(['systemctl', 'disable', 'systemd-resolved'])
    if state['enabled'] == 'enabled':
      command(['systemctl', 'enable', 'systemd-resolved'])
    elif state['enabled'] == 'enabled-runtime':
      command(['systemctl', 'enable', '--runtime', 'systemd-resolved'])
    operation = 'restart' if state['active'] else 'stop'
    command(['systemctl', operation, 'systemd-resolved'])
  command(['nmcli', 'general', 'reload'])


def verify_configuration():
  for name, target in FILES:
    if target.read_bytes() != (SCRIPT_DIR / name).read_bytes():
      raise RuntimeError(f'The installed configuration differs: {target}')
  if not RESOLV_CONF.is_symlink() or RESOLV_CONF.readlink() != STUB_RESOLV:
    raise RuntimeError('/etc/resolv.conf does not select the local DNS stub.')
  command(['systemctl', 'is-active', '--quiet', 'systemd-resolved'])
  command(['systemctl', 'is-enabled', '--quiet', 'systemd-resolved'])
  mode = command(['resolvectl', 'dnsovertls']).stdout
  if not re.search(r'^Global:\s+yes\s*$', mode, re.MULTILINE):
    raise RuntimeError('The running resolver does not require DNS over TLS.')
  servers = command(['resolvectl', 'dns']).stdout
  expected = {f'{address}#{TLS_SERVER}' for address in DNS_ADDRESSES}
  global_servers = set()
  for line in servers.splitlines():
    label, separator, values = line.partition(':')
    if separator and label == 'Global':
      global_servers = set(values.split())
    elif separator and label.startswith('Link ') and values.strip():
      raise RuntimeError('Another client supplied per-interface DNS servers.')
  if global_servers != expected:
    raise RuntimeError(
        'The running resolver does not use the configured servers.')
  result = command([
      'resolvectl', '--cache=no', '--synthesize=no', '--type=A', 'query',
      'example.com'
  ])
  print(result.stdout, end='', flush=True)
  command(['getent', 'ahosts', 'example.com'])
  print('Verified strict system DNS over TLS and system resolver lookup.',
        flush=True)


def apply_configuration():
  baseline = STATE_DIR / 'baseline'
  transaction = STATE_DIR / 'transaction'
  if transaction.exists():
    raise RuntimeError(
        'An interrupted installation remains. Run --undo first.')
  command(['systemctl', 'is-active', '--quiet', 'NetworkManager'])
  verify_tls()
  STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
  snapshot_configuration(transaction)
  first_installation = not baseline.exists()
  try:
    if first_installation:
      shutil.copytree(transaction, baseline, symlinks=True)
    if command(['rpm', '-q', '--quiet', 'systemd-resolved'],
               check=False).returncode != 0:
      print('Installing systemd-resolved.', flush=True)
      command(['dnf', 'install', '--assumeyes', 'systemd-resolved'])
    for name, target in FILES:
      replace_file(SCRIPT_DIR / name, target)
    command(['restorecon', '-F', *[str(target) for _, target in FILES]])
    command(['nmcli', 'general', 'reload'])
    command(['systemctl', 'daemon-reload'])
    command(['systemctl', 'enable', 'systemd-resolved'])
    command(['systemctl', 'restart', 'systemd-resolved'])
    if not STUB_RESOLV.is_file():
      raise RuntimeError('The resolver did not create its local stub file.')
    replace_resolver_symlink()
    command(['restorecon', '-F', str(RESOLV_CONF)])
    verify_configuration()
  except BaseException as installation_error:
    print('Installation failed; restoring the prior configuration.',
          file=sys.stderr,
          flush=True)
    try:
      restore_configuration(transaction)
    except BaseException as restoration_error:
      raise RuntimeError(
          f'Installation failed: {installation_error}. '
          f'Restoration failed: {restoration_error}. '
          'The saved files remain available; run --undo from a host terminal.'
      ) from restoration_error
    shutil.rmtree(transaction)
    if first_installation:
      shutil.rmtree(baseline)
    raise
  shutil.rmtree(transaction)
  print('Configuration active. Restart Brave and inspect brave://policy.',
        flush=True)


def undo_configuration():
  baseline = STATE_DIR / 'baseline'
  if not baseline.is_dir():
    raise RuntimeError(
        'No saved installation exists; no configuration changed.')
  restore_configuration(baseline)
  shutil.rmtree(baseline)
  shutil.rmtree(STATE_DIR / 'transaction', ignore_errors=True)
  print('Restored the saved DNS configuration. Restart Brave.', flush=True)


def main():
  parser = argparse.ArgumentParser(
      description='Configure authenticated system DNS over TLS and Brave.')
  operations = parser.add_mutually_exclusive_group()
  operations.add_argument('--check', action='store_true')
  operations.add_argument('--undo', action='store_true')
  arguments = parser.parse_args()
  try:
    if arguments.check:
      verify_configuration()
      return 0
    if os.geteuid() != 0:
      os.execvp('sudo', [
          'sudo', '--', sys.executable,
          str(SCRIPT_DIR / 'configure.py'), *sys.argv[1:]
      ])
    with LOCK_PATH.open('w') as lock:
      fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
      if arguments.undo:
        undo_configuration()
      else:
        apply_configuration()
  except (OSError, ValueError, RuntimeError,
          subprocess.CalledProcessError) as error:
    print(f'DNS configuration failed: {error}', file=sys.stderr)
    if isinstance(error, subprocess.CalledProcessError):
      print(error.stderr or error.stdout or '', file=sys.stderr, end='')
    return 1
  except KeyboardInterrupt:
    print('DNS configuration interrupted.', file=sys.stderr)
    return 130
  return 0


if __name__ == '__main__':
  sys.exit(main())
