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

Status: installed after the user's host synchronization run. The package,
three installed configuration files, and resolver symlink match the design,
and host resolver status confirmed strict TLS to Cloudflare on 2026-11-24.
All 18 isolated tests passed. Container tests show that strict DNS over TLS
works through the `wg-US-CA-515` VPN tunnel. The qBittorrent failure of
2026-11-24 came from the profile's IPv6 VPN endpoint on a network without
IPv6, not from DNS; [INSTR.md](INSTR.md) step 12 gives the correction.
VM and pod DNS encryption requires separate configuration; the host change
leaves bridge and TAP forwarding intact.
See [INSTR.md](INSTR.md) for verification, restoration, and tests, and
[sources](EVIDENCE_INSPIRATION_REFERENCE.md) for implementation references.
