# Work log

Root: `/home/ctuk/Projects/dotfiles/dns`.

1. 2026-11-24: Established one work unit: document the available DNS evidence,
   explain VPN and DNS encryption boundaries, and provide host verification.
2. Read `/etc/os-release`: CentOS Stream 10. Queried RPM: NetworkManager
   `1.58.0-1.el10` exists; `systemd-resolved`, `dnsconfd`, and the `unbound`
   server package do not exist in the installed package set.
3. Read `/etc/resolv.conf`, `/run/NetworkManager/resolv.conf`, and
   `/run/NetworkManager/no-stub-resolv.conf`: each names `192.168.0.1` as its
   only resolver. The files identify NetworkManager as their generator.
4. Attempted `ip`, `nmcli`, and `resolvectl` inspection. The sandbox denied
   netlink or system-bus access. Its `/proc/net/dev` exposed only loopback.
   These restrictions prevent a conclusion about host VPN connectivity or DNS
   leakage; they do not establish an absent VPN.
5. Queried common VPN package names and Flatpak applications without identifying
   the client. Requested the VPN application name and connected state. Reviewed
   primary DNS protocol, NetworkManager, browser, and provider documentation.
6. Created the six assessment documents. Kept existing repository changes
   outside this directory intact. Made no resolver, VPN, or environment changes.
7. Completed the work unit after reviewing the documentation and validating
   whitespace, local document links, and shell syntax. Host routing checks and
   packet capture remain unperformed; they require a host terminal.
8. 2026-11-24: The requested scope changed to system DNS configuration, with
   Brave as the browser. Read the existing assessment, repository instructions,
   synchronization script, and working-tree state before implementation.
9. Confirmed Brave `1.100.58-1` and the absence of the `systemd-resolved` package.
   `sudo -n true` failed because the sandbox sets `no new privileges`.
   The current session cannot install packages, change `/etc`, or activate host
   services. Added `PLAN.md` before the first configuration change.
10. Completed implementation unit 1: added strict Cloudflare DNS over TLS,
    disabled NetworkManager DNS injection, selected the operating system DNS
    client for Brave, and added a DNS-specific `sync.sh` dispatch. The helper
    preserves original and transaction snapshots, applies atomic file changes,
    restores SELinux labels, verifies runtime state, and supports restoration.
11. Reviewed systemd 257, NetworkManager, Brave, Chromium policy, and Cloudflare
    primary references. Ran YAPF, Python/INI/JSON syntax and configuration checks,
    document-link validation, Bash syntax, whitespace checks, and
    `./sync.sh --dns --help`; all passed. Host activation remains pending.
12. Completed verification unit 2 through independent review and isolated tests.
    Review identified wrapped `resolvectl dns` output and failure cleanup when
    initial baseline creation fails before making the destination. Corrected
    both conditions and added regression coverage.
13. Ran `yapf -i dns/configure.py dns/test_configure.py`, then
    `python3 -B -m unittest discover -s dns -p test_configure.py -v`.
    All 18 tests passed. Tests exercise real temporary files and symlinks while
    simulating package, service, label, and DNS commands. They do not execute
    privileged host operations or send network traffic.
14. Attempted deployment unit 3 with `./sync.sh --dns`. The command exited 1
    because `sudo` cannot obtain root under the sandbox's `no new privileges`
    restriction. No package or host configuration change occurred.
15. Ran `./sync.sh --dns --check`; it exited 1 because the managed NetworkManager
    configuration does not exist. Rechecked `/etc/resolv.conf`: it still names
    `192.168.0.1`. RPM still reports `systemd-resolved` absent. Kept deployment
    unit 3 open and documented the exact command for a host terminal.
16. Committed only this task's changes. The existing unrelated working-tree
    changes, including prior `sync.sh` edits, remain outside these commits.
17. 2026-11-24: The user reported running synchronization and requested the
    exact changes and loopback/Kubernetes compatibility. Re-read the plan and
    log. Confirmed `systemd-resolved-257-35.el10` installed, all three managed
    files identical to their sources, and `/etc/resolv.conf` pointing to the
    local stub with `nameserver 127.0.0.53`.
