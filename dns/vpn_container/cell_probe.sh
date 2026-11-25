#!/usr/bin/env bash
set -uo pipefail

readonly endpoint_family=$1
readonly resolver_mode=$2
readonly qbittorrent_seconds=$3
readonly interface_name=wg-US-CA-515
readonly routing_mark=51820
readonly source_config=/mnt/vpn-secret/source.conf
readonly setconf_file=/run/wg-setconf.conf
readonly torrent_file=/mnt/vpn-input/control.torrent
readonly webui_base=http://127.0.0.1:8080/api/v2
readonly qbittorrent_home=/home/qbt
readonly lookup_names=(
  download.db-ip.com
  tracker.opentrackr.org
  open.stealth.si
  tracker.torrent.eu.org
  open.demonii.com
  exodus.desync.com
  router.bittorrent.com
  dht.transmissionbt.com
  bttracker.debian.org
)
readonly magnet_trackers=(
  udp://tracker.opentrackr.org:1337
  udp://open.stealth.si:80/announce
  udp://tracker.torrent.eu.org:451/announce
  udp://open.demonii.com:1337/announce
  udp://exodus.desync.com:6969
)

selected_endpoint=none
resolver_service_state=not_checked
handshake_state=no
egress_address=none
egress_successes=0
egress_attempts=0
dns_over_tls_state=fail
lookup_resolved_count=0
qbittorrent_connection_status=none
qbittorrent_dht_nodes=0
qbittorrent_trackers_working=0
qbittorrent_trackers_total=0
qbittorrent_downloaded_bytes=0
qbittorrent_geolocation=none
uplink_interface_name=none
reverse_path_drops_before=0

print_section() {
  printf '\n== %s\n' "$1"
}

run_logged() {
  printf '$ %s\n' "$*"
  local exit_status=0
  "$@" 2>&1 || exit_status=$?
  printf '[exit %d]\n' "$exit_status"
  return "$exit_status"
}

read_value() {
  local section=$1
  local key=$2
  awk -v section="[$section]" -v key="$key" '
    /^[[:space:]]*\[/ {
      current_section = $0
      gsub(/[[:space:]]/, "", current_section)
    }
    current_section == section && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      value = $0
      sub(/^[^=]*=[[:space:]]*/, "", value)
      sub(/[[:space:]]+$/, "", value)
      print value
    }' "$source_config"
}

split_list() {
  tr ',' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d'
}

