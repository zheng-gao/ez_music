#!/usr/bin/env bash
###################################################################################################
# --------------------------------------- Common Command ---------------------------------------- #
###################################################################################################
REQUIRED_COMMANDS=()
# System Command
REQUIRED_COMMANDS+=("basename")
REQUIRED_COMMANDS+=("cat")
REQUIRED_COMMANDS+=("date")
REQUIRED_COMMANDS+=("dirname")
REQUIRED_COMMANDS+=("find")
REQUIRED_COMMANDS+=("grep")
REQUIRED_COMMANDS+=("mkdir")
REQUIRED_COMMANDS+=("ps")
REQUIRED_COMMANDS+=("read")
REQUIRED_COMMANDS+=("sleep")
REQUIRED_COMMANDS+=("tabs")
REQUIRED_COMMANDS+=("tail")
REQUIRED_COMMANDS+=("touch")
# Git Command
REQUIRED_COMMANDS+=("git")
# JAVA Command
REQUIRED_COMMANDS+=("java")
# Maven Command
REQUIRED_COMMANDS+=("mvn")

# Verify the required commands
function command_exist() {
    command -v "${cmd}" > "/dev/null" || { echo "Not found required command \"${cmd}\", Exit!"; exit; }
}

for cmd in "${REQUIRED_COMMANDS[@]}"; do command_exist "${cmd}"; done

###################################################################################################
# -------------------------------------- Global Variables --------------------------------------- #
###################################################################################################
if [[ "${0}" != "-bash" ]]; then
    # Put all global variables in this block in order to make "source ./control.sh" work
    BASE_DIRECTORY="$(dirname "${0}")"
else
    BASE_DIRECTORY="."
fi

###################################################################################################
# --------------------------------------- DEV Environment  -------------------------------------- #
###################################################################################################
PROJECT_NAME="ez_music"
DEV_WORKSPACE="/var/tmp/${PROJECT_NAME}_workspace"; [[ ! -d "${DEV_WORKSPACE}" ]] && mkdir -p "${DEV_WORKSPACE}"
DEV_LOGS="${DEV_WORKSPACE}/logs"; [[ ! -d "${DEV_LOGS}" ]] && mkdir -p "${DEV_LOGS}"
DEV_DATA="${DEV_WORKSPACE}/data"; [[ ! -d "${DEV_DATA}" ]] && mkdir -p "${DEV_DATA}"
DEV_LOG_FILE="${DEV_LOGS}/app.log"
DEV_PID_FILE="${DEV_DATA}/app.pid"

###################################################################################################
# ------------------------------------- Mini EZ-Bash Library ------------------------------------ #
###################################################################################################
function ez_contain() {
    # ${1} = Item, ${2} ~ ${n} = List
    for data in "${@:2}"; do [[ "${1}" = "${data}" ]] && return 0; done; return 1
}

function ez_exclude() {
    ez_contain "${@}" && return 1 || return 0
}

function ez_join() {
    local delimiter="${1}"; local i=0; local out_put=""
    for data in "${@:2}"; do
        [[ "${i}" -eq 0 ]] && out_put="${data}" || out_put+="${delimiter}${data}"
        ((++i))
    done
    echo "${out_put}"
}

function ez_log_stack() {
    local ignore_top_x="${1}"; local stack=""; local i=$((${#FUNCNAME[@]} - 1))
    if [[ -n "${ignore_top_x}" ]]; then
        for ((; i > "${ignore_top_x}"; --i)); do stack+="[${FUNCNAME[${i}]}]"; done
    else
        # i > 0 to ignore self "ez_log_stack"
        for ((; i > 0; --i)); do stack+="[${FUNCNAME[${i}]}]"; done
    fi
    echo "${stack}"
}

function ez_print_usage() {
    tabs 30; (>&2 echo -e "${1}\n"); tabs
}

function ez_build_usage() {
    local operation argument description="No Description"
    while [[ -n "${1}" ]]; do
        case "${1}" in
            "-o" | "--operation") shift; operation=${1}; [[ -n "${1}" ]] && shift ;;
            "-a" | "--argument") shift; argument=${1}; [[ -n "${1}" ]] && shift ;;
            "-d" | "--description") shift; description=${1}; [[ -n "${1}" ]] && shift ;;
            *) echo "$(ez_log_stack) Unknown argument \"${1}\""; return 1 ;;
        esac
    done
    if [[ "${operation}" = "init" ]]; then
        [[ -z "${argument}" ]] && argument="${FUNCNAME[1]}"
        # shellcheck disable=SC2028
        echo "\n[Function Name]\t\"${argument}\"\n[Function Info]\t${description}\n"
    elif [[ "${operation}" = "add" ]]; then
        # shellcheck disable=SC2028
        echo "${argument}\t${description}\n"
    else
        echo "$(ez_log_stack) Invalid value \"${operation}\" for \"-o|--operation\""; return 1
    fi
}