18. Runtime verification reached the service check but the sandbox denied
    system-bus access. A read-only Kubernetes query likewise failed because
    the sandbox denies sockets. These failures do not establish a host or
    cluster failure. Added compatibility review unit 4 before documentation
    changes.
19. Inspected the Kubernetes laboratory source: separate Debian guests,
    bridge `br-lab`, user-owned TAPs, and dedicated NAT. Both native and
    tutorial seeds select guest DNS `1.1.1.1` and `9.9.9.9`; native seeds
    write guest lab-name mappings to `/etc/hosts`.
20. Read archived tutorial evidence dated 2026-11-16: guest kubelet uses
    cluster DNS `10.96.0.10` and `/run/systemd/resolve/resolv.conf`; CoreDNS
    handles cluster names and forwards other queries using its own resolver
    file. Distinguished this archive from live state.
21. Completed independent read-only compatibility review. Documented that
    loopback addresses identify their own namespace, guest DNS does not gain
    host TLS, wildcard DNS listeners can conflict, and private-name discovery
    differs under the static public resolver policy. Added non-destructive
    laboratory verification instructions. Changed documentation only.
22. Validated local documentation links, Bash syntax for documented shell
    commands, and whitespace. All checks passed. Kept host runtime verification
    open because the sandbox still denies service and network access.
23. 2026-11-24: The user requested confirmation of VPN testing and a mechanical
    explanation. Confirmed that no VPN activation or packet capture has occurred.
    Re-read installed settings: strict DNS over TLS remains configured, with
    Brave using the system resolver. Live NetworkManager and route queries
    still fail under the sandbox. The saved VPN profile also denies reads.
24. Documented the mechanical DNS sequence and the separate TLS and VPN layers.
    Added a host-side procedure for VPN-on inspection, routing to each upstream,
    packet capture, and a query that bypasses cache and synthesis. Clarified
    that `--check` does not verify VPN routing. Rechecked primary systemd,
    Cloudflare, RFC 7858, and VPN protocol references. Document-link, shell
    procedure syntax, and whitespace checks passed. Changed documentation only.
25. 2026-11-24, approximately 20:55 PST: The user reported that a previously
    failing domain lookup recovered and requested retrospective diagnosis.
    Reviewed resolver logs since installation at 17:01 and recent network,
    kernel, suspend, and hibernate journals. The resolver recorded normal
    startup at 17:01:39 and no subsequent events. NetworkManager recorded a
    DHCP lease renewal at 20:14:34; the last 15 minutes contained no entries.
    Kernel and suspend/hibernate journals contained no entries for the last
    45 minutes.
26. Found no recorded timeout, TLS error, DNSSEC validation error, resolver
    restart, or domain-specific query timing. These logs cannot establish
    the delay's cause. Requested the duration and browser error. Cache expiry
    and transient upstream or transport failures remain unverified possibilities.
    Made no resolver, VPN, browser, or logging configuration change.
27. 2026-11-24, approximately 21:15 PST: The user reported that the resolver
    change appeared to break qBittorrent and requested a container test with
    the VPN configuration. Read resolver status, the installed drop-in, the
    DNS commits, the qBittorrent configuration and log, and the NetworkManager
    journal.
28. Established the failure window. NetworkManager activated `wg-US-CA-515` at
    21:03:06. qBittorrent 5.2.3, bound to interface `wg-US-CA-515` and port
    51820, logged "Couldn't download IP geolocation database file. Reason: The
    remote host name was not found (invalid hostname)" at 21:03:19; its binary
    names `download.db-ip.com` for that file. The user deactivated the profile
    at 21:10:13. Separately, 86 of 89 "Failed to restore torrent" warnings
    name the unmounted external drive `/run/media/ctuk/Seagate Expansion Drive`.
29. Identified a second change before the failure. The profile's peer endpoint
    is `[2a02:6ea0:e606:3742::10]:51820`, the last of two uncommented
    `Endpoint` lines in `~/Downloads/wg-US-CA-515.conf`; the first line names
    `149.22.84.89:51820`. The host returns "Network is unreachable" for the
    IPv6 endpoint: network `WOODMAN24`, first joined 2026-11-23 14:36, supplies
    no global IPv6 address or gateway. qBittorrent last detected VPN exit
    addresses on 2026-11-20 and did not run again until 2026-11-24 21:03.
