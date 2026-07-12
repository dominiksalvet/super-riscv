#!/usr/bin/env bash

#
#   Super RISC-V - superscalar dual-issue RISC-V processor
#   Copyright (C) 2024-2026 Dominik Salvet
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

# This is a universal workload runner created for Super RISC-V processor needs.
# It uses the delivered Makefile hierarchical build system and 'workload' files
# describing individual steps and parallel execution opportunities. It is mainly
# intended for processor testing.

set -e

# $1 - workload name (optional)
init_env() {
    readonly WORKLOADS_DIR=workloads
    readonly WORKLOAD_NAME="${1:-quick_check}"
    readonly WORKLOAD_PATH="$WORKLOADS_DIR/${WORKLOAD_NAME}.workload"

    OUT_DIR="$(make api_get_out_dir)"
    readonly OUT_DIR
    readonly OUT_WORKLOAD_DIR="$OUT_DIR/workloads/$WORKLOAD_NAME"
}

# $1 - command ID
# $2 - command (string of make arguments)
execute_command() {
    mkdir -p "$OUT_WORKLOAD_DIR/$1"

    local -a cmd_array
    read -r -a cmd_array <<< "$2"
    cmd_array+=('INPUT_IN_FILE=1' "SIM_OUT_DIR=$OUT_WORKLOAD_DIR/$1")

    # TODO: store output to SIM_OUT_DIR if failing for simpler debugging
    make "${cmd_array[@]}" > /dev/null
}

# $1 - group name
# $2 - first command ID
# $@ - make commands
execute_group() {
    echo "Executing group $1 ..."
    local cmd_id="$2"
    shift 2

    # TODO: make this parallel (with reasonable limit)
    local cmd_line
    for cmd_line in "$@"; do
        execute_command "$cmd_id" "$cmd_line"
        ((cmd_id++))
    done
}

# TODO: add error reporting (and how to reproduce)
main() {
    echo 'Initializing execution environment ...'
    init_env "$1"

    echo "Running workload $WORKLOAD_NAME ..."
    mkdir -p "$OUT_WORKLOAD_DIR"

    local cur_group="" # current parallel group
    local group_lineno # start line number of group
    local -a group_cmds=() # make commands in group

    local lineno=0
    local line_group
    local line_cmd

    while IFS=' ' read -r line_group line_cmd || [ "$line_group" ] || [ "$line_cmd" ]; do
        ((++lineno))

        if [[ -z "$line_group" || -z "$line_cmd" ]]; then
            echo "ERROR: ${WORKLOAD_PATH}:${lineno}: invalid line" >&2
            return 1
        fi

        if [ "$cur_group" = "$line_group" ]; then
            group_cmds+=("$line_cmd")
        else
            if (( lineno != 1 )); then
                execute_group "$cur_group" "$group_lineno" "${group_cmds[@]}"
            fi

            cur_group="$line_group"
            group_lineno="$lineno"
            group_cmds=("$line_cmd")
        fi

    done < "$WORKLOAD_PATH"

    if (( lineno == 0 )); then
        echo "ERROR: $WORKLOAD_PATH is empty" >&2
        return 1
    else
        execute_group "$cur_group" "$group_lineno" "${group_cmds[@]}"
    fi

    echo "Workload $WORKLOAD_NAME finished successfully!"
}

main "$@"
