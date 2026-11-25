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
connections. Public DNS does not resolve VPN-only internal names. The same
command installs `/etc/sysctl.d/90-dotfiles-src-valid-mark.conf`, which the
IPv4 VPN profile requires on this host.

Status: installed after the user's host synchronization run. The package,
three installed configuration files, and resolver symlink match the design,
and host resolver status confirmed strict TLS to Cloudflare on 2026-11-24.
All 18 isolated tests passed. Strict DNS over TLS works through the VPN
tunnel. The qBittorrent failure of 2026-11-24 came from the VPN profile's
IPv6 endpoint on a network without IPv6; the DNS change altered only the
error message. The IPv4 endpoint also needs
`net.ipv4.conf.all.src_valid_mark=1` on this host. Profile
`wg-US-CA-515-ipv4` and the sysctl file apply the two corrections;
[INSTR.md](INSTR.md) step 12 describes them. VM and pod DNS encryption requires separate configuration;
the host change leaves bridge and TAP forwarding intact.
See [INSTR.md](INSTR.md) for verification, restoration, and tests, and
[sources](EVIDENCE_INSPIRATION_REFERENCE.md) for implementation references.