30. Added verification units 6 to 9 to `PLAN.md`. Built a CentOS Stream 10
    image with the host's `systemd-resolved-257-35.el10`, the repository
    resolver file, `wireguard-tools`, and `qbittorrent-nox` 5.2.4. Wrote the
    orchestrator and probe; both passed `bash -n` and ShellCheck 0.11.0, run
    from its container image with the scripts on standard input.
31. The first host-replica run exposed a harness defect: `systemd-resolved`
    exited with status 217/USER ("Failed to keep CAP_SYS_ADMIN") under rootless
    Podman's default capabilities, and lookups failed in 0.00 seconds against an
    absent stub. A paired container comparison showed that `--cap-add SYS_ADMIN`
    starts the resolver. Added that capability, a resolver-state summary line,
    a recorded egress command, and a `resolvectl query`. Renamed the defective
    run's directory to `20261124T213123_resolver_inactive`.
32. Reran the host-replica cell (`20261124T213537`). The resolver ran with the
    host's global configuration. The tunnel sent one 148-byte handshake
    initiation and received nothing. Egress, DNS over TLS, and the VPN resolver
    timed out; 0 of 9 lookups resolved, each after 10.02 seconds. qBittorrent
    reported 0 of 6 trackers working, 0 DHT nodes, and the host's geolocation
    error. No evidence file contains private key material; no container or
    secret directory remained. Unit 6 complete.
33. Changed container names to hyphenated forms: the resolver rejected the
    underscore in the name that Podman writes to `/etc/hosts`. Ran the
    four-cell matrix (`20261124T214244`) from 21:42 to 21:57 PST.

    | Cell | Endpoint | Resolver | Handshake | Lookups | qBittorrent after 75 s |
    | --- | --- | --- | --- | --- | --- |
    | `ipv6_strict_dot` | IPv6 | strict DNS over TLS | no | 0/9, 10.02 s each | firewalled; 0 DHT nodes; 0 bytes; geolocation lookup failed |
    | `ipv4_strict_dot` | IPv4 | strict DNS over TLS | yes | 9/9, 0.16 to 1.00 s | connected; 354 DHT nodes; 149,079,220 bytes; 89 seeds |
    | `ipv4_vpn_dns` | IPv4 | VPN resolver without TLS | yes | 9/9, 0.09 to 0.31 s | connected; 332 DHT nodes; 152,405,090 bytes; 95 seeds |
    | `ipv6_vpn_dns` | IPv6 | VPN resolver without TLS | no | 0/9, 20.04 s each | firewalled; 0 DHT nodes; 0 bytes; geolocation lookup failed |

34. The endpoint family alone determines the outcome; the resolver mode does
    not change it. With the IPv4 endpoint, the strict resolver authenticated
    `cloudflare-dns.com` on IPv4 and IPv6 port 853 through the tunnel, and
    `resolvectl` reported encrypted transport on link `wg-US-CA-515`.
    qBittorrent detected the exit addresses `149.22.84.92` and
    `2a02:6ea0:e606:3742::13`, which match its log of 2026-11-20. The lookup
    durations equal the glibc defaults: 5-second timeout times 2 attempts for
    one server (10 s) and for two servers (20 s).
35. Recorded two anomalies that do not vary with resolver mode. First, in
    `ipv4_strict_dot` the IPv4 HTTPS trace to `1.1.1.1` failed with curl exit
    35 (TLS connect error), while the IPv6 trace, DNS over TLS to
    `1.1.1.1:853`, and the download succeeded in the same cell; this request
    uses an IP literal and no DNS. Second, in both IPv4 cells one of six
    trackers worked: Debian's HTTP tracker reset the connection and four UDP
    trackers remained uncontacted within 75 seconds. No evidence file
    contains key material. Unit 7 complete.
