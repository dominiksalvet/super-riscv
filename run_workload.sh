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

set -mu

# global variables
declare -A pid_to_cmd_id

# $1 - workload name (optional)
init_env() {
    readonly WORKLOADS_DIR=workloads
    readonly WORKLOAD_NAME="${1:-quick_check}"
    readonly WORKLOAD_PATH="$WORKLOADS_DIR/${WORKLOAD_NAME}.workload"

    OUT_DIR="$(make api_get_out_dir)" || return
    readonly OUT_DIR
    readonly OUT_WORKLOAD_DIR="$OUT_DIR/workloads/$WORKLOAD_NAME"

    MAX_JOBS="$(nproc)" || return
    readonly MAX_JOBS
}

# TODO: add error reporting (and how to reproduce)
main() {
    echo 'Initializing execution environment ...'
    init_env "${1:-}" || return
    echo "Detected $MAX_JOBS execution threads ..."

    echo "Running workload $WORKLOAD_NAME ..."
    mkdir -p "$OUT_WORKLOAD_DIR" || return

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
                execute_group "$cur_group" "$group_lineno" "${group_cmds[@]}" || return
            fi

            cur_group="$line_group"
            group_lineno="$lineno"
            group_cmds=("$line_cmd")
        fi

    done < "$WORKLOAD_PATH" || return

    if (( lineno == 0 )); then
        echo "ERROR: $WORKLOAD_PATH is empty" >&2
        return 1
    else
        execute_group "$cur_group" "$group_lineno" "${group_cmds[@]}" || return
    fi

    # TODO: maybe move out of this function?
    echo "Workload $WORKLOAD_NAME finished successfully!"
}

# $1 - group name
# $2 - first command ID
# $@ - make commands
execute_group() {
    local group_name="$1"
    local cmd_id="$2"
    shift 2 || return

    echo "Executing group $group_name ..."

    # TODO: add simple progress tracking
    local -a failed_cmd_ids=()
    local running_jobs=0
    local cmd_line
    for cmd_line in "$@"; do
        execute_command "$cmd_id" "$cmd_line" &
        pid_to_cmd_id["$!"]="$cmd_id"

        ((++running_jobs))
        ((++cmd_id))

        while (( running_jobs >= MAX_JOBS )); do
            reap_one_job || return
        done
    done

    while (( running_jobs > 0 )); do
        reap_one_job || return
    done

    # TODO: add summary report of all errors (sorted)
    # if any command fails, the whole group fails
    if (( ${#failed_cmd_ids[@]} > 0 )); then
        return 1
    fi
}

# $1 - command ID
# $2 - command (string of make arguments)
execute_command() {
    trap - INT QUIT TERM

    local cmd_out_dir="$OUT_WORKLOAD_DIR/$1"
    mkdir -p "$cmd_out_dir" || return

    local -a cmd_array
    read -r -a cmd_array <<< "$2"
    cmd_array+=('INPUT_IN_FILE=1' "SIM_OUT_DIR=$cmd_out_dir")

    local cmd_log_file="$cmd_out_dir/command.log"
    {
        echo "make ${cmd_array[*]}"
        echo

        # execute the make command itself
        make "${cmd_array[@]}"
    } > "$cmd_log_file" 2>&1
}

reap_one_job() {
    local pid

    if ! wait -n -p pid; then
        local failed_cmd_id="${pid_to_cmd_id[$pid]}"
        failed_cmd_ids+=("$failed_cmd_id")

        # TODO: improve this report?
        echo "FAIL #$failed_cmd_id" >&2
    fi

    unset "pid_to_cmd_id[$pid]"
    ((running_jobs--))
}

# $1 - signal name
handle_sig() {
    local sig="$1"
    local child_sig

    case "$sig" in
        INT)
            echo 'Received SIGINT, stopping active jobs ...' >&2
            child_sig=INT
            ;;
        QUIT)
            echo 'Received SIGQUIT, killing active jobs ...' >&2
            child_sig=KILL
            ;;
        TERM)
            echo 'Received SIGTERM, stopping active jobs ...' >&2
            child_sig=TERM
            ;;
        *)
            echo 'ERROR: Received unhandled signal!' >&2
            exit 1
            ;;
    esac

    kill_jobs "$child_sig"

    case "$sig" in
        INT) exit 130 ;;
        QUIT) exit 131 ;;
        TERM) exit 143 ;;
    esac
}

# $1 - signal name
kill_jobs() {
    local pids
    pids="$(jobs -p)" || return

    # TODO: add a diagnosis message of killed commands
    local pid
    for pid in $pids; do
        kill -"$1" -- "-$pid" 2>/dev/null || true
    done

    # plain 'wait' tends to suffer from races here
    for pid in $pids; do
        wait "$pid" 2>/dev/null || true
    done

    echo 'All jobs terminated!' >&2
}

trap 'handle_sig INT' INT
trap 'handle_sig QUIT' QUIT
trap 'handle_sig TERM' TERM

# TODO: if failed, check if there are active jobs
main "$@"
