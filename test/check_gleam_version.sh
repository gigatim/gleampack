#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/gleam_funcs.sh
source $SCRIPT_DIR/../lib/canonical_version.sh

# override functions
reset_test() {
  EXIT_CODE=0
  OUTPUT_LINES=()
}

exit() {
  EXIT_CODE=$1
}
output_line() {
  OUTPUT_LINES+=("$1")
}


# TESTS
######################
suite "check_gleam_version"

  STACK="heroku-24"

  test "bad version"

    check_gleam_version v0.1.0 26.0

    [ "$EXIT_CODE" == 1 ]
    echo ${OUTPUT_LINES[0]} | grep -q "Gleam '0.1.0' isn't currently supported"



  test "good version"

    check_gleam_version v1.16.2 26.0

    [ "$EXIT_CODE" == "0" ]



PASSED_ALL_TESTS=true
