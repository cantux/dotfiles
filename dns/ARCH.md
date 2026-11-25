# DNS paths and privacy boundaries

1. A recursive resolver receives DNS questions and obtains or caches answers.
   A DNS leak occurs when a query bypasses the intended VPN routing policy.
2. VPN encryption protects traffic between the VPN client and VPN endpoint.
   Plain DNS inside that connection can protect query contents from the local
   network and internet service provider. The resolver and VPN endpoint can
   observe those contents.
3. DNS over HTTPS (DoH) and DNS over TLS (DoT) encrypt the client-to-resolver
   exchange. The resolver receives query contents. These protocols do not
   establish which network interface carries the encrypted exchange.

| Query path | Access-network observation | Resolver observation |
| --- | --- | --- |
| Plain DNS outside the VPN | DNS contents appear on the network path. | Query contents and source address. |
| Plain DNS inside the VPN | VPN traffic conceals DNS contents until the VPN endpoint. | Query contents; source depends on VPN forwarding. |
| DoH or DoT inside the VPN | VPN traffic conceals DNS contents; TLS also protects the exchange to the resolver. | Query contents and the address presented by the VPN. |
| DoH or DoT outside the VPN | TLS conceals DNS contents; connection metadata remains visible. | Query contents and the non-VPN source address, subject to address translation. |

4. `/etc/resolv.conf` names a destination; it does not prove the actual packet
   path. Firewall redirection, application-specific DNS, proxies, and router
   forwarding can change the interpretation.
5. A router can encrypt its upstream DNS while the computer still sends plain
   DNS to the router. Router configuration therefore cannot establish encryption
   between this computer and its resolver.
6. NetworkManager's `connection.dns-over-tls` setting requires a compatible
   plugin. Its `yes` mode prohibits plaintext fallback; `opportunistic` permits
   fallback. Merely replacing a nameserver address does not enable TLS.
7. NetworkManager supports `systemd-resolved` and `dnsconfd` integration.
   Global DNS overrides can displace VPN-supplied DNS and private-domain rules.
   Configuration must account for the selected VPN client, IPv4, IPv6,
   application-specific DNS, and behavior after disconnection.

See [primary references](EVIDENCE_INSPIRATION_REFERENCE.md). The assessment
does not identify the installed VPN client or establish its connected state.
