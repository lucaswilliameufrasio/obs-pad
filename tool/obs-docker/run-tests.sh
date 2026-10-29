#!/bin/sh
# Builds the headless OBS image, starts it and runs test/real_obs against it.
#   tool/obs-docker/run-tests.sh            # build, run, test, remove
#   KEEP=1 tool/obs-docker/run-tests.sh     # leave OBS running afterwards
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
name=${OBS_PAD_DOCKER_CONTAINER:-obspad-obs}
port=${OBS_PORT:-4455}

docker build -q -t obs-pad/obs-headless "$here" >/dev/null
docker rm -f "$name" >/dev/null 2>&1 || true

# OBS Pad Desktop runs next to OBS when built:
#   (cd companion && flutter build linux --release)
bundle="$root/companion/build/linux/x64/release/bundle"
companion_args=""
if [ -x "$bundle/obs_pad_desktop" ]; then
  companion_args="-v $bundle:/opt/obs-pad-desktop:ro -p 127.0.0.1:4457:4457 -p 127.0.0.1:4457:4457/udp"
  export OBS_PAD_COMPANION=1
fi
# shellcheck disable=SC2086
docker run -d --init --name "$name" -p "127.0.0.1:$port:4455" $companion_args \
  obs-pad/obs-headless >/dev/null
[ "${KEEP:-}" = 1 ] || trap 'docker rm -f "$name" >/dev/null' EXIT

printf 'Waiting for OBS'
for _ in $(seq 1 60); do
  if docker logs "$name" 2>&1 | grep -q 'you can haz websockets'; then break; fi
  printf .
  sleep 1
done
sleep 2
echo

cd "$root"
OBS_PAD_REAL_OBS=1 OBS_PAD_DOCKER_CONTAINER="$name" OBS_PORT="$port" \
  flutter test test/real_obs "$@"