function ez_print_log() {
    local usage time_stamp
    if [[ "${1}" = "-h" ]] || [[ "${1}" = "--help" ]]; then
        usage=$(ez_build_usage -o "init" -d "Print Log to Console")
        usage+=$(ez_build_usage -o "add" -a "-l|--logger" -d "Logger type such as INFO, WARN, ERROR, ...")
        usage+=$(ez_build_usage -o "add" -a "-m|--message" -d "Message to print")
        ez_print_usage "${usage}"; return
    fi
    time_stamp="$(date '+%Y-%m-%d %H:%M:%S')"; local logger="INFO"; local message=""
    while [[ -n "${1}" ]]; do
        case "${1}" in
            "-l" | "--logger") shift; logger=${1}; [[ -n "${1}" ]] && shift ;;
            "-m" | "--message") shift; message=${1}; [[ -n "${1}" ]] && shift ;;
            *) echo "[${time_stamp}]$(ez_log_stack)[ERROR] Unknown argument identifier \"${1}\""; return 1 ;;
        esac
    done
    echo "[${time_stamp}]$(ez_log_stack 1)[${logger}] ${message}"
}

###################################################################################################
# -------------------------------------- Control Function --------------------------------------- #
###################################################################################################
function control_clean() {
    ez_print_log -m "Cleaning yarn build"
    rm -rf "${BASE_DIRECTORY}/src/main/react/frontend/build"
    rm -rf "${BASE_DIRECTORY}/src/main/react/frontend/node_modules"
    rm -rf "${BASE_DIRECTORY}/src/main/react/frontend/.eslintcache"
    # rm "${BASE_DIRECTORY}/src/main/react/frontend/package-lock.json"
    # rm "${BASE_DIRECTORY}/src/main/react/frontend/yarn.lock"
    ez_print_log -m "Cleaning maven build"
    mvn "clean" # this will clean "${BASE_DIRECTORY}/target"
    ez_print_log -m "Cleaning database"
    rm -f "${DEV_DATA}/h2.db"*
}

function control_build() {
    mvn "package"
}

function control_config() {
    local config_file="${BASE_DIRECTORY}/src/main/resources/application.properties" active_profile
    if [[ -n "${1}" ]]; then
        ez_print_log -m "Using \"application-${1}.properties\""
        active_profile="spring.profiles.active=${1}"
    else
        ez_print_log -m "Using \"application-dev-h2.properties\""
        active_profile="spring.profiles.active=dev-h2"
    fi
    echo "${active_profile}" > "${config_file}"
}

function control_publish() {
    ez_print_log -l "WARN" -m "Not implemented ${FUNCNAME[0]}"
}

function control_deploy() {
    ez_print_log -l "WARN" -m "Not implemented ${FUNCNAME[0]}"
}

function control_start() {
    local jar_file process_id
    jar_file=$(find "${BASE_DIRECTORY}/target" -d 1 -type f -name "*.jar" | tail -1)
    if [[ -f "${jar_file}" ]]; then
        java -jar "${jar_file}" > "${DEV_LOG_FILE}" 2>&1 &
        process_id="${!}"; echo "${process_id}" > "${DEV_PID_FILE}"
        ez_print_log -m "Running \"${jar_file}\" ..."
        ez_print_log -m "PID: \"${process_id}\""
        ez_print_log -m "Log: \"${DEV_LOG_FILE}\""
    else
        ez_print_log -l "ERROR" -m "Jar file not found in \"${BASE_DIRECTORY}/target\""
    fi
    # Run the maven sprint-boot command "mvn spring-boot:run" instead of running the jar
}

function control_open() {
    local url="http://localhost:8080"
    if command -v "open" > "/dev/null"; then open "${url}"
    else ez_print_log -m "Please open \"${url}\" in browser"; fi
}

function control_db() {
    # Connect to h2 database console
    local url="http://localhost:8080/h2-console"
    if command -v "open" > "/dev/null"; then open "${url}"
    else ez_print_log -m "Please open \"${url}\" in browser"; fi
    ez_print_log -m "JDBC URL = jdbc:h2:file:/var/tmp/ez_music_workspace/data/h2.db"
    ez_print_log -m "Username = admin"
    ez_print_log -m "Password = admin"
}

function control_status() {
    local process_id status="Down"; echo
    # shellcheck disable=SC2009
    ps -ef | grep -v "grep" | grep "java" | grep "jar" | grep "target" && status="Running" && echo
    echo "[App Status] ${status}"; echo
}

function control_log() {
    ez_print_log -m "Tailing log: ${DEV_LOG_FILE}"
    tail -f "${DEV_LOG_FILE}"
}

function control_stop() {
    local process_id sleep_seconds
    process_id=$(cat "${DEV_PID_FILE}")
    if [[ -z "${process_id}" ]]; then
        ez_print_log -l "ERROR" -m "PID not found!"
    else
        ez_print_log -m "Killing PID ${process_id} ..."
        kill "${process_id}"
        sleep_seconds=5; echo
        for i in {1..6}; do
            if ! ps -p "${process_id}"; then echo; break; fi
            echo; ez_print_log -m "Retry-${i} sleep ${sleep_seconds} seconds ..."; echo; sleep "${sleep_seconds}"
        done
        if ps -p "${process_id}" > "/dev/null"; then
            ez_print_log -l "ERROR" -m "PID ${process_id} is still alive, Timeout!"; return 1
        else
            ez_print_log -m "PID ${process_id} is killed"
        fi
    fi
}

