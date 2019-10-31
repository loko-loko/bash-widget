#!/bin/bash

load_B(){ #ARG $total $object $msg $bar_lenght(Default:15)

    local total=$1
    local object=$2
    local msg=${3//_/ }
    local bar_lenght=${4:-15}

    local percent=$((object * 100 / total))
    local bar_filled=$((object * bar_lenght / total))
    local bar_empty=$((bar_lenght - bar_filled))

    load_bar=$(
        printf "["
        [ $bar_filled != 0 ] && for i in $(seq 1 ${bar_filled}); do printf "o"; done
        [ $bar_filled != $bar_lenght ] && for i in $(seq 1 ${bar_empty}); do printf "."; done
        printf "]"
    )

    local percent_fmt=$(printf "%02d" $percent)
    local total_fmt=$(printf "%03d" $total)
    local object_fmt=$(printf "%03d" $object)

    local load_bar_fmt="  $msg\t: $load_bar ${percent_fmt}% [$object_fmt/$total_fmt]"

    [ $total != $object ] && echo -e "$load_bar_fmt\r\c" || echo -e "$load_bar_fmt [done]"

}

load_B $*
