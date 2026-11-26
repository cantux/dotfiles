#!/usr/bin/env bash
set -euo pipefail

readonly APP_ID="com.heroicgameslauncher.hgl"
readonly HEROIC_DIR="${HOME}/.var/app/${APP_ID}/config/heroic"
readonly GAME_DIR="${HOME}/Games/Heroic/HoMM 3 Complete"
readonly PREFIX_DIR="${HOME}/Games/Heroic/Prefixes/Heroes of Might and Magic 3 Complete"
readonly PROTON_DIR="${HEROIC_DIR}/tools/proton/Proton-CachyOS-latest"
readonly UMU_RUN="${HEROIC_DIR}/tools/runtimes/umu/umu_run.py"
readonly DOWNLOAD_DIR="${HOME}/Downloads/hd_mod"
readonly INSTALLER_URL="https://heroes3hd.com/HoMM3_HD_Latest_setup.exe"
readonly INSTALLER_PATH="${DOWNLOAD_DIR}/HoMM3_HD_Latest_setup.exe"
readonly VERIFIED_INSTALLER_PATH="${DOWNLOAD_DIR}/HoMM3_HD_Latest_setup_verified.exe"
readonly WINDOWS_GAME_DIR="Z:${GAME_DIR//\//\\}"
readonly INSTALL_LOG="${PREFIX_DIR}/drive_c/hd_mod_install.log"
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly SCRIPT_DIR
readonly REPAIR_TOOL="${SCRIPT_DIR}/repair_inno_offsets.py"

main() {
  if [[ ! -f "${GAME_DIR}/Heroes3.exe" ]]; then
    echo "missing: ${GAME_DIR}/Heroes3.exe" >&2
    return 1
  fi
  mkdir -p "${DOWNLOAD_DIR}" "${PREFIX_DIR}"
  if [[ ! -f "${INSTALLER_PATH}" ]]; then
    curl -fsSL -o "${INSTALLER_PATH}" "${INSTALLER_URL}"
  fi
  sha256sum "${INSTALLER_PATH}"
  python3 -I "${REPAIR_TOOL}" "${INSTALLER_PATH}" "${VERIFIED_INSTALLER_PATH}"

  flatpak run \
    --filesystem=xdg-download/hd_mod:ro \
    --env=WINEPREFIX="${PREFIX_DIR}" \
    --env=STEAM_COMPAT_DATA_PATH="${PREFIX_DIR}" \
    --env=STEAM_COMPAT_INSTALL_PATH="${GAME_DIR}" \
    --env=STEAM_COMPAT_CLIENT_INSTALL_PATH="${HOME}/.var/app/${APP_ID}/.steam/steam" \
    --env=PROTONPATH="${PROTON_DIR}" \
    --env=GAMEID=umu-0 \
    --env=STORE=gog \
    --command="${UMU_RUN}" \
    "${APP_ID}" \
    "${VERIFIED_INSTALLER_PATH}" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- \
    "/DIR=${WINDOWS_GAME_DIR}" '/LOG=C:\hd_mod_install.log'

  grep -E 'Installation process succeeded|Exit code|Fatal' "${INSTALL_LOG}"
  ls -l "${GAME_DIR}/HD_Launcher.exe"
}

main "$@"
