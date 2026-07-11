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

set -e

# $1 - workload name (optional)
init_env() {
    OUT_DIR="$(make api_get_out_dir)"
    readonly OUT_DIR
    readonly WORKLOADS_DIR=workloads

    # global variables
    workload_name="${1:-quick_check}"
    workload_path="$WORKLOADS_DIR/${workload_name}.workload"
}

# $1 - parallel group
# $@ - make commands
execute_group() {
    echo "Executing group $1"

    local group="$1"
    shift
    local -a cmds=("$@")

    for cmd in "${cmds[@]}"; do
        echo "make $cmd"
    done
}

main() {
    echo 'Initializing execution environment ...'
    init_env "$1"

    echo "Running workload $workload_name ..."

    local lineno=0
    local cur_group="" # current parallel group
    local -a cur_cmds=() # make commands to be executed in parallel

    while IFS= read -r line || [ "$line" ]; do
        ((++lineno))

        local line_group="${line%% *}"
        local line_cmd="${line#* }"

        if [ "$line_group" = "$line_cmd" ] || [ -z "$line_group" ] || [ -z "$line_cmd" ]; then
            echo "ERROR: ${workload_path}:${lineno}: invalid line" >&2
            return 1
        fi

        if [ "$cur_group" = "$line_group" ]; then
            cur_cmds+=("$line_cmd")
        else
            if (( lineno != 1 )); then
                execute_group "$cur_group" "${cur_cmds[@]}"
            fi

            cur_group="$line_group"
            cur_cmds=("$line_cmd")
        fi
    done < "$workload_path"

    if (( lineno == 0 )); then
        echo "ERROR: $workload_path is empty" >&2
        return 1
    else
        execute_group "$cur_group" "${cur_cmds[@]}"
    fi
}

main "$@"
