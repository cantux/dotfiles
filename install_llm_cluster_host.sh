#!/usr/bin/env bash
set -euo pipefail

KUBECTL_VERSION=v1.36.5
KUBECTL_SHA256=33bc88a24c3b09cf55bfd59e6ca977881b61fc3f25ab65bc80c65b430248648e
CILIUM_CLI_VERSION=v0.20.1
CILIUM_CLI_SHA256=24e817dcfcc8a12e325ce7547617bcbcf171c5b0b335bb24d2bb1207ba047f61
HUBBLE_VERSION=v1.20.2
HUBBLE_SHA256=03f248a50cad11e728bf9383382392c57148fd6a19853ad359fb7598dae29312
POOL_DIR=/home/mls-pool
KERNEL_ARGS="intel_iommu=on iommu=pt"
TARGET_USER=${SUDO_USER:-$USER}
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
BIN_DIR=$TARGET_HOME/.local/bin

if [ "${1:-}" = "--undo" ]; then
  sudo grubby --update-kernel=ALL --remove-args="$KERNEL_ARGS"
  sudo systemctl disable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket || true
  sudo gpasswd -d "$TARGET_USER" libvirt || true
  rm -f "$BIN_DIR/kubectl" "$BIN_DIR/cilium" "$BIN_DIR/hubble"
  echo "Undone. Reboot to drop the IOMMU kernel arguments. $POOL_DIR is kept; remove it after provisioning/down.sh."
  exit 0
fi

sudo dnf install -y libvirt-daemon-kvm libvirt-daemon-config-network virt-install qemu-img policycoreutils-python-utils
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket virtnodedevd.socket
sudo usermod -aG libvirt "$TARGET_USER"

sudo mkdir -p "$POOL_DIR"
sudo semanage fcontext -a -t virt_image_t "$POOL_DIR(/.*)?" 2>/dev/null || sudo semanage fcontext -m -t virt_image_t "$POOL_DIR(/.*)?"
sudo restorecon -R "$POOL_DIR"

sudo grubby --update-kernel=ALL --args="$KERNEL_ARGS"

sudo dnf config-manager --add-repo https://developer.download.nvidia.com/devtools/repos/rhel10/x86_64/ || true
sudo dnf install -y nsight-systems-cli

if command -v kubeadm >/dev/null; then
  sudo kubeadm reset -f || true
fi
sudo systemctl disable --now kubelet || true

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$BIN_DIR"
curl -fL -o "$work/kubectl" "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
echo "$KUBECTL_SHA256  $work/kubectl" | sha256sum -c -
curl -fL -o "$work/cilium.tgz" "https://github.com/cilium/cilium-cli/releases/download/$CILIUM_CLI_VERSION/cilium-linux-amd64.tar.gz"
echo "$CILIUM_CLI_SHA256  $work/cilium.tgz" | sha256sum -c -
curl -fL -o "$work/hubble.tgz" "https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-amd64.tar.gz"
echo "$HUBBLE_SHA256  $work/hubble.tgz" | sha256sum -c -
tar -xzf "$work/cilium.tgz" -C "$work"
tar -xzf "$work/hubble.tgz" -C "$work"
install -m 0755 -o "$TARGET_USER" "$work/kubectl" "$work/cilium" "$work/hubble" "$BIN_DIR/"

echo
echo "kubectl: $("$BIN_DIR/kubectl" version --client | head -1)"
echo "cilium:  $("$BIN_DIR/cilium" version --client 2>/dev/null | head -1)"
echo "hubble:  $("$BIN_DIR/hubble" version)"
echo "nsys:    $(nsys --version)"
echo "Kernel args now: $(sudo grubby --info=DEFAULT | grep ^args)"
echo "Next: log out and back in (libvirt group), then reboot (IOMMU)."