36. Documented the cause, the correction, and the harness: `ARCH.md` (VPN
    endpoint and resolver interaction; harness design, invariants, and four
    deviations from the host), `INSTR.md` (steps 11 and 12; step 9 updated),
    the `README.md` status, `MAP.md`, and evidence items 34 to 45. A web-fetch
    subagent read Proton's NetShield page, which it quoted verbatim, and the
    qBittorrent API wiki. A recheck of the raw wiki Markdown confirmed the
    tracker status table verbatim. The local manual confirmed NetworkManager's
    DNS priority defaults. All 32 local links resolve; the new shell blocks
    pass `bash -n`; `git diff --check` is clean. Unit 8 complete.
37. Obtained the independent review (unit 9). The reviewer derived the same
    cause from primary evidence before reading the documents and reported 13
    findings. Verified directly:
    1. The host applies strict reverse-path filtering on `wlp0s20f3`
       (`/usr/lib/sysctl.d/50-redhat.conf`) with `src_valid_mark=0`.
       NetworkManager 1.58.0 installs wg-quick's connection-mark rules
       (`_fw_nft_wg_default_construct`) but sets no `src_valid_mark`, so the
       kernel validates reply sources without the restored mark. The harness
       masked this condition with loose filtering, so the IPv4-endpoint
       correction remains unverified for the host.
    2. The seed counts in entry 33 are swapped: `ipv4_strict_dot` has 95 and
       `ipv4_vpn_dns` 89. The system `grep` (ugrep) printed the two files out
       of order.
    3. Failed lookups took 10.01 to 10.02 s and 20.02 to 20.04 s. The final
       counters of 10,360 and 9,768 bytes equal 70 and 66 unanswered
       initiations.
    4. chronyd marked its IPv6 sources online at 21:03:06 and offline at
       21:10:14, so the tunnel's `::/0` route was the host's only IPv6 path.
    The reported Brave errors were absent from the user journal and were not
    adopted. Units 10 and 11 resolve the findings. Unit 9 complete.
38. Unit 10. Changed the harness to inherit the host's reverse-path settings
    instead of loose filtering, to install NetworkManager 1.58.0's nftables
    rules (table `nm-wg-wg-US-CA-515`: `preraw`, `premangle`, `postmangle`),
    to add `src_valid_mark` as a cell factor (suffix `_valid_mark`), to record
    the effective sysctls and the `IPReversePathFilter` counter, to repeat the
    IPv4 trace five times after a handshake, and to require
    `XDG_RUNTIME_DIR`. A smoke container confirmed the inherited values
    (`all.rp_filter=0`, `default.rp_filter=1`, `wlp0s20f3.rp_filter=1`,
    `src_valid_mark=0`) and that NetworkManager's rule text loads. Stopped a
    six-cell run during its first cell to shorten the wait, removed its
    incomplete directory, and ran the two decisive cells (`20261124T224242`):

    | Cell | `src_valid_mark` | Reverse-path drops | Tunnel | Lookups | qBittorrent |
    | --- | --- | --- | --- | --- | --- |
    | `ipv4_strict_dot` | 0 | 69 | 0 bytes received | 0/9 | firewalled; the host's geolocation error |
    | `ipv4_strict_dot_valid_mark` | 1 | 0 | 177,626,332 bytes received | 9/9 | connected; 339 DHT nodes; 145,795,635 bytes |

    In the second cell the first initiation went unanswered during the
    2-second ping, so its summary reads `handshake=no`; WireGuard's 5-second
    retry established the tunnel before the egress probe.
39. The user set `net.ipv4.conf.all.src_valid_mark=1` at runtime and asked for
    a working profile. Wrote `~/Downloads/wg-US-CA-515-ipv4/wg-US-CA-515.conf`
    (mode 600; IPv6 `Endpoint` commented out; key line identical). Imported it
    as `wg-US-CA-515-ipv4` (UUID `7d0da835-83c3-4a67-84fa-c5c5069697a4`) with
    autoconnect off; the original profile remains unchanged. Activated it
    under a guard that reverts after 15 seconds without a reply. The Proton
    resolver answered on attempt 4; egress showed `149.22.84.92`; the
    resolver reported encrypted transport on link `wg-US-CA-515`;
    `IPReversePathFilter` rose from 315 to 335 during activation.
    qBittorrent held no sockets and requires a restart. Evidence:
    `host_ipv4_profile.txt`. Unit 10 complete.
