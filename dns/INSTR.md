# Verification and configuration procedure

1. Run the following read-only commands in a host terminal while the VPN reports
   a connected state. The assessment sandbox cannot perform these host checks.

   ```sh
   nmcli -f NAME,TYPE,DEVICE connection show --active
   nmcli -f GENERAL.DEVICE,IP4.DNS,IP6.DNS device show
   cat /etc/resolv.conf
   ip -4 rule show
   ip -4 route show table all
   ip -6 rule show
   ip -6 route show table all
   ip -4 route get 192.168.0.1
   ```

   A route through a physical interface warrants investigation. Firewall
   redirection can still change the packet destination or path. A VPN client
   that operates outside NetworkManager might not appear as a VPN connection.

2. To check ordinary DNS on a physical interface, replace `interface_name` with
   the actual Wi-Fi or Ethernet interface name and run a bounded capture:

   ```sh
   dns_interface=interface_name
   sudo timeout 20s tcpdump -nn -p -i "$dns_interface" 'udp port 53 or tcp port 53'
   ```

   During the capture, run a fresh system lookup in another terminal:

   ```sh
   getent ahosts "dns-check-$(date +%s%N).example.com"
   ```

   An absent address answer is expected for the test name. The generated DNS
   traffic provides the observation. A matching query on the physical interface
   establishes ordinary DNS outside the VPN for that lookup. Plain DNS visible
   on a virtual VPN interface alone does not establish such exposure. An empty
   physical-interface capture does not prove protection for all applications or
   for DoH traffic that uses HTTPS. Neither capture nor lookup ran during this
   assessment.

3. Select the configuration scope after identifying the VPN application.

   | Scope | Configuration choice | Verification |
   | --- | --- | --- |
   | VPN connection | Use the client's DNS leak protection and intended resolver; use its kill switch when protection must continue after disconnection. | Confirm DNS routing for IPv4 and IPv6 and the client's disconnection behavior. |
   | Chrome browser | Open Settings, Privacy and security, Security, Use secure DNS; choose an explicit provider. | Confirm the browser accepts the selected provider and retains the intended VPN route. |
   | Firefox browser | Open Settings, Privacy & Security, DNS over HTTPS; choose Max Protection for strict behavior. | Confirm DoH status; the default mode can disable DoH when it detects a VPN. |
   | System resolver | Integrate a compatible backend with NetworkManager and require authenticated DoT without plaintext fallback. | Confirm resolver status, encrypted upstream connections, VPN routing, and private-domain resolution. |

   Browser settings cover the browser's DNS behavior, not every application.
   Encrypted DNS can override a VPN provider's resolver policy. Consult the VPN
   client's documentation before combining them; the Proton reference documents
   one provider's explicit compatibility constraints.

4. Keep future environment configuration in
   `/home/ctuk/Projects/dotfiles` on `centos_xps_9700` and apply it through
   `./sync.sh`, as the repository instructions require. This document supplies
   configuration choices rather than an installation procedure because the VPN
   client and intended scope remain unknown.

5. This documentation has no compilation step. Review the Markdown and run
   `git diff --check` for changed documentation. The inspected Vim configuration
   defines no Markdown formatter or linter. See
   [sources](EVIDENCE_INSPIRATION_REFERENCE.md) for protocol and configuration
   details.