select_endpoint() {
  local family=$1
  local endpoint
  while IFS= read -r endpoint; do
    if [[ $family == ipv6 && $endpoint == \[* ]]; then
      printf '%s\n' "$endpoint"
      return 0
    fi
    if [[ $family == ipv4 && $endpoint != \[* ]]; then
      printf '%s\n' "$endpoint"
      return 0
    fi
  done < <(read_value Peer Endpoint)
  return 1
}

endpoint_address() {
  local endpoint=$1
  if [[ $endpoint == \[* ]]; then
    endpoint=${endpoint#\[}
    printf '%s\n' "${endpoint%%\]*}"
  else
    printf '%s\n' "${endpoint%:*}"
  fi
}

first_vpn_resolver() {
  read_value Interface DNS | split_list | head -n 1
}

write_setconf_file() {
  local endpoint=$1
  local previous_umask
  previous_umask=$(umask)
  umask 077
  {
    printf '[Interface]\n'
    printf 'PrivateKey = %s\n\n' "$(read_value Interface PrivateKey)"
    printf '[Peer]\n'
    printf 'PublicKey = %s\n' "$(read_value Peer PublicKey)"
    printf 'AllowedIPs = %s\n' "$(read_value Peer AllowedIPs)"
    printf 'Endpoint = %s\n' "$endpoint"
    printf 'PersistentKeepalive = %s\n' "$(read_value Peer PersistentKeepalive)"
  } > "$setconf_file"
  umask "$previous_umask"
}

create_tunnel() {
  local address
  run_logged ip link add "$interface_name" type wireguard
  run_logged wg setconf "$interface_name" "$setconf_file"
  run_logged wg set "$interface_name" fwmark "$routing_mark"
  while IFS= read -r address; do
    run_logged ip address add "$address" dev "$interface_name"
  done < <(read_value Interface Address | split_list)
  run_logged ip link set dev "$interface_name" mtu 1420 up
  run_logged ip -4 route add default dev "$interface_name" table "$routing_mark"
  run_logged ip -4 rule add priority 32764 table main suppress_prefixlength 0
  run_logged ip -4 rule add priority 32765 not fwmark "$routing_mark" \
    table "$routing_mark"
  run_logged ip -6 route add default dev "$interface_name" table "$routing_mark"
  run_logged ip -6 rule add priority 32764 table main suppress_prefixlength 0
  run_logged ip -6 rule add priority 32765 not fwmark "$routing_mark" \
    table "$routing_mark"
}

write_networkmanager_rules() {
  local table_name=nm-wg-$interface_name
  local address
  local family
  for family in ip ip6; do
    printf 'add table %s %s\n' "$family" "$table_name"
    printf 'flush table %s %s\n' "$family" "$table_name"
  done
  while IFS= read -r address; do
    address=${address%/*}
    family=ip
    if [[ $address == *:* ]]; then
      family=ip6
    fi
    printf 'add chain %s %s preraw { iifname != "%s" %s daddr %s fib saddr type != local drop; }\n' \
      "$family" "$table_name" "$interface_name" "$family" "$address"
  done < <(read_value Interface Address | split_list)
  for family in ip ip6; do
    printf 'add chain %s %s premangle { type filter hook prerouting priority mangle; policy accept; meta l4proto udp meta mark set ct mark; }\n' \
      "$family" "$table_name"
    printf 'add chain %s %s postmangle { type filter hook postrouting priority mangle; policy accept; meta l4proto udp mark 0x%08x ct mark set meta mark; }\n' \
      "$family" "$table_name" "$routing_mark"
  done
}

apply_networkmanager_rules() {
  write_networkmanager_rules > /run/nm-wg.nft
  run_logged cat /run/nm-wg.nft
  run_logged nft --file /run/nm-wg.nft
}

uplink_interface() {
  ip -4 route show table main default \
    | awk '{ for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit } }'
}

reverse_path_drop_count() {
  awk '/^TcpExt:/ {
      if (!header_seen) {
        split($0, names)
        header_seen = 1
        next
      }
      split($0, values)
      for (i = 2; i in names; i++) {
        if (names[i] == "IPReversePathFilter") {
          print values[i]
        }
      }
    }' /proc/net/netstat
}

effective_rp_filter() {
  local all_value
  local interface_value
  all_value=$(sysctl -n net.ipv4.conf.all.rp_filter)
  interface_value=$(sysctl -n "net.ipv4.conf.$uplink_interface_name.rp_filter")
  if ((all_value > interface_value)); then
    printf '%s\n' "$all_value"
  else
    printf '%s\n' "$interface_value"
  fi
}

show_reverse_path_state() {
  sysctl net.ipv4.conf.all.rp_filter net.ipv4.conf.default.rp_filter \
    "net.ipv4.conf.$uplink_interface_name.rp_filter" \
    net.ipv4.conf.all.src_valid_mark
  printf 'rp_filter_effective=%s\n' "$(effective_rp_filter)"
  printf 'IPReversePathFilter=%s\n' "$(reverse_path_drop_count)"
}

show_routes() {
  local endpoint_ipv4
  local endpoint_ipv6
  endpoint_ipv4=$(endpoint_address "$(select_endpoint ipv4)")
  endpoint_ipv6=$(endpoint_address "$(select_endpoint ipv6)")
  run_logged ip -brief address show
  run_logged ip -4 rule show
  run_logged ip -6 rule show
  run_logged ip -4 route show table main
  run_logged ip -6 route show table main
  run_logged ip -4 route show table "$routing_mark"
  run_logged ip -6 route show table "$routing_mark"
  run_logged ip -4 route get 1.1.1.1
  run_logged ip -6 route get 2606:4700:4700::1111
  run_logged ip -4 route get "$endpoint_ipv4" mark "$routing_mark"
  run_logged ip -4 route get "$endpoint_ipv4"
  run_logged ip -6 route get "$endpoint_ipv6" mark "$routing_mark"
  run_logged nft list ruleset
}

configure_resolver() {
  if [[ $resolver_mode == strict_dot ]]; then
    run_logged ln --symbolic --force --no-dereference \
      ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    run_logged systemctl restart systemd-resolved.service
    resolver_service_state=$(systemctl is-active systemd-resolved.service)
    run_logged cat /etc/systemd/resolved.conf.d/90-dotfiles-dns.conf
    run_logged resolvectl status
  else
    run_logged systemctl stop systemd-resolved.service
    resolver_service_state=stopped_by_mode
    run_logged rm --force /etc/resolv.conf
    read_value Interface DNS | split_list | sed 's/^/nameserver /' \
      > /etc/resolv.conf
  fi
  run_logged ls -l /etc/resolv.conf
  run_logged cat /etc/resolv.conf
  run_logged grep -E '^hosts:' /etc/nsswitch.conf
  printf 'resolver_service=%s\n' "$resolver_service_state"
}

show_tunnel_state() {
  wg show "$interface_name" \
    | sed -E 's/^([[:space:]]*public key: ).*/\1<redacted>/'
}

measure_tunnel() {
  local handshake_epoch
  run_logged ping -c 3 -W 2 "$(first_vpn_resolver)"
  run_logged show_tunnel_state
  handshake_epoch=$(wg show "$interface_name" latest-handshakes \
    | awk '{ print $2 }')
  printf 'latest_handshake_epoch=%s\n' "${handshake_epoch:-0}"
  if [[ ${handshake_epoch:-0} != 0 ]]; then
    handshake_state=yes
  fi
}

trace_egress() {
  curl -sS --max-time 15 "$1" | grep -E '^(ip|colo|loc|tls)='
}

measure_egress() {
  local trace
  local address
  local attempt
  egress_attempts=1
  if [[ $handshake_state == yes ]]; then
    egress_attempts=5
  fi
  for ((attempt = 1; attempt <= egress_attempts; attempt++)); do
    printf 'attempt %d of %d\n' "$attempt" "$egress_attempts"
    trace=$(run_logged trace_egress https://1.1.1.1/cdn-cgi/trace)
    printf '%s\n' "$trace"
    address=$(printf '%s\n' "$trace" | sed -n 's/^ip=//p')
    if [[ -n $address ]]; then
      egress_address=$address
      egress_successes=$((egress_successes + 1))
    fi
  done
  run_logged trace_egress 'https://[2606:4700:4700::1111]/cdn-cgi/trace'
}

probe_dns_over_tls() {
  timeout 20 openssl s_client -connect "$1" -servername cloudflare-dns.com \
    -verify_hostname cloudflare-dns.com -verify_return_error -brief < /dev/null
}

measure_dns_over_tls() {
  if run_logged probe_dns_over_tls 1.1.1.1:853; then
    dns_over_tls_state=ok
  fi
  run_logged probe_dns_over_tls '[2606:4700:4700::1111]:853'
}

measure_lookup() {
  local name=$1
  local start_time
  local end_time
  local first_address
  local exit_status=0
  start_time=$(date +%s.%N)
  first_address=$(timeout 30 getent ahosts "$name" \
    | awk 'NR == 1 { print $1 }') || exit_status=$?
  end_time=$(date +%s.%N)
  if ((exit_status == 0)) && [[ -n $first_address ]]; then
    lookup_resolved_count=$((lookup_resolved_count + 1))
  fi
  awk -v name="$name" -v status="$exit_status" -v start="$start_time" \
    -v end="$end_time" -v address="${first_address:-none}" \
    'BEGIN {
      printf "%-24s exit=%-3s seconds=%6.2f first_address=%s\n",
        name, status, end - start, address
    }'
}

write_qbittorrent_config() {
  local config_dir=$qbittorrent_home/.config/qBittorrent
  mkdir --parents "$config_dir" "$qbittorrent_home/downloads"
  cat > "$config_dir/qBittorrent.conf" << EOF
[LegalNotice]
Accepted=true

[BitTorrent]
Session\\Interface=$interface_name
Session\\InterfaceName=$interface_name
Session\\Port=51820
Session\\QueueingSystemEnabled=false
Session\\DefaultSavePath=$qbittorrent_home/downloads
Session\\GlobalDLSpeedLimit=2048
Session\\GlobalUPSpeedLimit=256

[Network]
PortForwardingEnabled=false

[Preferences]
WebUI\\Address=127.0.0.1
WebUI\\Port=8080
WebUI\\LocalHostAuth=false
EOF
  chown --recursive qbt:qbt "$qbittorrent_home"
}

start_qbittorrent() {
  local deadline=$((SECONDS + 30))
  runuser -u qbt -- env HOME="$qbittorrent_home" \
    qbittorrent-nox --confirm-legal-notice > /run/qbittorrent-nox.out 2>&1 &
  while ((SECONDS < deadline)); do
    if curl -sS --max-time 2 "$webui_base/app/version" > /dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

api_get() {
  curl -sS --max-time 10 "$webui_base/$1"
}

api_post() {
  local endpoint=$1
  shift
  curl -sS --max-time 30 "$@" "$webui_base/$endpoint"
}

measure_qbittorrent() {
  local torrent_hash
  local transfer_json
  local trackers_json
  local log_json
  write_qbittorrent_config
  if ! run_logged start_qbittorrent; then
    run_logged cat /run/qbittorrent-nox.out
    return
  fi
  run_logged api_get app/version
  run_logged api_post torrents/add --form "torrents=@$torrent_file"
  sleep 3
  torrent_hash=$(api_get torrents/info | jq -r '.[0].hash // empty')
  printf 'torrent_hash=%s\n' "$torrent_hash"
  run_logged api_post torrents/addTrackers \
    --data-urlencode "hash=$torrent_hash" \
    --data-urlencode "urls=$(printf '%s\n' "${magnet_trackers[@]}")"
  run_logged api_post torrents/reannounce --data-urlencode "hashes=$torrent_hash"
  printf 'waiting %s seconds\n' "$qbittorrent_seconds"
  sleep "$qbittorrent_seconds"
  transfer_json=$(api_get transfer/info)
  trackers_json=$(api_get "torrents/trackers?hash=$torrent_hash")
  log_json=$(api_get 'log/main?normal=true&info=true&warning=true&critical=true')
  printf '%s\n' "$transfer_json" \
    | jq '{connection_status, dht_nodes, dl_info_data, up_info_data}'
  api_get torrents/info \
    | jq '.[] | {name, state, num_seeds, num_leechs, downloaded, progress}'
  printf '%s\n' "$trackers_json" | jq -c '.[] | {url, status, num_peers, msg}'
  printf '%s\n' "$log_json" | jq -r '.[] | "\(.type) \(.message)"'
  qbittorrent_connection_status=$(jq -r '.connection_status' <<< "$transfer_json")
  qbittorrent_dht_nodes=$(jq -r '.dht_nodes' <<< "$transfer_json")
  qbittorrent_downloaded_bytes=$(jq -r '.dl_info_data' <<< "$transfer_json")
  qbittorrent_trackers_total=$(jq \
    '[.[] | select(.url | startswith("** [") | not)] | length' \
    <<< "$trackers_json")
  qbittorrent_trackers_working=$(jq \
    '[.[] | select((.url | startswith("** [") | not) and .status == 2)]
      | length' <<< "$trackers_json")
  qbittorrent_geolocation=$(jq -r \
    '[.[] | select(.message | test("geolocation"; "i")) | .message]
      | last // "none"' <<< "$log_json")
  run_logged api_post app/shutdown --data ''
}

print_summary() {
  print_section summary
  printf 'summary.cell=%s_%s\n' "$endpoint_family" "$resolver_mode"
  printf 'summary.endpoint=%s\n' "$selected_endpoint"
  printf 'summary.resolver_service=%s\n' "$resolver_service_state"
  printf 'summary.reverse_path=rp_filter_effective=%s src_valid_mark=%s\n' \
    "$(effective_rp_filter)" "$(sysctl -n net.ipv4.conf.all.src_valid_mark)"
  printf 'summary.reverse_path_drops=%s\n' \
    "$(($(reverse_path_drop_count) - reverse_path_drops_before))"
  printf 'summary.handshake=%s\n' "$handshake_state"
  printf 'summary.egress_ipv4=%s\n' "$egress_address"
  printf 'summary.egress_ipv4_successes=%s/%s\n' "$egress_successes" \
    "$egress_attempts"
  printf 'summary.dns_over_tls_ipv4=%s\n' "$dns_over_tls_state"
  printf 'summary.lookups_resolved=%s/%s\n' "$lookup_resolved_count" \
    "${#lookup_names[@]}"
  printf 'summary.qbittorrent_connection_status=%s\n' \
    "${qbittorrent_connection_status:-none}"
  printf 'summary.qbittorrent_dht_nodes=%s\n' "${qbittorrent_dht_nodes:-0}"
  printf 'summary.qbittorrent_trackers_working=%s/%s\n' \
    "${qbittorrent_trackers_working:-0}" "${qbittorrent_trackers_total:-0}"
  printf 'summary.qbittorrent_downloaded_bytes=%s\n' \
    "${qbittorrent_downloaded_bytes:-0}"
  printf 'summary.qbittorrent_geolocation=%s\n' \
    "${qbittorrent_geolocation:-none}"
}

main() {
  local name
  print_section cell
  printf 'endpoint_family=%s resolver_mode=%s qbittorrent_seconds=%s\n' \
    "$endpoint_family" "$resolver_mode" "$qbittorrent_seconds"
  date --iso-8601=seconds
  print_section versions
  run_logged rpm -q systemd systemd-resolved wireguard-tools qbittorrent-nox \
    openssl
  run_logged sha256sum /etc/systemd/resolved.conf.d/90-dotfiles-dns.conf
  selected_endpoint=$(select_endpoint "$endpoint_family")
  printf 'selected_endpoint=%s\n' "$selected_endpoint"
  write_setconf_file "$selected_endpoint"
  print_section 'tunnel setup'
  create_tunnel
  apply_networkmanager_rules
  uplink_interface_name=$(uplink_interface)
  print_section routes
  show_routes
  print_section 'resolver mode'
  configure_resolver
  print_section 'reverse path before traffic'
  reverse_path_drops_before=$(reverse_path_drop_count)
  show_reverse_path_state
  print_section 'tunnel liveness'
  measure_tunnel
  print_section 'egress by address'
  measure_egress
  print_section 'DNS over TLS reachability'
  measure_dns_over_tls
  print_section 'VPN resolver without TLS'
  run_logged dig +time=3 +tries=1 +short "@$(first_vpn_resolver)" \
    tracker.opentrackr.org A
  print_section 'system resolver lookups'
  for name in "${lookup_names[@]}"; do
    measure_lookup "$name"
  done
  if [[ $resolver_mode == strict_dot ]]; then
    print_section 'resolver statistics'
    run_logged resolvectl query --cache=no tracker.opentrackr.org
    run_logged resolvectl statistics
    run_logged journalctl --unit systemd-resolved.service --no-pager \
      --lines 20
  fi
  print_section qbittorrent
  measure_qbittorrent
  print_section 'tunnel counters'
  run_logged wg show "$interface_name" transfer
  print_section 'reverse path after traffic'
  show_reverse_path_state
  print_summary
}

main
