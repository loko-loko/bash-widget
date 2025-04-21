#!/bin/bash

load_bar(){ #ARG $total $object $msg $bar_lenght(Default:15)
    #
    # This small tool allows to display a progression bar.
    #
    # He take on arguments :
    #  - Total Object
    #  - Current Object
    #  - Message to display next to the bar
    #  - Bar size (Default:15)
    #
    #
    # Examples:
    #   Load bar on loop:
    #     for i in {1..32}; do load_bar 32 $i "My Custom Bar"; sleep .1; done
    #     My Custom Bar : [ooo............] 21% [007/032]
    #     My Custom Bar : [ooooo..........] 37% [012/032]
    #     My Custom Bar : [ooooooo........] 53% [017/032]
    #     My Custom Bar : [ooooooooooo....] 75% [024/032]
    #     My Custom Bar : [oooooooooooooo.] 93% [030/032]
    #     My Custom Bar : [ooooooooooooooo] 100% [032/032] [done]
    #
    #   With Custom size (Default:15):
    #     for i in {1..32}; do load_bar 32 $i "My Bar" 30; sleep .1; done
    #     My Bar : [ooooo.........................] 18% [006/032]
    #     My Bar : [oooooooooo....................] 34% [011/032]
    #     My Bar : [ooooooooooooooo...............] 53% [017/032]
    #     My Bar : [ooooooooooooooooooooo.........] 71% [023/032]
    #     My Bar : [ooooooooooooooooooooooooooo...] 90% [029/032]
    #     My Bar : [oooooooooooooooooooooooooooooo] 100% [032/032] [done]

    local total=$1
    local object=$2
    local msg=$3
    local bar_lenght=${4:-15}

    local percent=$((object * 100 / total))
    local bar_filled=$((object * bar_lenght / total))
    local bar_empty=$((bar_lenght - bar_filled))

    load_bar=$(
        printf "["
        [[ $bar_filled != 0 ]] && for i in $(seq 1 ${bar_filled}); do printf "o"; done
        [[ $bar_filled != $bar_lenght ]] && for i in $(seq 1 ${bar_empty}); do printf "."; done
        printf "]"
    )

    local percent_fmt=$(printf "%02d" $percent)
    local total_fmt=$(printf "%03d" $total)
    local object_fmt=$(printf "%03d" $object)

    local load_bar_fmt="  $msg\t: $load_bar ${percent_fmt}% [$object_fmt/$total_fmt]"

    [[ $total != $object ]] && echo -e "$load_bar_fmt\r\c" || echo -e "$load_bar_fmt [done]"

}

# for i in {1..32}; do load_bar 32 $i "My Progession Bar" 30; sleep .1; done

