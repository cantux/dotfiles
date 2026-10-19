# MAP

Root of this work: `~/Projects/dotfiles` (branch `centos`). This directory
(`easyeffects/`) holds the documentation; the configuration lives at the paths
`sync.sh` mirrors into `$HOME`.

## Components

| Path (repo-relative) | Role |
|---|---|
| `.var/app/com.github.wwmm.easyeffects/data/easyeffects/output/dell-s3225qc.json` | The equalizer preset: one `equalizer#0` plugin, five bands, −2.5 dB input gain. |
| `.var/app/com.github.wwmm.easyeffects/data/easyeffects/autoload/output/alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__HDMI1__sink:[Out] HDMI1.json` | Autoload rule: binds the preset to the HDMI/DP-1 sink of the sof-soundwire card (the route that carries audio to the S3225QC). |
| `.config/autostart/easyeffects-service.desktop` | Starts the EasyEffects service at desktop login. |
| `sync.sh` (items list) | Tracks the three paths above; `./sync.sh` applies repo → `$HOME`. |
| `easyeffects/README.md` | Entry point: what this is, how to apply. |
| `easyeffects/ARCH.md` | Signal path, autoload matching, band rationale, invariants. |
| `easyeffects/INSTR.md` | Install, apply, verify, tune, debug commands. |
| `easyeffects/WORKLOG.md` | Chronological record of the setup. |
| `easyeffects/EVIDENCE_INSPIRATION_REFERENCE.md` | Sources for every design decision. |

## Live locations in `$HOME` (produced by sync.sh)

1. `~/.var/app/com.github.wwmm.easyeffects/data/easyeffects/output/dell-s3225qc.json`
2. `~/.var/app/com.github.wwmm.easyeffects/data/easyeffects/autoload/output/…:[Out] HDMI1.json`
3. `~/.config/autostart/easyeffects-service.desktop`

`~/.var/app/com.github.wwmm.easyeffects/config/easyeffects/db/` is EasyEffects 8
runtime state. It stays untracked.
