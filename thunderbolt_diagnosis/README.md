# Thunderbolt / WD19TB dock diagnosis

Dell XPS 17 9700, CentOS Stream 10. Companion to `../display_diagnosis` — same
machine, same dock, different failure. Investigation of 2026-09-02.

**Trigger:** a tool reported that the device on the lower-left (southwest)
USB-C port was "not on Thunderbolt".

**Conclusion:** false negative. The dock was on Thunderbolt the whole time, at
full 40 Gb/s, and its firmware was already fully current.

## Hardware facts worth not re-deriving

- All four USB-C ports on the XPS 17 9700 are Thunderbolt 3. There is no
  non-TB USB-C port to accidentally land in.
- Two **discrete** Intel JHL7540 Titan Ridge 4C controllers, two ports each:
  - `00:1c.4` → `/sys/bus/thunderbolt/devices/domain0`
  - `00:1d.0` → `domain1`
  Comet Lake-H does *not* have CPU-integrated Thunderbolt; that starts with Ice
  Lake. Anything you read claiming otherwise for this machine is wrong.
- Host TB controller NVM is 56.00 on both. LVFS has no firmware for
  `THUNDERBOLT\VEN_00D4&DEV_098F` because Dell ships it inside the BIOS.
- ACPI `_PLD` is useless here: all four ports report
  `panel=top, horizontal=left, vertical=upper`. **Nothing in sysfs names the
  physical connector.** Map it empirically:
  ```sh
  for i in 0 1 2 3; do
    echo "port$i: $([ -d /sys/class/typec/port$i-partner ] && echo OCCUPIED || echo empty)"
  done
  ```
- There is no Dell Thunderbolt *driver* on Linux. The in-tree `thunderbolt`
  module is it. `boltd` runs at security level `user`.

## The false negative

Kernel log at dock connect:

```
typec-thunderbolt port0-partner.1: failed to create symlinks
typec-thunderbolt port0-partner.1: probe with driver typec-thunderbolt failed with error -17
```

`-17` is `-EEXIST`. The dock advertises SVID `0x8087` twice; the driver binds
the first and the second probe collides, leaving the alt-mode entry that is
actually *labelled* Thunderbolt3 stuck at `active=no`:

```
/sys/class/typec/port0-partner/port0-partner.0  svid=8087 desc=Thunderbolt3 active=no
/sys/class/typec/port0-partner/port0-partner.1  svid=8087                   active=yes
```

Any tool that answers "is this on Thunderbolt?" from the Type-C alt-mode state
reads that and says no. Cosmetic; nothing downstream is affected.

**Use these for ground truth instead:**

```sh
cat /sys/bus/thunderbolt/devices/*/device_name
cat /sys/bus/thunderbolt/devices/1-1/{rx_speed,rx_lanes,nvm_version}
boltctl list
lspci -tv | grep -A6 '1d\.0'
```

The dock is genuinely tunneling iff **its own** JHL7440 Titan Ridge DD bridge
enumerated — here `71:00.0 → 72:02.0 → 73:00.0 (xHCI)`. In USB-C fallback that
whole PCI subtree does not exist and there is no gigabit ethernet. That test is
decisive; the alt-mode flag is not.

The dock moves between controllers freely and works on both: it was
`thunderbolt 0-3` behind `00:1c.4`, and after a replug `thunderbolt 1-1` behind
`00:1d.0`.

## Cross-reference to ../display_diagnosis

Today's state confirms that investigation's known-good baseline, and adds one
data point to its open question 2 (is the dock's video path at fault?):

- `card1-DP-1` = DELL S3225QC, 3840x2160@60, `i915`, native connector, plugged
  **directly** into a laptop USB-C port. Matches the documented baseline.
- `card1-DP-10` = Acer PM161Q, 1920x1080@60, **through the dock** — an MST
  connector behind the WD19TB's VMM5331 hub (no `ddc`/`i2c-*` node, unlike
  DP-1). So **the dock's video path does work**; it carried a 1080p display
  fine. Whatever the original 4K-over-dock problem was, it is not "dock video
  is broken".
- 4K@60 on the S3225QC is a **hardware ceiling, not a misconfiguration**. The
  CML-H display engine is DP 1.4 HBR2 with no DSC: ~17.3 Gb/s usable vs
  ~25.7 Gb/s needed for 4K120. The panel is 120 Hz but only offers 4K@60 plus
  1440p/1080p@120 here. Do not chase this as a bug.

## Dock firmware

### fwupd alone cannot answer this

`fwupdmgr get-updates` says "No updates available" — that is **not** a clean
bill of health. The `dell_dock` plugin fails to enumerate the base EC:

```
failed to add device .../usb9/9-2/9-2.3/9-2.3.5:
  failed to add device using on dell_dock: can't read base dock type from EC
```

`9-2.3.5` is `413c:b06f`, the WD19 base EC. Only the Thunderbolt NVM gets
version-checked; EC, MST hub and package level stay invisible. Known upstream
issue: https://github.com/fwupd/fwupd/issues/10417

### Where to download

Product page →
<https://www.dell.com/support/product-details/en-us/product/dell-wd19tb-dock/drivers>
Driver ID **P16WW**, "Dell Dock WD19/WD22TB4 Firmware Update Utility".

01.01.15 (released 27 Jul 2026), covers WD19/WD22/HD22/WD25/SD25:

