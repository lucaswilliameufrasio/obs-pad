OBS settings baked into the test image.

- `basic/profiles/Padrao`: OBS defaults (recording shares the live encoder,
  so OBS cannot pause it).
- `basic/profiles/Gravacao`: recording with its own encoder ("Small"), which
  can be paused.

Both stream to the local nginx-rtmp started by `entrypoint.sh`.
