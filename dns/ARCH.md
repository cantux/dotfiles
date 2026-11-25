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

## DNS request sequence

1. After Brave loads the installed policies, it uses the operating system DNS
   client. A browser cache entry can satisfy a lookup without invoking DNS.
   The current NSS order checks `/etc/hosts` before DNS.
2. For an unresolved name, the system client reads `/etc/resolv.conf` and sends
   an ordinary DNS query to `127.0.0.53`, port 53. This exchange remains on
   loopback; it does not travel to the router or ISP.
3. `systemd-resolved` checks its local data and cache. On a cache miss, it
   selects a configured Cloudflare IP address. The static IP means it needs
   no separate DNS lookup to find the upstream server.
4. The kernel selects a route for TCP traffic to that IP on port 853. A VPN
   route encapsulates the connection in the VPN protocol. A physical route
   sends the TLS connection directly through the access network. DNS settings
   alone do not choose between these paths.
5. The resolver establishes or reuses a TLS connection to Cloudflare. On a new
   connection, it authenticates the certificate against `cloudflare-dns.com`
   and the system trust store. TLS then protects DNS requests and responses.
   `DNSOverTLS=yes` rejects an upstream that cannot provide authenticated TLS.
   This exchange uses neither SSH nor browser DNS over HTTPS.
6. Cloudflare decrypts the question, obtains an answer from cache or DNS
   resolution, and returns it over TLS. The client-to-Cloudflare encryption
   does not guarantee encryption of Cloudflare's queries to other DNS servers.
7. The local resolver returns the answer over loopback. The application can
   then connect to the returned address. A website connection constitutes a
   separate exchange with its own transport and encryption settings.

| Route | Query transport | Source address that Cloudflare observes |
| --- | --- | --- |
| VPN carries the connection | DNS inside TLS inside the VPN; TLS remains after the VPN endpoint removes VPN encapsulation. | VPN exit address. |
| Physical interface carries the connection | DNS inside TLS through the router and ISP. | Access-network public address, subject to address translation. |

TLS protects query contents along the client-to-resolver connection in both
cases. Cloudflare receives the question. No live VPN activation, route test,
or packet capture has occurred in this session. The isolated tests establish
configuration and recovery behavior; they do not establish network routing.

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
7. The helper also installs `src-valid-mark.conf` as
   `/etc/sysctl.d/90-dotfiles-src-valid-mark.conf` and loads it with
   `sysctl -p`; verification requires the running value 1. Snapshots of format
   version 2 record the prior running value, and restoration writes it back.
   Version-1 snapshots, including the baseline of 2026-11-24, predate the file;
   restoration from them removes it and restores the documented default, 0.

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

## VPN endpoint and resolver interaction

1. The NetworkManager profile `wg-US-CA-515` stores the peer endpoint
   `[2a02:6ea0:e606:3742::10]:51820`. Its source file contains two uncommented
   `Endpoint` lines; the profile holds the second, IPv6 line. The first line
   names `149.22.84.89:51820`.
2. The profile's policy routing sends all traffic except the access network's
   subnet into the tunnel; the rule `lookup main suppress_prefixlength 0`
   keeps subnet routes. On an access network without an IPv6 route, no
   handshake with the IPv6 endpoint completes, yet the device activates. DNS
   queries, tracker requests, and peer connections then enter a tunnel that
   carries nothing, and every resolver reached through the tunnel fails.
3. Before `dns=none`, NetworkManager also listed the access network's
   resolver (`192.168.0.1`) after the VPN resolvers. That resolver answers
   through the subnet route, so lookups would probably have succeeded after
   the VPN resolvers' timeouts while tracker and peer traffic still failed.
   The resolver change therefore set the error message, not the outcome.
4. The host filters reverse paths strictly on `wlp0s20f3` and kept
   `src_valid_mark=0`. NetworkManager restores the connection mark on
   encrypted replies but does not set `src_valid_mark`. The kernel then
   validates a reply's source without the mark: the lookup skips the main
   table's suppressed default route, selects the WireGuard table, and finds a
   device other than the receiving interface, so strict mode drops replies
   from an IPv4 endpoint. An IPv4 endpoint therefore requires
   `net.ipv4.conf.all.src_valid_mark = 1`, which wg-quick sets. This IPv4
   filter does not apply to the IPv6 endpoint.
5. Through an established tunnel, `openssl` authenticated `cloudflare-dns.com`
   on IPv4 and IPv6 port 853, `systemd-resolved` reported encrypted
   transport, and the nine tested names resolved under either resolver.
   Lookups took 0.16 to 1.00 seconds over TLS and 0.09 to 0.31 seconds through
   the VPN resolver.
