#!/bin/bash -
#
########################################
# title         : dn_oracle_db_control.sh
# description   : To control Oracle DB start/stop/..
# author        : D.Nepochitoj
# date          : 2023-07-10
# version       : 000.002
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

prt()
{
printf "### oracle_db_control: $1" "${@:2}"
}

# start/stop/.. oracle db w srvctl
oracle_db_control_srvctl()
{
    prt "srvctl: begin\n\n"
    time "${SRVCTL_FILE}" "${DB_COMMAND}" database -d "${DB_NAME}" -verbose
    prt "srvctl: end\n"
}

# start/stop/.. oracle db w sqlplus
oracle_db_control_sqlplus()
{
    if [ "${DB_COMMAND}" != "status" ]; then
            prt "sqlplus: ERROR: incorrect input for command. Correct commands: status\n"
            exit 1
    fi

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
    prt "end\n"
}

# start/stop/.. oracle db w srvctl or sqlplus
oracle_db_control()
{
    printf "\n%s\n" "${DIVIDER_LINE}"
    prt "BEGIN: for %s %s %s %s %s\n\n" "${DB_HOST}" "${DB_PORT}" "${DB_NAME}" "${DB_HOME}" "${DB_COMMAND}"
    prt "%s\n" "$SRVCTL_FILE"

    # check input commands: start/stop/status
    case ${DB_COMMAND} in
        start|stop|status) ;;
        *)   prt "ERROR: incorrect input for command. Correct commands: start, stop,  status\n"
             exit 1 ;;
    esac

    # choose srvctl or sqlplus to execute command for oracle db
    if command -v "${SRVCTL_FILE}" &> /dev/null; then
        oracle_db_control_srvctl "${DB_COMMAND}"
        prt "srvctl: end\n"
    else
        oracle_db_control_sqlplus "${DB_COMMAND}"
        prt "sqlplus: end\n"
    fi

    printf "\n"
    prt "END: for %s %s %s %s %s\n%s\n\n" "${DB_HOST}" "${DB_PORT}" "${DB_NAME}" "${DB_HOME}" "${DB_COMMAND}" "${DIVIDER_LINE}"
}

oracle_db_control "${DB_HOST}" "${DB_PORT}" "${DB_NAME}" "${DB_HOME}" "${DB_COMMAND}"
