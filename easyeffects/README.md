# EasyEffects equalizer for the Dell S3225QC

A parametric equalizer for the Dell S3225QC monitor speakers, applied system-wide
through EasyEffects 8 on PipeWire. The preset loads automatically whenever audio
routes to the monitor over DisplayPort.

Apply on a fresh machine:

1. `flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`
2. `flatpak install --user -y flathub com.github.wwmm.easyeffects`
3. `cd ~/Projects/dotfiles && ./sync.sh`
4. Log out and in, or start the service once: `flatpak run com.github.wwmm.easyeffects --service-mode --hide-window &`

Verify: `flatpak run com.github.wwmm.easyeffects -a output` prints `dell-s3225qc`.

See INSTR.md for tuning and debugging, ARCH.md for the signal path and the
reasoning behind each band.