6. Strict DNS over TLS replaces the VPN resolver. Proton's NetShield filters
   domains in Proton's DNS servers, so queries sent to Cloudflare receive no
   NetShield filtering. Cloudflare receives each query from the VPN exit
   address.
7. The profile `wg-US-CA-515-ipv4` holds the IPv4 endpoint, the same key, and
   the interface name `wg-US-CA-515` that qBittorrent binds to; it does not
   connect automatically. It requires `src_valid_mark=1`, which the user set
   at runtime on 2026-11-24 and which item 7 of the installation section
   makes persistent.
8. A NetworkManager profile cannot carry `src_valid_mark`: the profile
   settings define neither it nor `rp_filter`. The kernel combines the
   receiving interface's value with `all` by logical OR, and the receiving
   interface is the access network's interface, not the WireGuard device.
   The setting therefore belongs to host sysctl configuration or to a
   dispatcher script that runs when the profile changes state; the helper
   uses sysctl configuration. With the setting on, the kernel uses a packet's
   mark in reverse-path lookups and in ICMP reply source selection; unmarked
   packets see no change.

## VPN verification harness

1. `vpn_container/run_matrix.sh` runs one rootless Podman container per matrix
   cell. Each container owns a separate network namespace; the harness changes
   no host interface, route, rule, or resolver setting.
2. The image reproduces the measured host components: CentOS Stream 10,
   `systemd-resolved-257-35.el10`, the NSS line `hosts: files dns myhostname`,
   and the repository `resolved.conf`, whose SHA-256 equals the installed
   drop-in. It runs `qbittorrent-nox` 5.2.4; the host runs the 5.2.3 AppImage.
3. `vpn_container/cell_probe.sh` creates the kernel WireGuard device
   `wg-US-CA-515` from the profile's source file and applies NetworkManager's
   routing for a peer with `/0` allowed IPs: fwmark 51820, a default route in
   table 51820, and the rules `lookup main suppress_prefixlength 0` and
   `not fwmark 51820 lookup 51820` for both address families.
4. Three factors define the cells. The endpoint factor selects the IPv6 or the
   IPv4 `Endpoint` line. The resolver factor selects `strict_dot`, the
   installed resolver behind its local stub, or `vpn_dns`, the profile's DNS
   servers in `/etc/resolv.conf`. The suffix `_valid_mark` sets
   `src_valid_mark=1`; other cells inherit the host's value.
5. Each cell measures, in order: tunnel setup and routes, handshake, egress by
   IP address, DNS over TLS to Cloudflare, the VPN resolver, nine lookups
   through glibc, and `qbittorrent-nox` bound to `wg-US-CA-515` on port 51820.
   qBittorrent loads the Debian netinst torrent and five trackers from the
   failing magnet link, limited to 2 MiB/s for 75 seconds.
6. Invariants: the private key exists only in `$XDG_RUNTIME_DIR` and in the
   container's `/run`, and the harness deletes both; the harness refuses to
   run without `XDG_RUNTIME_DIR`; evidence redacts the interface public key;
   each cell starts from a new container.
7. Deviations from the host:
   1. The container holds `CAP_SYS_ADMIN` within its user namespace; systemd
      requires it to start the sandboxed resolver.
   2. The container inherits the host's reverse-path settings and loads
      NetworkManager's connection-mark rules. Rule priorities 32764 and 32765
      replace NetworkManager's UUID-derived priorities in the same order.
      Runs before `20261124T224242` used loose filtering, which hid the
      condition in item 4 of the preceding section.
   3. pasta, the rootless network backend, installs an IPv6 default route
      through `fe80::1`. The container therefore sends the 148-byte handshake
      initiation, which the host cannot forward without an IPv6 route.
   4. Before `dns=none`, NetworkManager listed the VPN resolvers (priority 50)
      above the access network's resolver (priority 100). The `vpn_dns` cell
      omits the access network's resolver. That resolver can answer through
      the local subnet route outside the tunnel, but qBittorrent's bound
      sockets and every other destination still use the tunnel.
   5. The `handshake` summary field reports the state about 2 seconds after
      the first packet. WireGuard retries an unanswered initiation after 5
      seconds, so a working tunnel can follow `handshake=no`.

See [primary and local references](EVIDENCE_INSPIRATION_REFERENCE.md).
Installed host files match the design, and host resolver status matched it on
2026-11-24. Cluster checks remain unperformed.
