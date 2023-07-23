#!/bin/bash -
#
########################################
# title         : don_oracle_db_control.sh
# description   : To control Oracle DB with start/stop/status
# author        : D.Nepochitoj
# date          : 2023-07-22
# version       : 001.007
# usage         : see "core::get_help" below
# notes         : depends on core.sh
# bash_version  : 4.2.46(2)-release
########################################


########################################
# modules
########################################

source lib/logging_levels.sh
source lib/core.sh

########################################
# set variables
########################################

# reset parameters
unset DB_MACHINE DB_PORT ORACLE_SID ORACLE_HOME DB_COMMAND

readonly REGEXP_IS_NUMBER='^[0-9]+$'

# * https://docs.oracle.com/en/database/oracle/oracle-database/12.2/rilin/selecting-a-database-name.html#GUID-3C954866-8375-4319-9184-CAA5F3B299D4
    #
    # In Oracle RAC environments, the database name (DB_UNIQUE_NAME) portion
    # is a string of no more than 30 characters that can contain alphanumeric,
    # underscore (_), dollar ($), and pound (#) characters,
    # but must begin with an alphabetic character.
    # No other special characters are permitted in a database name.
    # The DB_NAME parameter for a database is set to the first 8 characters of the database name.
    #
# * https://regex101.com
# * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_expressions/Cheatsheet
# * https://www.ibm.com/docs/en/rational-clearquest/9.0.1?topic=tags-meta-characters-in-regular-expressions
    # * [\w-] is the same as [A-Za-z0-9_-]
    #
    # ^[a-zA-z]{1}[a-zA-z0-9_$#]{0,7}$
readonly REGEXP_IS_ORACLE_SID='^[a-zA-Z][a-zA-Z0-9_\$#]*'
readonly REGEXP_IS_ORACLE_HOME='^/'

#readonly DIVIDER_LINE="########################################"
#readonly DIVIDER_LINE=""

# set for formatting time
readonly TIMEFORMAT='%3lR'      ### TIMEFORMAT='%0lR'

SQLPLUS_ONLY_FLAG="false"

#printf "%s\n" "${DIVIDER_LINE}"

while getopts "hsvGm:p:d:o:c:S" option; do
    case "${option}" in
        # help
        h) core::get_help
            logging_levels::debug "-h specified: Help on usage"
            core::exit_normal
            ;;
        # logging_levels.sh
        s) VERBOSITY=$SILENT_LVL
            logging_levels::debug "-s specified: Silent mode"
            ;;
        v) VERBOSITY=$INF_LVL
            logging_levels::debug "-v specified: Verbose mode"
            ;;
        G) VERBOSITY=$DBG_LVL
            logging_levels::debug "-G specified: Debug mode"
            ;;
        ### main
        m) readonly DB_MACHINE="${OPTARG}"
            #logging_levels::debug "-m specified: set DB_MACHINE"
            ;;
        p) readonly DB_PORT="${OPTARG}"
            #logging_levels::debug "-p specified: set DB_PORT"
            if ! [[ $DB_PORT =~ $REGEXP_IS_NUMBER ]]; then
                logging_levels::critical "ERROR: DB_PORT must be a positive, whole number."
                core::exit_abnormal
            elif [[ $DB_PORT -eq 0 ]]; then
                logging_levels::critical "ERROR: TIMES must be greater than zero"
                core::exit_abnormal
            fi
            ;;
        d) readonly ORACLE_SID="${OPTARG}"
            #logging_levels::debug "-d specified: set ORACLE_SID"
            if ! [[ $ORACLE_SID =~ $REGEXP_IS_ORACLE_SID ]]; then
                logging_levels::critical "ERROR: ORACLE_SID must be no more than 8 characters that can contain alphanumeric, underscore (_), dollar ($), and pound (#) characters, but must begin with an alphabetic character."
                core::exit_abnormal
            fi
            export ORACLE_SID
            ;;
        o) readonly ORACLE_HOME="${OPTARG}"
            #logging_levels::debug "-o specified: set ORACLE_HOME"
            if ! [[ $ORACLE_HOME =~ $REGEXP_IS_ORACLE_HOME ]]; then
                    logging_levels::critical "ERROR: ORACLE_HOME must begin from /."
                    core::exit_abnormal
            fi
            export ORACLE_HOME
            ;;
        c) readonly DB_COMMAND="${OPTARG}"
            #logging_levels::debug "-c specified: set DB_COMMAND"
            case "${DB_COMMAND}" in
                start|stop|status) ;;
                *)  logging_levels::critical "check_input_commands: ERROR: incorrect input for command. Correct commands: start, stop, status\n"
                    core::exit_abnormal
                    ;;
            esac
            ;;
        S) SQLPLUS_ONLY_FLAG="true"
            logging_levels::dump_var SQLPLUS_ONLY_FLAG
            ;;
        *) logging_levels::critical "main: ERROR: incorrect parameter\n"
            core::get_help
            core::exit_abnormal
            ;;
    esac
