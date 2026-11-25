# System DNS over TLS

Root: `/home/ctuk/Projects/dotfiles/dns`.

1. Apply from a host terminal:

   ```sh
   ~/Projects/dotfiles/sync.sh --dns
   ```

2. Restart Brave. Open `brave://policy` and confirm
   `BuiltInDnsClientEnabled=false` and `DnsOverHttpsMode=off`.

The system resolver encrypts upstream queries to Cloudflare over authenticated
TLS. Brave uses the operating system DNS client. The configuration prohibits
plaintext fallback and uses public DNS for all domains, including during VPN
connections. Public DNS does not resolve VPN-only internal names.

Status: prepared in the repository; host activation remains pending because
the execution sandbox prevents root operations. All 18 isolated tests passed.
The deployment attempt stopped at `sudo`; the host still uses `192.168.0.1`.
See [INSTR.md](INSTR.md) for verification, restoration, and tests, and
[sources](EVIDENCE_INSPIRATION_REFERENCE.md) for implementation references.
