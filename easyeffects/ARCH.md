# ARCH

## Signal path

PipeWire link topology with the service running (verified with `pw-link -l`):

```
application stream
  → easyeffects_sink (virtual sink; EasyEffects moves playback streams here)
  → ee_soe_equalizer (LSP parametric equalizer, the dell-s3225qc preset)
  → ee_soe_spectrum → ee_soe_output_level
  → alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__HDMI1__sink
  → DisplayPort → Dell S3225QC internal DSP and speakers
```

## Autoload matching

EasyEffects loads an output preset automatically when the active device and
route match an autoload rule. The rule file name and its JSON fields carry the
match key:

1. `device` = PipeWire node name of the sink (`alsa_output…HiFi__HDMI1__sink`).
2. `device-profile` = route name of the active port (`[Out] HDMI1`, from the
   device's `Route` parameter).
3. `preset-name` = `dell-s3225qc`.

## Equalizer design

No published frequency-response measurement of the S3225QC speaker array exists
(searched 2026-10-09; see EVIDENCE_INSPIRATION_REFERENCE.md). The curve is
therefore a conservative correction derived from the rated specification
(5 × 5 W drivers, 100 Hz–20 kHz response) and established small-loudspeaker
practice. Gains stay within ±2.5 dB so the correction cannot be worse than the
uncorrected state by a large margin.

| Band | Type | f (Hz) | Gain (dB) | Q | Purpose |
|---|---|---|---|---|---|
| 0 | Hi-pass, 24 dB/oct | 80 | — | 0.707 | Removes signal below the rated 100 Hz band edge; reduces driver excursion and intermodulation distortion at volume. |
| 1 | Lo-shelf | 150 | +2.0 | 0.707 | Restores warmth just above the roll-off that small sealed enclosures lose. |
| 2 | Bell | 500 | −2.0 | 1.5 | Reduces enclosure boxiness; resonances in 200–800 Hz are the most audible colorations. |
| 3 | Bell | 3000 | +1.0 | 1.0 | Presence region; supports speech intelligibility at near-field distance. |
| 4 | Hi-shelf | 8000 | +1.5 | 0.707 | Compensates high-frequency loss off-axis from the downward-oriented drivers. |

Input gain −2.5 dB precedes the filters: negative pre-amplification equal to or
exceeding the maximum boost prevents digital clipping (AutoEq convention).

## Invariants

1. The repository is the source of truth; `sync.sh` rsyncs the preset and
   autoload directories with `--delete`. A preset saved only from the GUI in
   `$HOME` disappears at the next sync unless copied into the repository first.
2. EasyEffects 8 reads presets from the XDG data directory
   (`~/.var/app/…/data/easyeffects/`), not the config directory. Files placed
   under `config/easyeffects/{output,autoload}` trigger a migration at service
   start that moves the current data-directory presets to the Flatpak trash.
   Never track the `config/` paths.
3. The monitor applies its own DSP (six audio profiles, 3D spatial audio)
   after this equalizer. Keep the monitor on the `Standard` profile with
   spatial audio off; otherwise two unknown transfer functions stack.

## Trade-offs

1. Without a measurement microphone the curve corrects category-typical faults,
   not device-specific ones. A calibrated measurement (e.g. REW with a UMIK-1)
   would replace bands 1–4 with measured corrections.
2. The equalizer runs on the laptop, so it also shapes audio when the user
   routes output elsewhere manually while the HDMI1 route stays active; the
   autoload rule bounds this to the monitor sink.
