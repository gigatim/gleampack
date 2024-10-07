#!/usr/bin/env bash

fetch_gleam_versions() {
  local otp=$1

  curl -s "https://api.github.com/repos/gleam-lang/gleam/releases" > /tmp/gleam_versions.json
  cat /tmp/gleam_versions.json | \
    jq -r 'map(select(.draft == false)) | .[].tag_name' | \
    sed -e 's/^v//' | \
    sort -Vr > /tmp/gleam_versions
}

fetch_erlang_versions() {
  case "${STACK}" in
    "heroku-24")
      url="https://builds.hex.pm/builds/otp/ubuntu-24.04/builds.txt"
      curl -s "$url" | awk '/^OTP-([0-9.]+ )/ {print substr($1,5)}' > /tmp/otp_versions
      ;;
    *)
      echo "Gleam is not supported on this stack version."
      exit 1
      ;;
  esac
}

exact_erlang_version_available() {
  # TODO: fallback to hashnuke one if not ubuntu-20.04 and not found on hex
  version=$1
  available_versions=$2
  found=1
  while read -r line; do
    if [ "$line" = "$version" ]; then
      found=0
    fi
  done <<< $(cat /tmp/otp_versions)
  echo $found
}

exact_gleam_version_available() {
  version=$1
  found=1
  while read -r line; do
    if [ "$line" = "$version" ]; then
      found=0
    fi
  done <<< $(cat /tmp/gleam_versions)
  echo $found
}

check_erlang_version() {
  version=$1
  fetch_erlang_versions
  exists=$(exact_erlang_version_available "$version")
  if [ $exists -ne 0 ]; then
    output_line "Sorry, Erlang '$version' isn't currently supported on this stack or isn't formatted correctly."
    output_line "Available versions:"
    while read -r line; do
      output_line "    $line"
    done <<< $(print_columns /tmp/otp_versions)
    exit 1
  fi
  rm -f /tmp/otp_versions
}

check_gleam_version() {
  version=${1#v}
  echo $version
  fetch_gleam_versions
  exists=$(exact_gleam_version_available "$version")
  if [ $exists -ne 0 ]; then
    output_line "Sorry, Gleam '$version' isn't currently supported or isn't formatted correctly."
    output_line "Available versions:"
    while read -r line; do
      output_line "    $line"
    done <<< $(print_columns /tmp/gleam_versions)
    exit 1
  fi
  rm -f /tmp/gleam_versions
}

print_columns() {
  awk '
    {
      printf "%-20s", $0
      if (NR % 4 == 0) {
        printf "\n"
      }
    }
    END {
    if (NR % 4 != 0) {
      printf "\n"
    }
  }
  ' "$1"
}
