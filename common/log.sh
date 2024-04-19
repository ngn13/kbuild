#!/bin/bash

BOLD="\e[1m"
RESET="\e[0m"
GREEN="\e[32m"
BLUE="\e[34m"
GRAY="\e[37m"
RED="\e[31m"

echo_color() {
  echo -e "${1}"
}

success() {
  echo_color "${BOLD}${GREEN}[+]${RESET}${BOLD} $1 ${RESET}"
}

info() {
  echo_color "${BOLD}${BLUE}[*]${RESET}${BOLD} $1 ${RESET}"
}

error() {
  echo_color "${BOLD}${RED}[-]${RESET}${BOLD} $1 ${RESET}"
}

print() {
  echo_color "${BOLD}${GRAY}$1${RESET}"
}