done

# handle no options to getopt passed
if [[ "$OPTIND" -eq 1 ]]; then
    logging_levels::critical "ERROR: no options to getopt passed"
    core::get_help
    core::exit_abnormal
fi

# logging_levels::dump_var VERBOSITY DB_MACHINE DB_PORT ORACLE_SID ORACLE_HOME DB_COMMAND
# logging_levels::debug "\n"

# set default variables, if no values passed from getopts
if [ -z "$DB_MACHINE" ] ;  then readonly DB_MACHINE="$(hostname -s)" ; fi
if [ -z "$DB_PORT" ] ;     then readonly DB_PORT="1521" ; fi
if [ -z "$ORACLE_SID" ] ;  then readonly ORACLE_SID="dbb" ; export ORACLE_SID; fi
if [ -z "$ORACLE_HOME" ] ; then readonly ORACLE_HOME="/u02/app/oracle/db/19.11" ; export ORACLE_HOME; fi
if [ -z "$DB_COMMAND" ] ;  then readonly DB_COMMAND="status" ; fi

# get values based on inputs
readonly SRVCTL_FILE=$(command -v "${ORACLE_HOME}"/bin/srvctl)
readonly SQLPLUS_FILE=$(command -v "${ORACLE_HOME}"/bin/sqlplus)
logging_levels::dump_var SRVCTL_FILE SQLPLUS_FILE

# check if any executable: srvctl, sqlplus - is available
if ! [[ -f "${SRVCTL_FILE}" || -f "${SQLPLUS_FILE}" ]]; then
    logging_levels::critical "ERROR: found no executables srvctl and/or sqlplus for input parameters. Re-check inputs.\n"
    core::exit_abnormal
fi

#printf "\n"
#printf "%s\n" "${DIVIDER_LINE}"

logging_levels::debug "Parameters passed:"
logging_levels::dump_var DB_MACHINE DB_PORT ORACLE_SID ORACLE_HOME DB_COMMAND



########################################
# functions
########################################

oracle_db_control_ps_sqlplus_handle_no_need_actions()
{
    # special cases:
    # * if db is alread started, no need start it;
    # * if db is alread stopped, no need stop it.

    logging_levels::debug "oracle_db_control_ps_sqlplus_get_current_status: begin";

    local db_pmon_is_up
    local oracle_db_status

    # check db pmon process is running
    # * https://stackoverflow.com/questions/22727107/how-to-find-the-last-field-using-cut
    db_pmon_is_up=$( ps -u "${LOGNAME}" | grep ora_pmon | grep -o '[^_]*$' | grep "${ORACLE_SID}" )

    logging_levels::dump_var LOGNAME ORACLE_SID db_pmon_is_up

    # on the local host
    if [[ "$db_pmon_is_up" ]]; then
        logging_levels::dump_var ORACLE_SID ORACLE_HOME SQLPLUS_FILE
        oracle_db_status=$( "${SQLPLUS_FILE}" -s / as sysdba <<'EOF'
set pages 0
set head off
set feed off
select status from v$instance i;
exit;
EOF
)
        logging_levels::dump_var oracle_db_status

        # if db is alread started, no need start it
        if [[ "${oracle_db_status}" == "OPEN" ]] && [[ "${DB_COMMAND}" == "start" ]] ; then
            printf "Instance %s status: %s. No need actions, db is already started.\n" "${ORACLE_SID}" "${oracle_db_status}"
            core::exit_normal
        fi
    elif [[ "${DB_COMMAND}" == "stop" ]]; then
        # if db is alread stopped, no need stop it
        printf "Instance %s status: STOPPED. No need actions, db is already stopped.\n" "${ORACLE_SID}"
        core::exit_normal
    fi

    logging_levels::debug "oracle_db_control_ps_sqlplus_get_current_status: end";

}

