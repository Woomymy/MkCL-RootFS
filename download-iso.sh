#!/usr/bin/env bash

set -eo pipefail

CL_VARIANT="${1}"
[[ -z "${CL_VARIANT}" ]] && CL_VARIANT="css"

rm_suffix() {
    IN="${1}"
    if [[ "${IN}" =~ ^0[0-9]{,}$ ]]
    then
        IN="${IN/0/}"
    fi
    echo "${IN}"
}

get_year() {
    echo "$(date +%Y)"
}

get_month() {
    BASE_MONTH="$(date +%m)"
    if [[ "${#BASE_MONTH}" == "1" ]]
    then
        echo "0${BASE_MONTH}"
    else
        echo "${BASE_MONTH}"
    fi
}

get_day() {
    BASE_DAY="$(date +%d)"
    if [[ "${#BASE_DAY}" == "1" ]]
    then
        echo "0${BASE_DAY}"
    else
        echo "${BASE_DAY}"
    fi
}

get_days() {
    CALC_YEAR="${2}"
    CALC_MONTH="${1}"
    case "${CALC_MONTH}" in
        1|3|5|7|8|10|12)
            echo "31"
            ;;
        4|6|9|11)
            echo "30"
            ;;
        2)
            if [[ "$((( CALC_YEAR % 4 )))" == "0" && "$((( CALC_YEAR % 100 )))" != "0" ]]
            then
                echo "29"
            else
                if [[ "$((( CALC_YEAR % 400 )))" == "0" ]]
                then
                    echo "29"
                else
                    echo "28"
                fi
            fi
            ;;
    esac
}

YEAR="$(get_year)"
MONTH="$(get_month)"
DAY="$(get_day)"

NIGHTLY_BASEDIR="http://miroir.linuxtricks.fr/nightly/"
ISO_ROOT="${NIGHTLY_BASEDIR}/${YEAR}${MONTH}${DAY}"

while [[ "$(curl -o /dev/null -sSL "${ISO_ROOT}" -w "%{http_code}")" == "404" ]]
do
    if [[ "${DAY}" == "01" ]]
    then
        if [[ "${MONTH}" == "01" ]]
        then
            MONTH="12"
            YEAR="$((( YEAR - 1 )))"
            DAY="$(get_days "${MONTH}" "${YEAR}")"
        else
            MONTH="$(rm_suffix "${MONTH}")"
            MONTH="$((( MONTH - 1 )))"
            DAY="$(get_days "${MONTH}" "${YEAR}")"
            [[ "${#MONTH}" == "1" ]] && MONTH="0${MONTH}"

        fi
    else
        DAY="$(rm_suffix "${DAY}")"
        DAY="$((( DAY - 1 )))"
        [[ "${#DAY}" == "1" ]] && DAY="0${DAY}"
    fi
    echo "Trying date ${YEAR} ${MONTH} ${DAY}"
    ISO_ROOT="${NIGHTLY_BASEDIR}/${YEAR}${MONTH}${DAY}"
    sleep 0.1
done

CL_DATE="${YEAR}${MONTH}${DAY}"
CL_ARCH="$(arch)"

ISO_FILE="${CL_VARIANT}-${CL_DATE}-${CL_ARCH}.iso"
ISO_LINK="${ISO_ROOT}/${ISO_FILE}"

[[ -e "${ISO_FILE}" ]] && rm -rf "${ISO_FILE}"

wget "${ISO_LINK}" -O "${ISO_FILE}"

