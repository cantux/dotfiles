# WORKLOG

2026-10-09

1. Identified the audio stack: PipeWire 1.4.11 + WirePlumber 0.5.10 with
   `pipewire-pulseaudio`; no PulseAudio daemon. Decision: install EasyEffects
   (the PipeWire successor of PulseEffects) instead of PulseEffects.
2. Identified the target device: EDID of `card1-DP-1` decodes to
   `DELL S3225QC` (manufacturer `DEL`, product `0xd1b5`). The audio path is the
   sof-soundwire card's `HiFi: HDMI1: sink` PCM, route `[Out] HDMI1`.
3. Checked packaging channels: no `easyeffects`/`pulseeffects` in BaseOS,
   AppStream, CRB, EPEL 10, vendor repos, or snap. Decision: Flathub, user
   scope. Added the Flathub remote and installed
   `com.github.wwmm.easyeffects` 8.3.0.
4. Searched for a measured EQ profile for the S3225QC speakers (AutoEq covers
   headphones; monitor reviews publish no speaker frequency response).
   Outcome: none exists. Decision: conservative five-band correction derived
   from Dell's rated 100 Hz–20 kHz response and small-loudspeaker practice
   (bands in ARCH.md).
5. Authored `dell-s3225qc.json` (preset) and the autoload rule keyed to
   `alsa_output…HiFi__HDMI1__sink` + `[Out] HDMI1`, plus a login autostart
   entry for the service. Placed all three in the dotfiles repository and
   registered them in `sync.sh`.
6. First service start revealed EasyEffects 8 reads presets from
   `data/easyeffects/`, not `config/easyeffects/`: the service migrated the
   files and trashed the data directory copies. Corrected the repository
   layout and `sync.sh` items to the `data/` paths; removed the leftover
   empty `config/easyeffects/autoload` directory (kept `config/easyeffects/db`,
   which is EasyEffects 8 runtime state).
7. Verified end to end after a clean service restart: `-p` lists the preset;
   `-a output` reports `dell-s3225qc` with no manual load (autoload works);
   zero migration messages; `pw-link -l` shows
   stream → easyeffects_sink → ee_soe_equalizer → spectrum → output level →
   HDMI1 sink.
8. Drift check before applying: only `.claude/settings.json` differed
   (repo `"model": "fable"` vs home `"claude-fable-5"`, the CLI rewrote the
   home copy; same model). The permission classifier denied editing that file
   (self-modification), so the three new items were applied selectively with
   the same rsync/cp semantics `sync.sh` uses; the settings drift remains for
   the user to resolve.
9. Left the repository uncommitted; `git status` shows the new files and the
   `sync.sh` edit on branch `centos`.