# start/stop/.. oracle db w srvctl
oracle_db_control_srvctl_all()
{
    logging_levels::debug "oracle_db_control_srvctl_all: begin";
    logging_levels::debug "${SRVCTL_FILE} ${DB_COMMAND} database -d ${ORACLE_SID} -verbose\n"

    # if [[ "${DB_COMMAND}" != "status" ]]; then
    #     oracle_db_control_srvctl_status
    # fi

    "${SRVCTL_FILE}" "${DB_COMMAND}" database -d "${ORACLE_SID}" -verbose

    if (( $? != 0 )); then
        logging_levels::critical "srvctl failled."
        core::exit_abnormal
    fi
    # tbd: add checking for $?

    printf "\n"
    logging_levels::debug "oracle_db_control_srvctl_all: end"
    #core::get_timestamp
}

# start/stop/.. oracle db w sqlplus
oracle_db_control_sqlplus_all()
{
    logging_levels::dump_var SQLPLUS_FILE
    case "${DB_COMMAND}" in
        status)
            "${SQLPLUS_FILE}" -s / as sysdba <<'EOF'
set head off
select 'Database ' || d.NAME
    || ' is ' || d.OPEN_MODE
    || '. Instance '|| i.INSTANCE_NAME
    || ' status: ' || i.STATUS
from v$database d join v$instance i on lower(d.name) = lower(i.INSTANCE_NAME);
exit;
EOF
            core::failed_command_exit "sqlplus status failed."
            # if (( $? != 0 )); then
            #     logging_levels::critical "sqlplus status failed."
            #     core::exit_abnormal
            # fi
            ;;
        stop)
            "${SQLPLUS_FILE}" -s / as sysdba <<'EOF'
shu immediate;
exit;
EOF
            if (( $? != 0 )); then
                logging_levels::critical "sqlplus stop failed."
                core::exit_abnormal
            fi
            ;;
        start)
            "${SQLPLUS_FILE}" -s / as sysdba <<'EOF'
startup;
exit;
EOF
            if (( $? != 0 )); then
                logging_levels::critical "sqlplus start failed."
                core::exit_abnormal
            fi
            ;;
        *)
            logging_levels::critical "oracle_db_control_sqlplus_all: ERROR: incorrect input for command. Correct commands: start, stop, status\n"
            core::exit_abnormal
            ;;
    esac

    logging_levels::debug "oracle_db_control_sqlplus_all: end"
}


# start/stop/.. oracle db w srvctl or sqlplus
oracle_db_control()
{
    logging_levels::debug "oracle_db_control: begin"
    #logging_levels::dump_var SRVCTL_FILE

    # handle special cases where no need additional actions
    oracle_db_control_ps_sqlplus_handle_no_need_actions

    # choose srvctl or sqlplus to execute command for oracle db
    if command -v "${SRVCTL_FILE}" &> /dev/null && [[ "${SQLPLUS_ONLY_FLAG}" == "false" ]]; then
        logging_levels::debug "srvctl exists and SQLPLUS_ONLY_FLAG is false"
        oracle_db_control_srvctl_all "${DB_COMMAND}"
        logging_levels::debug "oracle_db_control: srvctl: end"
    else
        logging_levels::debug "srvctl missing or SQLPLUS_ONLY_FLAG is true"
        oracle_db_control_sqlplus_all "${DB_COMMAND}"
        logging_levels::debug "oracle_db_control: sqlplus: end"
    fi

    #printf "\n"
    logging_levels::debug "oracle_db_control: end"
    #printf "\n"
    #core::get_timestamp
}


########################################
# main
########################################
main()
{
#    printf "%s\n" "${DIVIDER_LINE}"
    core::get_timestamp
    time oracle_db_control "${DB_MACHINE}" "${DB_PORT}" "${ORACLE_SID}" "${ORACLE_HOME}" "${DB_COMMAND}"
    core::exit_normal
}

main "$@"
