#!/bin/bash

# Find all the docker related processes running
for DC in `ps aux | grep docker | grep -v grep | awk '{print $2}'`; do
  # Find all the related child processes of those
  for CID in `pgrep -P $DC`; do
    COMMAND=$(ps $CID | grep -v 'TTY' | awk '{print substr($0, index($0,$5))}')
    CONTAINER=$(docker ps -q | xargs docker inspect --format '{{.State.Pid}}, {{.Name}}' | grep $CID | awk '{print $2}';)
    IMAGE=$(docker inspect --format='{{.Config.Image}}' $CONTAINER)
    LOG=$(docker inspect --format='{{.LogPath}}' $CONTAINER)
    echo -e "$CID\t$COMMAND\t$IMAGE\t$CONTAINER\t"
    for CHILD in `pgrep -P $CID`; do
      COMMAND=$(ps $CHILD | grep -v 'TTY' | awk '{print substr($0, index($0,$5))}')
      CONTAINER=$(docker ps -q | xargs docker inspect --format '{{.State.Pid}}, {{.Name}}' | grep $CHILD | awk '{print $2}';)
      echo -e " |-->  $CHILD\t$COMMAND\t$CONTAINER"
    done
      echo -e " [*] Log: $LOG"
  done
done

echo;echo

for CONTAINER_ID in `docker ps -q`; do
  echo
  CONTAINER_NAME=$(docker inspect --format "{{title .Name}}" $CONTAINER_ID)
  CONTAINER_IMAGE=$(docker inspect --format='{{.Config.Image}}' $CONTAINER_ID)
  CONTAINER_LOG=$(docker inspect --format='{{.LogPath}}' $CONTAINER_ID)
  echo "$CONTAINER_ID -> $CONTAINER_IMAGE -> $CONTAINER_NAME"
  echo "Log file: $CONTAINER_LOG"
  echo "---"
  docker top $CONTAINER_ID -eo pid,cmd | grep -v "PID"
  echo
done
