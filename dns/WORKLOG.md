# Work log

Root: `/home/ctuk/Projects/dotfiles/dns`.

1. 2026-11-24: Established one work unit: document the available DNS evidence,
   explain VPN and DNS encryption boundaries, and provide host verification.
2. Read `/etc/os-release`: CentOS Stream 10. Queried RPM: NetworkManager
   `1.58.0-1.el10` exists; `systemd-resolved`, `dnsconfd`, and the `unbound`
   server package do not exist in the installed package set.
3. Read `/etc/resolv.conf`, `/run/NetworkManager/resolv.conf`, and
   `/run/NetworkManager/no-stub-resolv.conf`: each names `192.168.0.1` as its
   only resolver. The files identify NetworkManager as their generator.
4. Attempted `ip`, `nmcli`, and `resolvectl` inspection. The sandbox denied
   netlink or system-bus access. Its `/proc/net/dev` exposed only loopback.
   These restrictions prevent a conclusion about host VPN connectivity or DNS
   leakage; they do not establish an absent VPN.
5. Queried common VPN package names and Flatpak applications without identifying
   the client. Requested the VPN application name and connected state. Reviewed
   primary DNS protocol, NetworkManager, browser, and provider documentation.
6. Created the six assessment documents. Kept existing repository changes
   outside this directory intact. Made no resolver, VPN, or environment changes.
7. Completed the work unit after reviewing the documentation and validating
   whitespace, local document links, and shell syntax. Host routing checks and
   packet capture remain unperformed; they require a host terminal.
8. 2026-11-24: The requested scope changed to system DNS configuration, with
   Brave as the browser. Read the existing assessment, repository instructions,
   synchronization script, and working-tree state before implementation.
9. Confirmed Brave `1.100.58-1` and the absence of the `systemd-resolved` package.
   `sudo -n true` failed because the sandbox sets `no new privileges`.
   The current session cannot install packages, change `/etc`, or activate host
   services. Added `PLAN.md` before the first configuration change.
10. Completed implementation unit 1: added strict Cloudflare DNS over TLS,
    disabled NetworkManager DNS injection, selected the operating system DNS
    client for Brave, and added a DNS-specific `sync.sh` dispatch. The helper
    preserves original and transaction snapshots, applies atomic file changes,
    restores SELinux labels, verifies runtime state, and supports restoration.
11. Reviewed systemd 257, NetworkManager, Brave, Chromium policy, and Cloudflare
    primary references. Ran YAPF, Python/INI/JSON syntax and configuration checks,
    document-link validation, Bash syntax, whitespace checks, and
    `./sync.sh --dns --help`; all passed. Host activation remains pending.
12. Completed verification unit 2 through independent review and isolated tests.
    Review identified wrapped `resolvectl dns` output and failure cleanup when
    initial baseline creation fails before making the destination. Corrected
    both conditions and added regression coverage.
13. Ran `yapf -i dns/configure.py dns/test_configure.py`, then
    `python3 -B -m unittest discover -s dns -p test_configure.py -v`.
    All 18 tests passed. Tests exercise real temporary files and symlinks while
    simulating package, service, label, and DNS commands. They do not execute
    privileged host operations or send network traffic.
14. Attempted deployment unit 3 with `./sync.sh --dns`. The command exited 1
    because `sudo` cannot obtain root under the sandbox's `no new privileges`
    restriction. No package or host configuration change occurred.
15. Ran `./sync.sh --dns --check`; it exited 1 because the managed NetworkManager
    configuration does not exist. Rechecked `/etc/resolv.conf`: it still names
    `192.168.0.1`. RPM still reports `systemd-resolved` absent. Kept deployment
    unit 3 open and documented the exact command for a host terminal.
16. Committed only this task's changes. The existing unrelated working-tree
    changes, including prior `sync.sh` edits, remain outside these commits.
