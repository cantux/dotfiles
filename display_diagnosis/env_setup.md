# GRUB / NVIDIA / Kernel 214 Fix Log

## Problem
5 GRUB entries (3 kernels + rescue + variants). Only kernel `6.12.0-201` worked.
Kernels `6.12.0-184` and `6.12.0-214` had no display and no network on boot.

---

## Diagnosis Steps

1. Checked current kernel and boot cmdline (`uname -r`, `/proc/cmdline`)
2. Listed available kernels and initramfs images under `/boot/`
3. Inspected `/etc/default/grub` — confirmed `GRUB_ENABLE_BLSCFG=true` (BLS mode)
4. Checked DKMS status — nvidia `595.45.04` built only for `201` and `214`, not `184`
5. Confirmed `rd.driver.blacklist=nouveau rd.driver.blacklist=nova-core` present in `201`'s cmdline but not in other entries
6. Checked `/etc/modprobe.d/blacklist-nouveau.conf` — blacklist applies post-initrd only
7. Verified `r8152` USB ethernet driver missing entirely from `214`'s module tree
8. Compared installed kernel RPMs — `214` was missing `kernel`, `kernel-modules`, and `kernel-modules-extra`

---

## Root Causes

| Kernel | Issue | Cause |
|--------|-------|-------|
| `6.12.0-184` | No display, no nvidia | DKMS never built for this kernel; modules absent |
| `6.12.0-214` | No external display | `rd.driver.blacklist=nouveau/nova-core` missing from BLS entry → nouveau loaded first, conflicted with proprietary nvidia |
| `6.12.0-214` | No network (USB ethernet) | `kernel-modules-6.12.0-214` not installed → entire `drivers/net/usb/` tree missing → no `r8152` driver for Realtek RTL8153B adapter |

**Why 214 was incomplete:** It was installed via `kernel-devel-matched` (needed for DKMS builds), which only pulls in `kernel-core`, `kernel-devel`, and `kernel-modules-core` — not the full `kernel` + `kernel-modules` + `kernel-modules-extra`.

---

## Fixes Applied

### 1. Add nouveau blacklist to all kernel cmdlines
```bash
sudo grubby --update-kernel=ALL \
  --args="rd.driver.blacklist=nouveau rd.driver.blacklist=nova-core"
```

### 2. Install missing kernel packages for 214
```bash
sudo dnf install kernel-6.12.0-214.el10.x86_64 \
                 kernel-modules-6.12.0-214.el10.x86_64 \
                 kernel-modules-extra-6.12.0-214.el10.x86_64
```

### 3. Rebuild initramfs for 214
```bash
sudo dracut --force --kver 6.12.0-214.el10.x86_64
```

### 4. (If needed) Build DKMS nvidia for kernel 184
```bash
sudo dkms install nvidia/595.45.04 -k 6.12.0-184.el10.x86_64
```

---

## System Info

- **Machine:** Dell laptop, hybrid graphics (Intel UHD CometLake-H + NVIDIA RTX 2060 Max-Q)
- **OS:** RHEL/CentOS Stream 10
- **NVIDIA driver:** `595.45.04` via `kmod-nvidia-open-dkms`
- **USB ethernet:** Realtek RTL8153B (`r8152` driver), interface `enp167s0u2u4`
- **WiFi:** Intel Comet Lake PCH CNVi (`iwlwifi`/`iwlmvm`)
