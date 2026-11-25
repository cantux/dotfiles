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

The assessment applies these protocol and implementation references directly.
It introduces no separate formal model or cross-domain analogy.
