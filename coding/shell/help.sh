#!/bin/bash
#
# name: help.sh
#
# desc: Locate files by name/content
# desc: (s) search string    - mandatory parameter
# desc: (d) target directory - optional parameter
# desc: (m) target marker    - optional parameter. Possible values = (all | name | desc | tag | ref | usage)
#
# markers:
# name: desc: tag: ref: usage:
#
# ref: n/a
#
# usage: help.sh -s ash
# usage: help.sh -d /some/dir -s ash
# usage: help.sh -d /some/dir -m all -s ash
# usage: help.sh -m tag -s ash

function f_get_os_type()
{
    ostype="$(uname -s)"

    case "${ostype}" in
        Linux*)     machine=Linux;;
        Darwin*)    machine=Mac;;
        CYGWIN*)    machine=Cygwin;;
        MINGW*)     machine=MinGw;;
        *)          machine="UNKNOWN:${unameOut}"
    esac

#    echo ${machine}
}



function f_help()
{

    target_dir="$1"
    target_marker="$2"
    search_str="$3"

    f_get_os_type

#    echo "$1" "$2" "$3" $machine

    # initialize parameters if null
    if [ -z ${target_dir} ]
    then
        target_dir="$(pwd)";
    fi

    if [[ "${machine}" == "Mac" ]]
    then

        case "${target_marker}" in
            all)    find "${target_dir}" -print0 | while read -d $'\0' file
                    do
                        echo '### May take some time ...'
                        egrep -sH 'name:|desc:|tag:|ref:|usage:' "${file}" | egrep -s --color "${search_str}"
                    done
                    ;;
            name)   find "${target_dir}" -print0 | while read -d $'\0' file
                    do
                        #egrep -sH 'name:' "${file}" | egrep -s --color "${search_str}"
                        mdfind -onlyin ${target_dir} "kMDItemDisplayName == '*${search_str}*'c"
                        break;
                    done
                    ;;
            desc)   find "${target_dir}" -print0 | while read -d $'\0' file
                    do
                        echo '### May take some time ...'
                        egrep -sH 'desc:' "${file}" | egrep -s --color "${search_str}"
                    done
                    ;;
            tag)    find "${target_dir}" -print0 | while read -d $'\0' file
                    do
                        echo '### May take some time ...'
                        egrep -sH 'tag:' "${file}" | egrep -s --color "${search_str}"
                    done
                    ;;
            ref)    find "${target_dir}" -print0 | while read -d $'\0' file
                    do
                        echo '### May take some time ...'
                        egrep -sH 'ref:' "${file}" | egrep -s --color "${search_str}"
                    done
                    ;;
            usage)  find "${target_dir}" -print0 | while read -d $'\0' file
                    do
                        echo '### May take some time ...'
                        egrep -sH 'usage:' "${file}" | egrep -s --color "${search_str}"
                    done
                    ;;
            *)      mdfind -interpret -onlyin ${target_dir} ${search_str}
                    #mdfind -onlyin ${target_dir} ${search_str}
        esac

        # if [[ "${target_marker}" == "all" ]]
        # then
        #     find "${target_dir}" -print0 | while read -d $'\0' file
        #     do
        #         egrep -sH 'name:|desc:|tag:|ref:|usage:' "${file}" | egrep -s --color "${search_str}"
        #     done
        # else
        #     mdfind -onlyin ${target_dir} ${search_str}
        # fi

    else
        echo '### ERROR: Unsupported OS. List of supported OS: Mac.'
    fi



}




### main

while getopts s:d:m: option
do
    case "${option}" in
        s) search_str="${OPTARG}"
            ;;
        d) target_dir="${OPTARG}"
            ;;
        m) target_marker="${OPTARG}"
            ;;
    esac
done

#echo '(s) target string   : '"${search_str}"
#echo '(d) target directory: '"${target_dir}"
#echo '(m) target marks    : '"${target_marker}"

f_help "${target_dir}" "${target_marker}" "${search_str}"

echo '### The end'
