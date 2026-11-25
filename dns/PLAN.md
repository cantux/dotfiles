# System DNS configuration plan

Root: `/home/ctuk/Projects/dotfiles/dns`.

Goal: configure the system resolver for authenticated DNS over TLS without
plaintext fallback and make Brave use that resolver. Keep the source in the
`centos_xps_9700` dotfiles branch and apply it through `./sync.sh`.

1. State: complete. Add the resolver and Brave configurations, an installation and
   restoration procedure, and a DNS-specific `sync.sh` entry. Keep the initial
   implementation complete across configuration, activation, and documentation.
   Check: review primary implementation documentation; validate configuration
   syntax and Bash syntax; confirm that restoration preserves the prior files.
   Result: primary-source review, YAPF, Python/INI/JSON validation, document
   links, Bash syntax, and the `sync.sh --dns --help` dispatch check passed.
2. State: complete. Delegate independent review and verification of TLS enforcement,
   Brave policy, installation failures, restoration, and repeat execution.
   Check: resolve findings and record the validation results.
   Result: 18 isolated tests passed after correcting multiline DNS status
   parsing and cleanup after a failed initial baseline copy. Tests cover real
   temporary files and symlinks with simulated host commands and no network.
3. State: installed; live verification pending. Apply the configuration and verify resolver
   status, successful DNS queries, Brave policy, and VPN routing.
   Check: collect host results. The current sandbox prevents root operations
   through its `no new privileges` restriction, so host activation requires a
   terminal outside this sandbox.
   Initial sandbox attempt: `./sync.sh --dns` exited 1 because `sudo` could not obtain
   root under `no new privileges`. `--check` confirmed the managed configuration
   is absent. `/etc/resolv.conf` still names `192.168.0.1` and the resolver
   package remains absent. This unit remains open for host execution.
   Follow-up result: the user ran synchronization. The package is now installed,
   all three installed configuration files match their sources, and the resolver
   symlink selects the local stub. The sandbox still denies system-bus and
   network access, so live service, DNS, Brave, and VPN checks remain pending.
4. State: complete. Review loopback and TAP-based Kubernetes compatibility
   without changing the laboratory. Check: compare changed host components with
   bridge, guest resolver, kubelet, and CoreDNS configuration; distinguish source
   and archived evidence from live checks; obtain independent review and record
   findings.
   Result: source and archived evidence show separate guest and cluster DNS.
   Independent review confirmed that host changes do not alter loopback IP
   paths, bridge/TAP forwarding, routing, or NAT. Documented local DNS listener
   conflicts, private-name changes, namespace-local loopback, and the absence
   of automatic TLS protection for guest and pod DNS. Live checks remain
   unavailable; no laboratory configuration changed.
5. State: complete. Explain the DNS request sequence and distinguish DNS
   encryption from VPN routing. Check: re-read installed configuration and
   primary protocol documentation; state the absent VPN test explicitly;
   document a host procedure that observes both the resolver and its route.
   Result: documented cache handling, loopback, TCP routing, TLS authentication,
   optional VPN encapsulation, and response handling. Added a host capture
   procedure. Document links, shell syntax, and whitespace checks passed.
   Live VPN verification remains open under unit 3.

Only the primary session updates this plan, updates `WORKLOG.md`, and commits.
