# Evidence and references

Root: `/home/ctuk/Projects/dotfiles/dns`. Inspection date: 2026-11-24.

1. Local evidence: `/etc/os-release`; `/etc/resolv.conf`;
   `/run/NetworkManager/resolv.conf`;
   `/run/NetworkManager/no-stub-resolv.conf`; `/etc/nsswitch.conf`; RPM queries;
   command errors from `ip`, `nmcli`, and `resolvectl`. These observations support
   the findings in [WORKLOG.md](WORKLOG.md), with its explicit scope limits.
2. [RFC 7858: Specification for DNS over Transport Layer Security](https://www.rfc-editor.org/rfc/rfc7858).
   Defines DNS over TLS and its client-to-server confidentiality boundary.
3. [RFC 8484: DNS Queries over HTTPS](https://www.rfc-editor.org/rfc/rfc8484).
   Defines DoH, including resolver selection and privacy considerations.
4. [NetworkManager.conf reference](https://www.networkmanager.dev/docs/api/latest/NetworkManager.conf.html).
   Defines the DNS plugins, resolver-file behavior, global DNS precedence, and
   `dns+tls` server syntax.
5. [NetworkManager connection settings](https://www.networkmanager.dev/docs/api/latest/settings-connection.html).
   Defines strict and opportunistic `dns-over-tls` modes and the compatible-plugin
   requirement.
6. [NetworkManager IPv4 settings](https://www.networkmanager.dev/docs/api/latest/settings-ipv4.html).
   Defines DNS priorities and their role in excluding other active profiles'
   DNS configuration. Priorities alone do not control arbitrary application DoH.
7. [Chrome security settings](https://support.google.com/chrome/answer/10468685?hl=en).
   Documents Secure DNS and the explicit-provider behavior that prevents
   automatic fallback to unencrypted DNS.
8. [Firefox DNS over HTTPS protection levels](https://support.mozilla.org/en-US/kb/dns-over-https).
   Documents Max Protection and the VPN-dependent behavior of Default Protection.
9. [Proton VPN: DNS leaks when using a VPN](https://protonvpn.com/support/dns-leaks-privacy).
   Provides a provider-specific example of encrypted VPN DNS and documented
   constraints on combining its client with external DoH or DoT. This reference
   does not identify the VPN application installed on this machine.
10. [Cloudflare: Oblivious DNS over HTTPS](https://developers.cloudflare.com/1.1.1.1/encryption/oblivious-dns-over-https/).
    Explains that an ordinary DoH resolver receives query contents and the
    source address of its client connection.
11. Local workflow evidence: `/home/ctuk/AGENTS.md`, the supplied repository
    instructions, and `/home/ctuk/Projects/dotfiles/.vimrc`. These define the
    environment-change location and available save-time checks.
12. [systemd 257 resolver configuration](https://www.freedesktop.org/software/systemd/man/257/resolved.conf.html).
    Matches the installed systemd major version. Defines strict TLS,
    certificate server names, list resets, fallback servers, routing domains,
    and the local DNS stub.
13. [systemd 257 resolvectl](https://www.freedesktop.org/software/systemd/man/257/resolvectl.html).
    Defines runtime DNS and TLS inspection and queries that bypass caches
    and synthetic answers.
14. [Cloudflare DNS over TLS](https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-tls/).
    Documents IPv4 and IPv6 endpoints, port 853, and TLS certificates.
15. [Brave Group Policy](https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy).
    Documents Chromium policy compatibility, Linux managed policy placement
    under `/etc/brave/policies/managed/`, and `brave://policy` verification.
16. [Chromium DNS over HTTPS policy](https://chromium.googlesource.com/chromium/src/+/376fc41e87a058f7a7b300b0ec3a4982b4ec0960/components/policy/resources/templates/policy_definitions/Miscellaneous/DnsOverHttpsMode.yaml).
    Defines `off` as disabling browser DoH.
17. [Chromium built-in DNS client policy](https://chromium.googlesource.com/chromium/src/+/376fc41e87a058f7a7b300b0ec3a4982b4ec0960/components/policy/resources/templates/policy_definitions/Miscellaneous/BuiltInDnsClientEnabled.yaml).
    Defines the disabled built-in client behavior. Combining it with DoH off
    selects the operating system DNS client.
18. Local privilege evidence: `sudo -n true` failed with the explicit
    `no new privileges` diagnostic. The session cannot apply host configuration.
    Host activation and network verification remain pending.
19. [systemd v257 resolvectl implementation](https://raw.githubusercontent.com/systemd/systemd/v257/src/resolve/resolvectl.c).
    `status_print_strv_ifindex` wraps DNS server lists into continuation lines.
    The verification parser accepts that native output format.
20. [systemd v257 address formatting](https://raw.githubusercontent.com/systemd/systemd/v257/src/basic/in-addr-util.c).
    Defines IPv6 formatting and the server-name suffix in resolver status.
21. [Isolated configuration tests](test_configure.py).
    Eighteen tests cover filesystem recovery and verification behavior. The
    work log records the command and result; no test claims host deployment.
22. Follow-up host evidence on 2026-11-24: `rpm -q systemd-resolved` now reports
    `257-35.el10`; byte comparisons match all three installed files to their
    sources; `/etc/resolv.conf` points to the local stub. System-bus and
    Kubernetes socket access still fail under the sandbox. These observations
    establish installation, not live service or cluster health.
23. [Laboratory architecture](../../ai/kubernetes/README.md),
    [host network setup](../../ai/kubernetes/rack/00-host-net.sh), and
    [network constants](../../ai/kubernetes/fleet/lib.sh).
    Establish separate Debian guests, `br-lab`, TAP devices, private addressing,
    and dedicated NAT. The DNS helper changes none of these components.
24. [Native guest seed](../../ai/kubernetes/provision/02-seed.sh) and
    [tutorial guest seed](../../ai/kubernetes_learning/cluster/seeds.sh).
    Both select guest DNS `1.1.1.1` and `9.9.9.9`. The native seed also writes
    laboratory names into each guest's `/etc/hosts`.
25. [Archived guest kubelet configuration](../../ai/kubernetes_learning/cluster/evidence/main/2-after-network-plugin/22-kubelet-configuration.txt)
    and [archived CoreDNS configuration](../../ai/kubernetes_learning/cluster/evidence/main/inventory/20-coredns-configuration.txt).
    Evidence dated 2026-11-16 establishes guest resolver and cluster DNS
    configuration at collection time. It does not establish live state.
26. [Kubernetes DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/).
    Defines cluster DNS policies and the network-namespace behavior relevant
    to host-networked pods.
27. [Kubernetes DNS troubleshooting](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/).
    Documents systemd stub inheritance and CoreDNS forwarding loops, including
    kubelet's upstream resolver-file setting. That file does not encode TLS.
28. [systemd 257 resolver service](https://www.freedesktop.org/software/systemd/man/257/systemd-resolved.service.html).
    Documents the `127.0.0.53` and `127.0.0.54` local DNS listeners and the
    separation between local clients and upstream resolution.
29. Follow-up inspection on 2026-11-24 reconfirmed `DNSOverTLS=yes`, static
    Cloudflare addresses with the TLS authentication name, the local stub, and
    the Brave policies. NetworkManager and routing queries still deny access.
    No VPN activation or packet capture occurred. The installer and isolated
    tests do not verify VPN routing.
30. [RFC 7858](https://www.rfc-editor.org/rfc/rfc7858) defines DNS over TLS,
    persistent TCP/TLS connections, and its stub-to-recursive scope.
    The DNS request sequence applies that protocol to the installed systemd
    configuration; it introduces no SSH transport.
31. [WireGuard protocol](https://www.wireguard.com/protocol/) explains one VPN
    protocol's independent encryption layer. This reference does not establish
    the active VPN protocol or its current routing on this machine.
32. Retrospective lookup investigation on 2026-11-24 around 20:55 PST:
    `journalctl -u systemd-resolved --since '2026-11-24 17:00:00'` contained
    startup records only. Recent NetworkManager, kernel, and sleep-service
    journals supplied no event that establishes a cause. No per-query timing
    or contemporaneous packet capture exists in the inspected evidence.
33. [systemd 257 resolvectl](https://www.freedesktop.org/software/systemd/man/257/resolvectl.html)
    defines the completed-local-query monitor and cache/synthesis bypass
    options. [Resolver cache documentation](https://www.freedesktop.org/software/systemd/man/257/resolved.conf.html)
    explains caching of valid and negative answers; that mechanism alone
    does not establish the cause of this incident.

34. Host evidence for the qBittorrent failure, collected on 2026-11-24 from
    21:13 to 21:31 PST: the NetworkManager journal (`wg-US-CA-515` activated
    at 21:03:06 and deactivated at 21:10:13; `WOODMAN24` first activated on
    2026-11-23 at 14:36:36; "Blues Junior" set as the IPv6 default on
    2026-11-21); qBittorrent logs (the geolocation error at 21:03:19; exit
    addresses on 2026-11-20 and earlier); `nmcli -f wireguard.peers` (the
    stored IPv6 endpoint); the source file, read with its private key redacted
    (two `Endpoint` lines); `ip -6 route get` ("Network is unreachable");
    `nmcli -f IP6 device show wlp0s20f3` (no global address or gateway); and
    `strings -el` on the running qBittorrent 5.2.3 binary
    (`https://download.db-ip.com/free/dbip-country-lite-%1.mmdb.gz`).
35. Container evidence: the
    [host replica](vpn_container/evidence/20261124T213537/ipv6_strict_dot.txt)
    and the [four-cell matrix](vpn_container/evidence/20261124T214244/). The
    directory
    [20261124T213123_resolver_inactive](vpn_container/evidence/20261124T213123_resolver_inactive/)
    records the harness defect in which the resolver did not start. The
    [reverse-path cells](vpn_container/evidence/20261124T224242/) and the
    [host activation](vpn_container/evidence/20261124T224242/host_ipv4_profile.txt)
    supersede the matrix's IPv4 outcome for the host.
36. nm-settings-nmcli(5), NetworkManager 1.58.0, local manual and
    [online edition](https://networkmanager.dev/docs/api/latest/nm-settings-nmcli.html).
    `wireguard.ip4-auto-default-route` places the default route in a dedicated
    table with an automatic fwmark and two policy rules, as wg-quick does with
    `Table=auto`. `wireguard.peers` defines the `endpoint` attribute.
    `ipv4.dns-priority` defaults to 50 for VPNs, including WireGuard, and 100
    for other connections, and orders `resolv.conf` under `dns=default`.
37. [WireGuard routing and network namespaces](https://www.wireguard.com/netns/)
    describes "Improved Rule-based Routing", the rule pair that the harness
    applies.
38. [WireGuard protocol](https://www.wireguard.com/protocol/) defines the
    148-byte handshake initiation; 148 bytes sent and 0 received identify one
    unanswered initiation.
39. resolv.conf(5), man-pages 6.06, local manual: `timeout` defaults to 5
    seconds and `attempts` to 2. These defaults account for the measured
    10.02-second and 20.04-second lookup failures.
40. podman-run(1), local manual: `--dns none` leaves the image's
    `/etc/resolv.conf` unchanged. pasta(1), local manual: the link-local
    address `fe80::1` serves as the IPv6 gateway fallback; the container's
    main table shows `default via fe80::1` although the host has no IPv6
    default route.
41. [qBittorrent WebUI API for 5.0](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-5.0)):
    tracker status 1 means "Tracker has not been contacted yet", 2 "Tracker
    has been contacted and is working", and 4 "Tracker has been contacted, but
    it is not working"; `dht_nodes` counts "DHT nodes connected to". Checked
    in the raw wiki Markdown, lines 1487 to 1491.
42. [Proton VPN NetShield](https://protonvpn.com/support/netshield): "the DNS
    server will check these domains against databases of domains known to host
    malware, ads, or trackers". NetShield therefore operates in Proton's DNS
    servers. The statement that queries sent to Cloudflare bypass it is an
    inference; the page states the same precedence for Android Private DNS.
43. [Debian CD torrents](https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/)
    supplied the control torrent `debian-13.8.0-amd64-netinst.iso.torrent`.
44. Inspiration: a two-level factorial design separates the effects of
    changes that occur together. Two changes preceded the failure: the
    resolver installation and the move from "Blues Junior" to `WOODMAN24`. The
    endpoint factor stands in for the second change, because the move made the
    unchanged IPv6 endpoint unreachable. The `vpn_dns` level approximates, but
    does not reproduce, the resolver configuration before the change.
    G. E. P. Box, J. S. Hunter, and W. G. Hunter, *Statistics for
    Experimenters: Design, Innovation, and Discovery*, 2nd ed., Wiley, 2005.
45. Inspiration: isolating the failure-inducing difference between a working
    state (2026-11-20) and a failing state (2026-11-24) follows scientific
    debugging and delta debugging. A. Zeller, *Why Programs Fail: A Guide to
    Systematic Debugging*, 2nd ed., Morgan Kaufmann, 2009. A. Zeller and
    R. Hildebrandt, "Simplifying and Isolating Failure-Inducing Input," *IEEE
    Transactions on Software Engineering*, 28(2):183–200, 2002.

46. [Linux IP sysctl documentation](https://github.com/torvalds/linux/blob/master/Documentation/networking/ip-sysctl.rst):
    "The max value from conf/{all,interface}/rp_filter is used when doing
    source validation on the {interface}". With `src_valid_mark` set to 1,
    "The fwmark of the packet is included in reverse path route lookup. This
    permits rp_filter to function when the fwmark is used for routing traffic
    in both directions."
47. NetworkManager source at tag 1.58.0:
    [`src/core/nm-firewall-utils.c`](https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/blob/1.58.0/src/core/nm-firewall-utils.c),
    function `_fw_nft_wg_default_construct`, builds the `premangle` and
    `postmangle` connection-mark chains. That file, `nm-device-wireguard.c`,
    and `nm-device.c` contain no `src_valid_mark`; `nm-device.c` reads
    `rp_filter` only for a connectivity-check warning. The installed binary
    contains the same rule strings.
48. wg-quick in `wireguard-tools-1.0.20250521-1.el10`, `/usr/bin/wg-quick`
    lines 238 to 240: the same two mark rules, followed by
    `sysctl -q net.ipv4.conf.all.src_valid_mark=1` for IPv4.
49. Host reverse-path configuration: `/usr/lib/sysctl.d/50-redhat.conf`
    lines 5 to 7 set `rp_filter = 1` for every interface;
    `/etc/sysctl.d/99-zzz-override_cilium.conf` line 7 sets
    `net.ipv4.conf.all.rp_filter = 0`. `src_valid_mark` remained 0 until the
    user set it on 2026-11-24.
50. Corroborating host evidence: chronyd marked its IPv6 sources online at
    21:03:06 and offline at 21:10:14; `resolvectl statistics` reported no
    failure responses since 17:01:39; with the VPN inactive, the host fetched
    the control torrent through the strict resolver at 21:31, 21:35, 21:42,
    and 22:42.

The DNS assessment applies the protocol and implementation references
directly. The VPN verification adopts the experimental design and debugging
methods of items 44 and 45.
