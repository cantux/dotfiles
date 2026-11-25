#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly script_dir
dns_dir=$(dirname "$script_dir")
readonly dns_dir
readonly image_name=localhost/dotfiles-dns-vpn-test:latest
readonly wireguard_source=${WIREGUARD_SOURCE:-$HOME/Downloads/wg-US-CA-515.conf}
readonly connection_name=wg-US-CA-515
readonly control_torrent_index=https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/
readonly qbittorrent_seconds=${QBITTORRENT_SECONDS:-75}
readonly all_cells=(ipv6_strict_dot ipv4_strict_dot ipv4_vpn_dns ipv6_vpn_dns)

secret_dir=
input_dir=

run_logged() {
  printf '$ %s\n' "$*"
  local exit_status=0
  "$@" 2>&1 || exit_status=$?
  printf '[exit %d]\n' "$exit_status"
}

remove_run_state() {
  local cell
  for cell in "${all_cells[@]}"; do
    podman rm --force --ignore "dns-vpn-$cell" > /dev/null 2>&1 || true
  done
  if [[ -n $secret_dir ]]; then
    rm --recursive --force "$secret_dir"
  fi
  if [[ -n $input_dir ]]; then
    rm --recursive --force "$input_dir"
  fi
}

source_endpoints() {
  sed -n 's/^[[:space:]]*Endpoint[[:space:]]*=[[:space:]]*//p' \
    "$wireguard_source"
}

route_to_endpoint() {
  local endpoint=$1
  local address
  if [[ $endpoint == \[* ]]; then
    address=${endpoint#\[}
    address=${address%%\]*}
    ip -6 route get "$address"
  else
    address=${endpoint%:*}
    ip -4 route get "$address"
  fi
}

record_host_context() {
  local endpoint
  date --iso-8601=seconds
  run_logged nmcli -t -f NAME,TYPE,DEVICE connection show --active
  run_logged nmcli -f wireguard.peers connection show "$connection_name"
  while IFS= read -r endpoint; do
    run_logged route_to_endpoint "$endpoint"
  done < <(source_endpoints)
  run_logged sha256sum /etc/systemd/resolved.conf.d/90-dotfiles-dns.conf \
    "$dns_dir/resolved.conf"
  run_logged resolvectl status
}

fetch_control_torrent() {
  local torrent_name
  torrent_name=$(curl -fsS --max-time 30 "$control_torrent_index" \
    | grep -o -E 'debian-[0-9.]+-amd64-netinst\.iso\.torrent' \
    | sort -u -V | tail -n 1)
  curl -fsS --max-time 60 --output "$input_dir/control.torrent" \
    "$control_torrent_index$torrent_name"
  printf 'control_torrent=%s\n' "$torrent_name"
}

wait_for_boot() {
  local container_name=$1
  local deadline=$((SECONDS + 90))
  local state
  while ((SECONDS < deadline)); do
    state=$(podman exec "$container_name" systemctl is-system-running \
      2> /dev/null || true)
    if [[ $state == running || $state == degraded ]]; then
      return 0
    fi
    sleep 1
  done
  return 1
}

run_cell() {
  local cell=$1
  local evidence_dir=$2
  local endpoint_family=${cell%%_*}
  local resolver_mode=${cell#*_}
  local container_name=dns-vpn-$cell
  podman rm --force --ignore "$container_name" > /dev/null
  podman run --detach --name "$container_name" --hostname dns-vpn-test \
    --cap-add NET_ADMIN --cap-add NET_RAW --cap-add SYS_ADMIN \
    --sysctl net.ipv4.conf.all.rp_filter=2 \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --dns none \
    --volume "$secret_dir:/mnt/vpn-secret:ro,Z" \
    --volume "$input_dir:/mnt/vpn-input:ro,Z" \
    "$image_name" > /dev/null
  if ! wait_for_boot "$container_name"; then
    printf 'cell %s: systemd did not finish booting\n' "$cell" >&2
  fi
  podman exec "$container_name" /usr/local/bin/cell_probe.sh \
    "$endpoint_family" "$resolver_mode" "$qbittorrent_seconds" \
    > "$evidence_dir/$cell.txt" 2>&1 || true
  podman rm --force "$container_name" > /dev/null
}

is_known_cell() {
  local candidate=$1
  local cell
  for cell in "${all_cells[@]}"; do
    if [[ $cell == "$candidate" ]]; then
      return 0
    fi
  done
  return 1
}

main() {
  local cells=("$@")
  local cell
  local evidence_dir
  if ((${#cells[@]} == 0)); then
    cells=("${all_cells[@]}")
  fi
  for cell in "${cells[@]}"; do
    if ! is_known_cell "$cell"; then
      printf 'unknown cell %s; known cells: %s\n' "$cell" "${all_cells[*]}" >&2
      exit 2
    fi
  done
  if [[ ! -r $wireguard_source ]]; then
    printf 'cannot read %s\n' "$wireguard_source" >&2
    exit 2
  fi
  evidence_dir=$script_dir/evidence/$(date +%Y%m%dT%H%M%S)
  mkdir --parents "$evidence_dir"
  trap remove_run_state EXIT
  secret_dir=$(mktemp --directory "${XDG_RUNTIME_DIR:-/tmp}/dns-vpn-secret.XXXXXX")
  input_dir=$(mktemp --directory "${XDG_RUNTIME_DIR:-/tmp}/dns-vpn-input.XXXXXX")
  install --mode 600 "$wireguard_source" "$secret_dir/source.conf"
  podman build --quiet --tag "$image_name" \
    --file "$script_dir/Containerfile" "$dns_dir" > /dev/null
  fetch_control_torrent > "$evidence_dir/control_torrent.txt"
  record_host_context > "$evidence_dir/host_context.txt" 2>&1
  for cell in "${cells[@]}"; do
    printf 'cell %s: running\n' "$cell"
    run_cell "$cell" "$evidence_dir"
    grep '^summary\.' "$evidence_dir/$cell.txt" || true
  done
  printf 'evidence: %s\n' "$evidence_dir"
}

main "$@"