function control_update() {
    ez_print_log -l "WARN" -m "Skip ${FUNCNAME[0]}"
}

###################################################################################################
# --------------------------------------- Heroku Function --------------------------------------- #
###################################################################################################
function control_heroku() {
    command_exist "heroku"
    local heroku_app_name
    read -rp "Heroku Application Name (default: ez-music-app): " heroku_app_name
    [[ -z "${heroku_app_name}" ]] && heroku_app_name="ez-music-app"
    if git "remote" -v | grep "heroku"; then
        ez_print_log -m "Already set heroku remote"
    else
        ez_print_log -m "Adding heroku remote"
        git "remote" "add" "heroku" "https://git.heroku.com/${heroku_app_name}.git"
    fi
    # heroku "create" "${heroku_app_name}"
    control_config "stg-heroku"
    ez_print_log -m "Pushing code to heroku ..."
    if git "push" "heroku" "master"; then
        ez_print_log -m "Open heroku website ..."
        heroku "open"
        ez_print_log -m "To view the heroku log: heroku logs --tail"
    else
        ez_print_log -l "ERROR" -m "Failed to push to heroku"
    fi
}

###################################################################################################
# ---------------------------------------- Main Function ---------------------------------------- #
###################################################################################################
function control() {
    local VALID_SKIPS=("clean" "config" "build" "publish" "deploy" "start" "stop"
                       "open" "db" "status" "log" "update" "heroku")
    local VALID_OPERATIONS=("ALL" "${VALID_SKIPS[@]}") usage=""
    if [[ -z "${1}" ]] || [[ "${1}" = "-h" ]] || [[ "${1}" = "--help" ]]; then
        usage=$(ez_build_usage -o "init" -d "Control Project Pipeline")
        usage+=$(ez_build_usage -o "add" -a "-o|--operations" -d "Choose from: [$(ez_join ', ' "${VALID_OPERATIONS[@]}")]")
        usage+=$(ez_build_usage -o "add" -a "-s|--skips" -d "Choose from: [$(ez_join ', ' "${VALID_SKIPS[@]}")]")
        usage+=$(ez_build_usage -o "add" -a "-f|--flags" -d "[Optional] The arguments of control_* function")
        ez_print_usage "${usage}"; return
    fi
    local args=("-o" "--operations" "-s" "--skips" "-f" "--flags") operations=() skips=() flags=()
    while [[ -n "${1}" ]]; do
        case "${1}" in
            "-o" | "--operations") shift
                while [[ -n "${1}" ]]; do
                    if ez_contain "${1}" "${args[@]}"; then break; else operations+=("${1}") && shift; fi
                done ;;
            "-s" | "--skips") shift
                while [[ -n "${1}" ]]; do
                    if ez_contain "${1}" "${args[@]}"; then break; else skips+=("${1}") && shift; fi
                done ;;
            "-f" | "--flags") shift
                while [[ -n "${1}" ]]; do
                    if ez_contain "${1}" "${args[@]}"; then break; else flags+=("${1}") && shift; fi
                done ;;
            *) ez_print_log -l "ERROR" -m "Unknown argument identifier \"${1}\", please choose from [${args[*]}]"; return 1 ;;
        esac
    done
    [[ -z "${operations[*]}" ]] && ez_print_log -l "ERROR" -m "No operation found!" && return 1
    if [[ "${#operations[@]}" -gt 1 ]] && ez_contain "ALL" "${operations[@]}"; then
        ez_print_log -l "ERROR" -m "Cannot mix \"ALL\" with other operations" && return 1
    fi
    for opt in "${operations[@]}"; do
        ez_exclude "${opt}" "${VALID_OPERATIONS[@]}" && ez_print_log -l "ERROR" -m "Invalid operation \"${opt}\"" && return 1
    done
    for skp in "${skips[@]}"; do
        ez_exclude "${skp}" "${VALID_SKIPS[@]}" && ez_print_log -l "ERROR" -m "Invalid skip \"${skp}\"" && return 1
    done
    if [[ "${operations[0]}" = "ALL" ]]; then
        operations=("stop" "clean" "config" "build" "publish" "deploy" "start" "status" "open")
    fi
    for opt in "${operations[@]}"; do
        ez_contain "${opt}" "${skips[@]}" && ez_print_log -m "Operation \"${opt}\" is skipped!" && continue
        ez_print_log -m "Operation \"${opt}\" is running ..."
        if "control_${opt}" "${flags[@]}"; then ez_print_log -m "Operation \"${opt}\" complete!"
        else ez_print_log -l "ERROR" -m "Operation \"${opt}\" failed!"; return 2; fi
    done
    ez_print_log -m "Done!!!"
}

# Entry Point
[[ "${0}" != "-bash" ]] && [[ "${0}" != "-sh" ]] && [[ $(basename "${0}") = "control.sh" ]] && control "${@}"
