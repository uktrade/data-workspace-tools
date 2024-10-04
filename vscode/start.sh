#!/bin/sh

set -eu

eval "$(fixuid -q)"

echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

mkdir -p /home/coder/.local/share/code-server/User/
cp /opt/code-server/settings.json /home/coder/.local/share/code-server/User/settings.json
chown -R coder:coder /home/coder

if [ "${DOCKER_USER-}" ]; then
  USER="$DOCKER_USER"
  if [ "$DOCKER_USER" != "$(whoami)" ]; then
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/nopasswd > /dev/null
    # Unfortunately we cannot change $HOME as we cannot move any bind mounts
    # nor can we bind mount $HOME into a new home as that requires a privileged container.
    sudo usermod --login "$DOCKER_USER" coder
    sudo groupmod -n "$DOCKER_USER" coder

    sudo sed -i "/coder/d" /etc/sudoers.d/nopasswd
  fi
fi

su - coder -c "exec dumb-init /usr/bin/code-server \
  --config /opt/code-server/config.yaml \
  --bind-addr 0.0.0.0:8888 \
  /home/coder"
