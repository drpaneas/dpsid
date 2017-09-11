#!/bin/bash
# $1 is the file from MTUI containing 'list-packages -w'

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
done < "$1"
