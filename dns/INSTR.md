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

8. Check the TAP-based laboratory from a host terminal. Select the kubeconfig
   for the cluster currently occupying the shared bridge. This example selects
   the native laboratory; the tutorial uses
   `~/Projects/ai/kubernetes_learning/.state/main/kubeconfig` instead.

   ```sh
   dns_kubeconfig="$HOME/Projects/ai/kubernetes/.state/kubeconfig"
   ip -brief address show br-lab
   bridge link show master br-lab
   kubectl --kubeconfig="$dns_kubeconfig" get nodes -o wide
   kubectl --kubeconfig="$dns_kubeconfig" -n kube-system get pods -l k8s-app=kube-dns
   ```

   Use an existing pod with `nslookup` to check cluster and external DNS.
   Replace the namespace and pod name with actual values:

   ```sh
   dns_namespace=default
   dns_pod=existing_pod_name
   kubectl --kubeconfig="$dns_kubeconfig" -n "$dns_namespace" exec "$dns_pod" -- nslookup kubernetes.default.svc.cluster.local
   kubectl --kubeconfig="$dns_kubeconfig" -n "$dns_namespace" exec "$dns_pod" -- nslookup example.com
   ```

   These commands change no cluster configuration and create no probe pods.
   Successful queries prove name resolution for that pod; they do not prove
   TLS encryption. Inspect the guest and CoreDNS upstream settings separately.

9. Verify DNS while the VPN is active from a host terminal. Activate the VPN
   through its normal connection control, then inspect actual state:

   ```sh
   nmcli -t -f NAME,TYPE,DEVICE connection show --active
   ~/Projects/dotfiles/sync.sh --dns --check
   resolvectl status
   ip -4 route get 1.1.1.1
   ip -4 route get 1.0.0.1
   ip -6 route get 2606:4700:4700::1111
   ip -6 route get 2606:4700:4700::1001
   ```

   Check the route for the server the resolver actually uses. A destination
   on the VPN interface supports the intended route; route output alone does
   not prove packet traversal or exclude firewall redirection.

   Capture traffic in one terminal:

   ```sh
   sudo timeout 20s tcpdump -nn -p -i any 'tcp port 853 or udp port 53 or tcp port 53'
   ```

   Generate a network query in another terminal:

   ```sh
   resolvectl --cache=no --synthesize=no --type=A query example.com
   ```

   DNS on loopback is expected. With VPN routing, the VPN interface shows the
   inner TCP 853 exchange, while the physical interface carries encrypted VPN
   transport. TCP 853 to Cloudflare on the physical interface indicates direct
   DoT outside the VPN: it still encrypts DNS contents but does not hide the
   access-network source address from Cloudflare. Plain DNS on TAP or bridge
   interfaces can come from guests; this host configuration does not encrypt
   guest forwarding. Repeat after VPN disconnection to compare behavior.

   No host VPN activation or capture has occurred; step 11 reproduces the VPN
   path in containers. `--check` verifies the resolver configuration and
   queries, not VPN routing.

10. Capture evidence during a repeated lookup delay. In one host terminal:

    ```sh
    sudo resolvectl monitor
    ```

    In another host terminal, time an upstream query without using the local
    resolver cache or synthetic answers:

    ```sh
    time resolvectl --cache=no --synthesize=no query piratebay.org
    ```

    Record the exact domain, time, browser error, and command result. The
    monitor shows completed local queries and answers; it does not capture
    individual upstream packets. The timed query requests IPv4 and IPv6
    addresses. Quick results while Brave remains delayed support checking
    browser caching, other hostnames the page needs, and the subsequent
    website connection. A slow or failed system lookup supports investigation
    of resolver and upstream transport behavior.

    Normal resolver logging need not retain per-query timing. An incident
    that has already recovered may therefore lack enough evidence for a
    retrospective diagnosis. Preserve the observations before flushing caches
    or restarting services.

11. Reproduce the VPN path in containers from a host terminal. The harness
    requires rootless Podman, the loaded `wireguard` kernel module, and the
    profile's source file. It changes no host network setting:

    ```sh
    ~/Projects/dotfiles/dns/vpn_container/run_matrix.sh
    ~/Projects/dotfiles/dns/vpn_container/run_matrix.sh ipv4_strict_dot
    ```

    The cells are `ipv6_strict_dot`, `ipv4_strict_dot`, `ipv4_vpn_dns`, and
    `ipv6_vpn_dns`. Without arguments, the harness runs all four in about 16
    minutes. `WIREGUARD_SOURCE` selects another source file;
    `QBITTORRENT_SECONDS` sets the qBittorrent interval (default 75). Each run
    writes `vpn_container/evidence/<timestamp>/`, and the `summary.` lines of
    each cell file report its result. Keep the host profile inactive during a
    run: the VPN server tracks one endpoint per peer key.

    Check the scripts after a change:

    ```sh
    cd ~/Projects/dotfiles/dns/vpn_container
    bash -n cell_probe.sh run_matrix.sh
    podman run --rm -i docker.io/koalaman/shellcheck:stable --shell=bash - < cell_probe.sh
    podman run --rm -i docker.io/koalaman/shellcheck:stable --shell=bash - < run_matrix.sh
    ```

12. Correct the profile when the access network has no IPv6 route. Confirm the
    condition:

    ```sh
    nmcli -f wireguard.peers connection show wg-US-CA-515
    ip -6 route get 2a02:6ea0:e606:3742::10
    ```

    "Network is unreachable" for the stored endpoint identifies the failure.
    Select the IPv4 endpoint from the same source file, then activate and
    verify:

    ```sh
    nmcli connection modify wg-US-CA-515 wireguard.peers 'Yg7VdAicq2Rj/FNl7dGvm4jB2XlmrzwBj6/eosX5CiY= endpoint=149.22.84.89:51820 allowed-ips=0.0.0.0/0;::/0 persistent-keepalive=25'
    nmcli connection up wg-US-CA-515
    curl -sS --max-time 15 https://1.1.1.1/cdn-cgi/trace | grep '^ip='
    resolvectl --cache=no --synthesize=no query tracker.opentrackr.org
    ```

    Success shows a Proton exit address (`149.22.84.92` in the container
    evidence) and an answer "acquired via local or encrypted transport". The
    IPv4 endpoint also serves dual-stack networks. To restore the IPv6
    endpoint, repeat the modification with
    `endpoint=[2a02:6ea0:e606:3742::10]:51820`. Commenting out the IPv6
    `Endpoint` line in `~/Downloads/wg-US-CA-515.conf` prevents the same
    selection on a later import.
