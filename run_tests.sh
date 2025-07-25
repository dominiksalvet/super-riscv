#!/bin/sh

#
#   Super RISC-V - superscalar dual-issue RISC-V processor
#   Copyright (C) 2024 Dominik Salvet
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# This is a test runner for Super RISC-V processor. It uses the delivered
# Makefile to support its reuse. It runs all tests found in the tests/
# directory. Each test is run with three different configurations of
# unknown values to prevent possible bugs (zeros, ones, random).

TESTS_DIR=tests
OUT_DIR=out

LOG_FILE="$OUT_DIR/run_tests.log"

# $@ - echo arguments
echo_log()
{
    echo "$@"     # to log file
    echo "$@" >&3 # to stdout
}

# $@ - make arguments
make_log()
{
    echo "Running 'make $*'" # log make command invocation
    make "$@"                # then execute it
}

# $1 - tests directory
get_test_names()
(
    cd "$1" || return
    test_names="$(echo *.s | tr ' ' '\n' | sed 's/\.s$//')"

    if [ "$test_names" = '*' ]; then
        echo 'No tests found' >&2
        return 1
    fi

    echo "$test_names"
)

main()
(
    mkdir -p "$OUT_DIR" &&
    exec 3>&1 1>"$LOG_FILE" 2>&1 || return

    echo_log 'Generating C++ processor model ...'
    make_log verilate || return

    echo_log 'Building C++ processor model ...'
    make_log build || return

    echo_log 'Collecting tests ...'
    test_names="$(get_test_names "$TESTS_DIR")" || return

    # TODO: consider whether running all tests three times is appropriate
    for test_name in $test_names; do
        echo_log "Running test $test_name ..."
        make_log sim ASSERTS=1 TEST_NAME="$test_name" X_VAL=0 &&
        make_log sim ASSERTS=1 TEST_NAME="$test_name" X_VAL=1 &&
        make_log sim ASSERTS=1 TEST_NAME="$test_name" X_VAL=2 SEED=42 || return
    done

    echo_log 'All tests passed'
)

main
main_status="$?"

if [ "$main_status" -ne 0 ]; then
    echo "Testing failed, see $LOG_FILE"
fi

exit "$main_status"
