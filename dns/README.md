# DNS privacy assessment

Root: `/home/ctuk/Projects/dotfiles/dns`.

1. The inspection on 2026-11-24 found `nameserver 192.168.0.1` in
   `/etc/resolv.conf` and both NetworkManager resolver files.
2. The execution sandbox prevented inspection of host routing and live
   NetworkManager state. These observations do not establish a DNS leak.
3. A VPN protects DNS from access-network observers when it carries the queries
   through its encrypted connection. DNS over HTTPS and DNS over TLS provide
   encryption between a client and its selected resolver; that resolver still
   receives the query contents. See [sources](EVIDENCE_INSPIRATION_REFERENCE.md).

Use [INSTR.md](INSTR.md) for host verification and configuration choices.
This assessment changes documentation only.
