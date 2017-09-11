#!/bin/bash
# $1 is the file from MTUI containing 'list-packages -w'
#
# Description:
# * installation of the package
# * the existance of the changelog
# * The tagging of docker image
# * the version of RPM vs Docker image

# Colors for the output
red='\033[0;31m'
green='\033[1;32m'
blue='\033[0;34m'
NC='\033[0m' # No Color
bold=`tput bold`
normal=`tput sgr0`
yellow=$(tput setaf 3)

while IFS='' read -r line || [[ -n "$line" ]]; do
    PKG=$(echo $line | awk -F ':' '{ print $1 }' |  tr -d '[:space:]');
    version=$(echo $line | awk -F ':' '{ print $2 }' | tr -d '[:space:]');
    echo -e "${bold}Testing: ${yellow}$PKG-$version${NC}"

    # Installation
    if rpm -q $PKG-$version > /dev/null; then
      echo -e " ${green}PASS${NC}: Installation Test: rpm -q $PKG-$version is installed";
    else
      echo -e " ${red}FAIL${NC}: Installation Test: rpm -q $PKG-$version is not installed";
    fi

    # Existance of changelog
    if rpm -q --changelog $PKG | grep '*' > /dev/null; then
      echo -e " ${green}PASS${NC}: Changelog Test: rpm -q --changelog $PKG exists";
    else
      echo -e " ${red}FAIL${NC}: Changelog Test: rpm -q --changelog $PKG not found (building error)";
    fi

    # Docker image
    if echo $PKG | grep image > /dev/null; then
      DIR="/tmp/$PKG"
      mkdir "$DIR"
      TARBALL=$(rpm -ql "$PKG" | grep "tar.xz")
      tar -xf "$TARBALL" -C "$DIR"
      HASH=$(cat "$DIR/manifest.json" | python -c 'import json,sys;obj=json.load(sys.stdin);print obj[0]["Config"][7:];')
      #echo "IMAGE ID: $HASH"
      FLAG=0
      for container in `docker ps -q`; do
        if docker inspect --format='{{.Image}}' $container | grep "$HASH" &> /dev/null; then
          CONTAINER_NAME=$(docker inspect --format "{{title .Name}}" $container)
          CONTAINER_IMAGE=$(docker inspect --format='{{.Config.Image}}' $container)
          echo -e " ${green}PASS${NC}: Docker Tag Test: Container $container hash256 found to be used by $CONTAINER_NAME"
          if echo $CONTAINER_IMAGE grep $version > /dev/null; then
            echo -e " ${green}PASS${NC}: Consistency Test: RPM = $version and Docker = $CONTAINER_IMAGE -> are matching"
          else
            echo -e " ${red}FAIL${NC}: Consistency Test: RPM = $version and Docker = $CONTAINER_IMAGE -> are not matching"
          fi
          FLAG=1
        fi
      done
      if [ "$FLAG" -eq 0 ]; then
        NOT_IN_USE="$PKG"
        echo -e " ${red}FAIL${NC}: Docker Tag Test: There is no running container using the $HASH base image id"
      fi
      rm -r "$DIR"
    else
      echo -e " ${blue}SKIP:${NC} This package does not contain a docker image.";
    fi
done < "$1"
