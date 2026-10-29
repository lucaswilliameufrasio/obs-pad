# OBS Pad Desktop

Optional app for the computer where OBS runs. With it open, OBS Pad on the
phone can:

- **find the computer** on the network ("Find on network"), no IP typing;
- **connect by QR code**;
- **send sounds from the phone**: they are saved in `~/OBS Pad/Sons` and the
  phone creates the OBS Media Source pointing to them;
- **turn on the OBS WebSocket server** with a password (OBS closed);
- on Windows, **allow OBS and OBS Pad through the firewall** (private
  networks only).

It talks to the phone on port 4457 (TCP and UDP). Every request is signed
with the OBS WebSocket password, which the app reads from the OBS settings on
this computer, so nothing extra has to be paired and the password never goes
over the network.

```bash
flutter run -d linux        # or windows / macos
flutter build linux --release
flutter test
```

The protocol, server and client live in `packages/obs_pad_companion`.
