#!/bin/sh
# Writes the websocket password from $OBS_PASSWORD and starts OBS on a
# virtual display.
set -e
cfg="$HOME/.config/obs-studio/plugin_config/obs-websocket"
mkdir -p "$cfg"
cat > "$cfg/config.json" <<JSON
{
  "alerts_enabled": false,
  "auth_required": true,
  "first_load": false,
  "server_enabled": true,
  "server_password": "${OBS_PASSWORD:-obspad-test}",
  "server_port": 4455
}
JSON
# A short beep the soundboard tests can play.
mkdir -p "$HOME/sounds"
ffmpeg -loglevel error -y -f lavfi -i "sine=frequency=880:duration=2" "$HOME/sounds/beep.wav"
# Local RTMP "platform" so a real live can be started and measured.
nginx -c "$HOME/nginx.conf"
# Leftovers from before a `docker restart` would stop Xvfb from starting.
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99
Xvfb :99 -screen 0 1280x720x24 -nolisten tcp &
export DISPLAY=:99
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ -e /tmp/.X11-unix/X99 ] && break
  sleep 0.5
done
exec obs --disable-shutdown-check --multi --minimize-to-tray "$@"
