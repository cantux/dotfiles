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

The assessment applies these protocol and implementation references directly.
It introduces no separate formal model or cross-domain analogy.
