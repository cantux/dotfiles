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

See [primary references](EVIDENCE_INSPIRATION_REFERENCE.md). Host verification
remains pending.
