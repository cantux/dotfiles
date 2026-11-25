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
