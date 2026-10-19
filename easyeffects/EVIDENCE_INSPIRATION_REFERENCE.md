# EVIDENCE, INSPIRATION, REFERENCE

## Primary procedure

1. Yalneb, "PulseEffects + AutoEq" (2019) — the followed post: take parametric
   filters (frequency, Q, gain per band, plus pre-amp headroom) and enter them
   into the PulseEffects equalizer.
   https://yalneb.blogspot.com/2019/04/pulseeffects-autoeq.html
   Adaptation here: PulseEffects targets PulseAudio and is superseded; this
   system runs PipeWire, so the same procedure applies through EasyEffects
   (same author, W. Vieira; same LSP equalizer plugin), and the bands go into a
   preset file instead of the GUI.
2. jaakkopasanen/AutoEq — source of the parametric-EQ-plus-negative-preamp
   convention; its database covers headphones only, so it holds no profile for
   monitor speakers. https://github.com/jaakkopasanen/AutoEq

## Device evidence

3. EDID of `/sys/class/drm/card1-DP-1`: manufacturer `DEL`, product `0xd1b5`,
   display descriptor `DELL S3225QC`.
4. Dell 32 Plus 4K QD-OLED Monitor S3225QC User's Guide: speakers 5 × 5 W,
   frequency response 100 Hz–20 kHz, 4 Ω; Custom Audio with 5-band EQ.
   https://gzhls.at/blob/ldb/2/9/8/c/4dfd3355295d99ff518e44158aba4035d276.pdf
5. Dell S3225QC 3D Spatial Audio self-test (the monitor's own DSP, to disable
   for a stable baseline):
   https://www.dell.com/support/kbdoc/en-us/000294124/dell-s3225qc-3d-spatial-audio-user-self-test-instructions
6. Reviews consulted for audio character (none publishes a measurement):
   Tom's Hardware https://www.tomshardware.com/monitors/gaming-monitors/dell-s3225qc-32-inch-4k-qd-oled-monitor-review ;
   RTINGS https://www.rtings.com/monitor/reviews/dell/s3225qc ;
   Techaeris https://techaeris.com/2025/06/14/dell-32-plus-s3225qc-4k-review/
   (reports clear dialogue and overall positive voicing, which argued for
   small corrective gains).

## Equalizer design sources

7. F. E. Toole, *Sound Reproduction: The Acoustics and Psychoacoustics of
   Loudspeakers and Rooms*, 3rd ed., Routledge, 2017 — audibility of
   resonances, midrange coloration, preference for smooth response and
   conservative equalization.
8. S. Olive, T. Welti, E. McMullin, "Listener Preference for Different
   Headphone Target Frequency Responses", AES Convention 134 (2013), and the
   Harman target-curve research line — basis for mild shelf-type corrections
   rather than narrow high-gain bells.
9. High-pass below a small driver's rated band to limit excursion and
   intermodulation distortion: standard practice documented across
   loudspeaker-protection literature and bass-management design; the 80 Hz
   corner sits below Dell's rated 100 Hz lower bound (source 4).

## Tooling formats

10. EasyEffects (wwmm/easyeffects) — preset JSON schema (LSP `equalizer#0`
    bands) and service mode. https://github.com/wwmm/easyeffects
11. Autoload file format (`device`, `device-description`, `device-profile`,
    `preset-name`; file name `<node>:<route>.json`): Framework community
    guide, verified empirically here (service log + `-a output`).
    https://community.frame.work/t/guide-framework-dsp-better-linux-audio/44645
12. EasyEffects 8 preset location migration from `config/easyeffects/` to
    `data/easyeffects/`: observed in this installation's service log
    (`presets_directory_manager.cpp` messages), version 8.3.0.
