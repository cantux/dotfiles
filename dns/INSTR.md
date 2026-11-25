# Application and verification

1. Run from a host terminal. The helper obtains administrator privileges,
   verifies authenticated TLS connectivity, saves configuration, installs
   `systemd-resolved` if necessary, and applies tracked files:

   ```sh
   ~/Projects/dotfiles/sync.sh --dns
   ```

   The network must reach a configured endpoint on TCP port 853. Failed
   activation or verification restores the preceding configuration.

2. Restart Brave. Open `brave://policy`, reload policies, and confirm status
   `OK` for both values:

   | Policy | Value |
   | --- | --- |
   | `BuiltInDnsClientEnabled` | `false` |
   | `DnsOverHttpsMode` | `off` |

   The system resolver supplies encryption. Proxy or VPN extensions can
   perform remote DNS independently.

3. Verify after connecting or disconnecting the VPN:

   ```sh
   ~/Projects/dotfiles/sync.sh --dns --check
   ```

   This read-only operation checks configuration and runtime state and sends
   test queries. It requires no administrator privileges. Success requires
   exact Cloudflare endpoints, strict global TLS, no per-interface servers,
   and successful queries. It does not establish the network route.

4. Inspect routing and DNS traffic in a host terminal:

   ```sh
   resolvectl status
   ip -4 route get 1.1.1.1
   ip -4 rule show
   ip -6 rule show
   sudo timeout 20s tcpdump -nn -p -i any 'tcp port 853 or udp port 53 or tcp port 53'
   ```

   During capture, run the verification command in another terminal. Plain
   DNS to `127.0.0.53` on loopback is expected. A VPN interface can show the
   inner TLS exchange; a physical interface normally shows encrypted VPN
   packets when the VPN carries that exchange. Inspect IPv6 routes when the
   upstream uses IPv6. Firewall or proxy redirection can change routing.

5. Inspect errors if strict DNS becomes unavailable:

   ```sh
   journalctl -u systemd-resolved -b --no-pager -n 80
   systemd-analyze cat-config systemd/resolved.conf
   ```

   The resolver fails resolution when authenticated TLS fails. It does not
   switch to plaintext. Public upstreams do not resolve VPN-only domain names.

6. Restore the original configuration:

   ```sh
   ~/Projects/dotfiles/sync.sh --dns --undo
   ```

   Restart Brave. Restoration recovers original files, symlinks, ownership,
   and resolver service state; it retains packages. This operation also
   supports recovery after interruption.

7. No compilation applies. Format Python before validation:

   ```sh
   cd ~/Projects/dotfiles
   yapf -i dns/configure.py dns/test_configure.py
   python3 -B -m unittest discover -s dns -p test_configure.py -v
   bash -n sync.sh
   python3 -m json.tool dns/brave-policy.json
   git diff --check
   ```

   Vim defines no Markdown, INI, JSON, or Bash save-time formatter or linter.
   Keep environment changes in this repository on `centos_xps_9700` and apply
   them through `sync.sh`.

   The 18 isolated tests use real temporary files and symlinks and simulate
   host commands. They cover rollback before and after activation, package
   changes to resolver files, failed backup creation, repeat execution,
   restoration, strict TLS requirements, wrapped DNS output, and foreign DNS.
   They do not establish host TLS reachability or Brave policy acceptance.
