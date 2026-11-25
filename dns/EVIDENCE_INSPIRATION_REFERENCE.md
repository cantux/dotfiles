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

The assessment applies these protocol and implementation references directly.
It introduces no separate formal model or cross-domain analogy.