```
https://dl.dell.com/FOLDER14783854M/1/DellDockFirmwarePackage_WD19_WD22_HD22_WD25_SD25_01.01.15.bin
sha256  09cad77ebbd59a297a7cf1b5a843b27b176015c611f1705a80235c2bd93f384e
```

The same firmware is on LVFS as `DellDockFirmwareUpdateLinux_01.01.15.cab`
(published 2026-07-14) — verified identical component versions, different
packaging and signing, different byte size (compression only).

### The .bin is NOT a static binary

It is a Python wrapper. It unzips an embedded `.cab` plus
`dell-fwupdate-dock_*.snap` and **hard-requires snapd** — it installs `core22`
and `core24` from the Snap Store, installs the Dell snap with
`--devmode --dangerous`, and runs *its own bundled fwupd*. That private fwupd
is exactly how it gets past the broken system `dell_dock` plugin. Without
snapd it exits with `snap is not installed in this sytem` (sic).

Prereqs on this box — snapd is in EPEL, already enabled; SELinux is Permissive
so there is no extra policy work:

```sh
sudo dnf install -y snapd
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo snap wait system seed.loaded
```

### Running it

Strip to a bare dock first: unplug every dock peripheral and display, dock on
its own 180 W PSU, laptop on AC.

```sh
chmod +x DellDockFirmwarePackage_WD19_WD22_HD22_WD25_SD25_01.01.15.bin
sudo ./DellDockFirmwarePackage_WD19_WD22_HD22_WD25_SD25_01.01.15.bin get-devices
sudo ./DellDockFirmwarePackage_WD19_WD22_HD22_WD25_SD25_01.01.15.bin install --uninstall
```

`get-devices` is read-only and is usually the whole job. Only run `install` if
something is actually behind; the MST flash alone is a 6-minute write. After
installing: wait ~1 min, unplug/replug the Type-C cable, re-run `get-devices`.
`--uninstall` removes the devmode snap when it finishes.

Teardown if you do not want snapd resident (this box runs cilium):

```sh
sudo snap remove dell-fwupdate-dock core22 core24
sudo systemctl disable --now snapd.socket snapd.service
sudo dnf remove -y snapd
[ -L /snap ] && sudo rm /snap
```

### Reading the package without installing snapd

`./…bin extract` also requires snapd, but the payload is plain base64 inside
the script — decode it directly:

```python
from base64 import b64decode
import io, zipfile
out = io.BytesIO()
for line in open(BIN, 'rb'):
    if line.startswith(b'#\x01'):
        out.write(b64decode(line[2:-1]))
out.seek(0)
zipfile.ZipFile(out).extractall('dellpkg')
```

That yields the `.cab` and the `.snap`. Then
`fwupdmgr get-details <cab> --json` lists every component version offline, with
no root and no snapd — enough to decide whether an update is even needed.

### Versions as of 2026-09-02 — already fully current, nothing flashed

| Component | Package 01.01.15 | Dock |
|---|---|---|
| EC | 01.01.00.16 | 01.01.00.16 |
| Package level | 01.01.03.01 | 01.01.03.01 |
| RTS5413 USB3.1 Gen1 hub | 01.25 | 01.25 |
| RTS5487 USB3.1 Gen2 hub | 01.66 | 01.66 |
| Thunderbolt NVM (Titan Ridge) | 60.00 | 60.00 |
| VMM5331 MST | 05.07.08 | 05.07.08 |

Dock service tag `[REDACTED]`. BIOS was 1.39.0 (latest on LVFS) throughout.

Shortcut for next time: the two Realtek hub versions are readable **without**
any Dell tooling, straight from USB descriptors — if these match the package,
the rest almost certainly does too:

```sh
for d in /sys/bus/usb/devices/*; do
  [ -e "$d/idVendor" ] || continue
  printf '%s:%s bcdDevice=%s %s\n' "$(cat $d/idVendor)" "$(cat $d/idProduct)" \
    "$(cat $d/bcdDevice)" "$(cat $d/product 2>/dev/null)"
done | grep -iE '0bda:(5487|5413|0487|0413)|413c:b06'
```

## Loose ends (not dock firmware, not chased)

- Dock GbE was `NO-CARRIER` — no cable in it, nothing wrong.
- The S3225QC's built-in USB hub does not enumerate on any bus. It supplies DP
  and 90 W PD but no USB at all. Suspect the monitor's OSD USB-upstream source
  assignment, or a display-only cable.
- **The dock NIC renames itself by PCI path**: `enp61s0u2u4` on controller 0
  (`00:1c.4`), `enp115s0u2u4` on controller 1 (`00:1d.0`). Moving the dock
  between ports renames the interface. Pin it with a systemd `.link` matching
  MAC `[REDACTED]` — this box runs cilium, so anything keyed on the
  interface name breaks silently when the dock moves.

## tbt_diag.sh

`./tbt_diag.sh <label>` snapshots everything above to
`tbt_diag_logs/<label>_<timestamp>.log` so runs are diffable — TB routers and
link speed, boltctl, the typec alt-mode state (including the known false
negative), PCI topology, USB tree, DRM connectors, dock net/audio, the fwupd
view including the expected `dell_dock` failure, and the relevant journal
lines. Ends with a manual Y/N block; fill it in by hand.

Label by physical port when that is the variable, e.g.
`./tbt_diag.sh dock_SW` then `./tbt_diag.sh dock_NW`.
