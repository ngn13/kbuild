#!/bin/bash

check_ret() {
  if [ $? -ne 0 ]; then
    error "$1"
    exit 1
  fi
}

get_file() {
  file=$(echo $1 | rev | cut -d"/" -f1 | rev)
}

remove_ext() {
  local ext=".$(echo $1 | rev | cut -d. -f1 | rev)"
  local len=${#ext}
  file=${1::-len}
}

download() {
  wget -N -nv --show-progress "${1}"
  return $?
}

load_version() {
  MAJOR=$(echo $1 | cut -d. -f1)
  MINOR=$(echo $1 | cut -d. -f2)
  MINOR2=$(echo $1 | cut -d. -f3)
  if [ -z "$MINOR2" ]; then
    MINOR2=$(echo $1 | cut -d- -f2)
  fi

  if [ -z "$MAJOR" ] || [ -z "$MINOR" ] || [ -z "$MINOR2" ]; then
    return 1
  fi
  return 0
}
