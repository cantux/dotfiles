# INSTR

## Install

1. `flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`
2. `flatpak install --user -y flathub com.github.wwmm.easyeffects`

Rationale for Flatpak: EasyEffects exists in no enabled dnf repository
(BaseOS, AppStream, CRB, EPEL 10, vendor repos) and not in snap; Flathub is the
only packaged channel on CentOS Stream 10.

## Apply

1. `cd ~/Projects/dotfiles && ./sync.sh`
2. Start the service: `flatpak run com.github.wwmm.easyeffects --service-mode --hide-window &`
   (the autostart entry does this at every login).

## Verify

1. `flatpak run com.github.wwmm.easyeffects -p` lists `dell-s3225qc`.
2. `flatpak run com.github.wwmm.easyeffects -a output` prints `dell-s3225qc`.
3. `pw-link -l | grep -A1 'ee_soe_output_level:output'` shows links into
   `…HiFi__HDMI1__sink:playback_FL/FR`.
4. Play audio; `wpctl status` shows the stream attached to `easyeffects_sink`.

## Tune

1. Edit `.var/app/…/data/easyeffects/output/dell-s3225qc.json` in the
   repository. Edit `left` and `right` identically while `split-channels` is
   false.
2. `./sync.sh`
3. Reload: `flatpak run com.github.wwmm.easyeffects -l dell-s3225qc`
4. Judge bands with a sine sweep (e.g. a 20 Hz–20 kHz logarithmic sweep file)
   and program material with known voicing.
5. Keep `input-gain` ≤ −(largest positive band gain).
6. On the monitor OSD, set the audio profile to `Standard` and disable 3D
   spatial audio for a stable baseline.

## Debug

1. Service log: run in a terminal with `--debug`:
   `flatpak run com.github.wwmm.easyeffects --service-mode --debug`
2. `Old … directory detected` in the log means files landed under
   `config/easyeffects/`; move them to `data/easyeffects/` (see ARCH.md
   invariant 2).
3. Autoload not firing: compare the autoload file's `device` and
   `device-profile` fields against `wpctl inspect <sink-id>` (node.name) and
   `pw-dump <device-id>` (active `Route` name).
4. GUI inspection: `flatpak run com.github.wwmm.easyeffects` opens the window
   against the running service.
