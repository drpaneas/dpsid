#!/bin/bash

INT_PKG=$(rpm -qa | grep -- '-docker-' | wc -l)
echo -e "Testing $INT_PKG packages:\n"

# Find all the packages installed related to Docker images
for PKG in $(rpm -qa | grep -- '-docker-'); do
  echo "Package Under Test: $PKG"

  # Create tmp directory
  DIR="/tmp/$PKG"
  mkdir "$DIR"

  # Find the path of the tarball and extract it
  TARBALL=$(rpm -ql "$PKG" | grep "tar.xz")
  tar -xf "$TARBALL" -C "$DIR"

  # Store the image hash and print it
  HASH=$(cat "$DIR/manifest.json" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[0]["Config"][7:];')
  echo "IMAGE ID: $HASH"

  # Find the currently running container that uses this base image
  FLAG=0
  for container in `docker ps -q`; do
    if docker inspect --format='{{.Image}}' $container | grep "$HASH" &> /dev/null; then
      CONTAINER_NAME=$(docker inspect --format "{{title .Name}}" $container)
      CONTAINER_IMAGE=$(docker inspect --format='{{.Config.Image}}' $container)
      echo -e " |--> PASS : $container || $CONTAINER_IMAGE || $CONTAINER_NAME"
      FLAG=1
    fi
  done

  # Find the base image that is not being used
  if [ "$FLAG" -eq 0 ]; then
    NOT_IN_USE="$PKG"
    echo " | --> FAIL : There is no running container using the base image id"
  fi

  # Delete the tmp directory and leave a space
  rm -r "$DIR"
  echo

done
