#!/bin/bash -
#
########################################
# title         : dn_oracle_db_control.sh
# description   : To control Oracle DB start/stop/..
# author        : D.Nepochitoj
# date          : 2023-06-25
# version       : 000.001
# usage         : ./dn_oracle_db_control.sh "${DB_HOST}" "${DB_PORT}" "${DB_NAME}" "${DB_HOME}" "${DB_COMMAND}"
# notes         :
# bash_version  : 4.2.46(2)-release
########################################

# "${}"

readonly DIVIDER_LINE="########################################"

# get values, if not provided use default values for oracle db
readonly DB_HOST=${1:-$(hostname -s)}
readonly DB_PORT=${2:-1521}
readonly DB_NAME=${3:-dbb}
readonly DB_HOME=${4:-/u02/app/oracle/db/19.11}
readonly DB_COMMAND=${5:-status}

# get values based on inputs
readonly SRVCTL_FILE=$(command -v "${DB_HOME}"/bin/srvctl)
readonly SQLPLUS_FILE=$(command -v "${DB_HOME}"/bin/sqlplus)

# start/stop/.. oracle db w srvctl
oracle_db_control_srvctl()
{
    printf "### oracle_db_control_srvctl: begin\n"
    printf "\n"
    time "${SRVCTL_FILE}" "${DB_COMMAND}" database -d "${DB_NAME}" -verbose
    printf "\n"
    printf "### oracle_db_control_srvctl: end\n"
}

# start/stop/.. oracle db w sqlplus
oracle_db_control_sqlplus()
{
    case "${DB_COMMAND}" in
        status)
            sqlplus -s / as sysdba <<'EOF'
set tim on
set timing on
set echo on
set head off
select 'Database ' || d.NAME
    || ' is ' || d.OPEN_MODE
    || '. Instance '|| i.INSTANCE_NAME
    || ' status: ' || i.STATUS
from v$database d join v$instance i on lower(d.name) = lower(i.INSTANCE_NAME);
exit;
EOF
            ;;
        *)
            printf "### oracle_db_control_sqlplus: ERROR: incorrect input for command. Correct commands: status\n"
            exit 1
            ;;
    esac

    printf "### oracle_db_control_sqlplus: end\n"
}

# start/stop/.. oracle db w srvctl or sqlplus
oracle_db_control()
{
    printf "\n"
    printf "%s\n" "${DIVIDER_LINE}"
    printf "### oracle_db_control: BEGIN: for %s %s %s %s %s\n" "${DB_HOST}" "${DB_PORT}" "${DB_NAME}" "${DB_HOME}" "${DB_COMMAND}"
    printf "\n"

    printf "### oracle_db_control: %s\n" "$SRVCTL_FILE"

    # check input commands: start/stop/status
    if ! [[ "${DB_COMMAND}" == "start" || "${DB_COMMAND}" == "stop" || "${DB_COMMAND}" == "status" ]]; then
        printf "### oracle_db_control: ERROR: incorrect input for command. Correct commands: start, stop,  status\n"
        exit 1
    fi

    # choose srvctl or sqlplus to execute command for oracle db
    if command -v "${SRVCTL_FILE}" &> /dev/null; then
        oracle_db_control_srvctl "${DB_COMMAND}"
        printf "### oracle_db_control: srvctl: end\n"
    else
        oracle_db_control_sqlplus "${DB_COMMAND}"
        printf "### oracle_db_control: sqlplus: end\n"
    fi

    printf "\n"
    printf "### oracle_db_control: END: for %s %s %s %s %s\n" "${DB_HOST}" "${DB_PORT}" "${DB_NAME}" "${DB_HOME}" "${DB_COMMAND}"
    printf "%s\n" "${DIVIDER_LINE}"
    printf "\n"
}

oracle_db_control "${DB_HOST}" "${DB_PORT}" "${DB_NAME}" "${DB_HOME}" "${DB_COMMAND}"
