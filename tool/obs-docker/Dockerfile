# Headless OBS Studio with obs-websocket for integration tests.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends software-properties-common gpg-agent \
 && add-apt-repository -y ppa:obsproject/obs-studio \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      obs-studio xvfb xauth mesa-utils libgl1-mesa-dri dbus-x11 \
      ffmpeg ca-certificates nginx libnginx-mod-rtmp \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m obs \
 && chown -R obs:obs /var/log/nginx /var/lib/nginx
USER obs
WORKDIR /home/obs

COPY --chown=obs:obs config/ /home/obs/.config/obs-studio/
COPY --chown=obs:obs nginx.conf /home/obs/nginx.conf
COPY --chown=obs:obs entrypoint.sh /home/obs/entrypoint.sh

ENV LIBGL_ALWAYS_SOFTWARE=1
EXPOSE 4455
ENTRYPOINT ["/home/obs/entrypoint.sh"]
