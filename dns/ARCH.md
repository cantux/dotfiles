# System resolver architecture

1. Applications use the operating system resolver. `/etc/resolv.conf` points
   to `/run/systemd/resolve/stub-resolv.conf`, which names the local resolver
   at `127.0.0.53`. Local DNS traffic stays on loopback.
2. `systemd-resolved` sends upstream queries to Cloudflare IPv4 and IPv6
   endpoints on TCP port 853. Each address specifies `cloudflare-dns.com`
   for certificate authentication. `DNSOverTLS=yes` rejects plaintext
   fallback. Empty `DNS=` and `Domains=` assignments clear earlier lists;
   `FallbackDNS=` clears fallback servers.
3. `Domains=~.` selects the configured resolver group for all DNS questions.
   The new resolver disables LLMNR and multicast DNS. The configuration does
   not add DNSSEC requirements or modify system NSS configuration.
4. NetworkManager `dns=none` preserves the resolver symlink, and
   `systemd-resolved=false` prevents additional DNS servers. DHCP and VPN DNS
   settings therefore do not weaken TLS requirements. The helper reloads
   configuration without restarting network interfaces.
5. Brave managed policy disables its built-in DNS client and browser DoH.
   Brave uses the operating system DNS client and the same TLS resolver.
6. Kernel routing determines whether the TLS connection travels through the
   VPN. This configuration encrypts system DNS with or without the VPN; it
   does not implement a VPN kill switch. The resolver receives query contents.
   A split VPN can expose the non-VPN source address to the resolver while
   TLS protects query contents along the connection.
7. Public DNS replaces VPN-private and DHCP-provided DNS. VPN-only domain
   names require a separate explicit design. Applications or proxies that
   perform their own DNS exchanges can bypass the system resolver. This
   configuration does not impose firewall controls.

## Installation and restoration

1. The helper checks NetworkManager and authenticates TLS to a configured
   endpoint before changing configuration.
2. It snapshots files, symlinks, ownership, and resolver service state before
   installing `systemd-resolved`: package installation can change resolver files.
3. It preserves the first snapshot as the original baseline. Each later
   attempt creates a separate snapshot of the current state.
4. It replaces managed files atomically, restores SELinux labels, reloads
   NetworkManager, enables and restarts the resolver, and selects its local stub.
5. Verification checks installed contents, the symlink, active and enabled
   service state, runtime TLS mode, exact upstream servers, absence of
   per-interface servers, a query that bypasses cache and synthesis, and a
   system resolver lookup.
6. Failure restores the transaction snapshot. `--undo` restores the original
   baseline, including service activation and enablement. Restoration retains
   installed packages. A file lock serializes configuration operations. An
   interrupted transaction requires `--undo` before another application attempt.

## Loopback and Kubernetes compatibility

1. Numeric connections to `127.0.0.1`, `::1`, and the laboratory's private
   addresses retain their existing paths. The helper changes DNS configuration;
   it changes no bridge, TAP device, route, forwarding setting, or NAT rule.
   NetworkManager's `systemd-resolved=false` disables DNS configuration injection,
   not the resolver service or NetworkManager's network management.
2. The resolver adds DNS listeners on `127.0.0.53:53` and `127.0.0.54:53`.
   Ordinary loopback services use their existing addresses and ports. Another
   DNS server that binds a wildcard address on port 53 can conflict.
3. The native Kubernetes laboratory runs Debian guests on `br-lab`
   (`10.30.0.1/24`) and user-owned TAP devices. Both laboratory seed scripts
   configure guest DNS addresses `1.1.1.1` and `9.9.9.9`. Native guest seeds
   also write lab-name mappings to each guest's `/etc/hosts`. These settings
   remain independent of the CentOS host's resolver.
4. The tutorial's archived kubelet evidence from 2026-11-16 selects cluster DNS
   `10.96.0.10` and guest `resolvConf: /run/systemd/resolve/resolv.conf`.
   Archived CoreDNS configuration handles `cluster.local` and forwards other
   queries using its own `/etc/resolv.conf`. These files support the expected
   separation; they do not prove current cluster health.
5. Loopback addresses belong to the current network namespace or guest. Using
   `127.0.0.53` in an isolated guest or ordinary pod does not reach the CentOS
   host's resolver. A guest can use its own local stub. A `hostNetwork` pod
   shares its node's network namespace. Incorrect stub inheritance by CoreDNS
   can cause a forwarding loop, as Kubernetes documents.
6. Host DNS encryption does not encrypt forwarded packets from guests or pods.
   Their external DNS can remain plaintext. A conventional upstream resolver
   file lists IP addresses without TLS requirements; using
   `/run/systemd/resolve/resolv.conf` avoids stub inheritance but does not
   itself enable encryption for its consumers.
7. Host `/etc/hosts` mappings continue to apply. Router-only DNS names,
   VPN-private zones, and discovery through resolved's LLMNR/mDNS paths require
   explicit configuration. Host resolution of cluster service names also
   requires an explicit cluster DNS route; host DNS does not gain those names
   merely because the host can reach the cluster's IP network.

See [primary and local references](EVIDENCE_INSPIRATION_REFERENCE.md).
Installed host files match the design; live host and cluster checks remain
unavailable within the execution sandbox.
