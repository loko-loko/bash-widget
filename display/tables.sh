#!/bin/bash

tables(){

    # This script who take on input a file or a variable and
    # display it under a table array (like linux command `column`)
    #
    # Examples:
    #   INPUT_VAR="raw1;raw2;raw3\nraw4;raw5;raw6"
    #
    #   Display with semicolon (default) separator:
    #     tables --input $INPUT_VAR
    #     | raw1 | raw2 | raw3
    #     | raw4 | raw5 | raw6
    #
    #   With header:
    #     tables --input $INPUT_VAR --header
    #     | raw1 | raw2 | raw3
    #     | ---- | ---- | ----
    #     | raw4 | raw5 | raw6
    #
    #   With custom marge:
    #     tables --input $INPUT_VAR --mrg 5
    #     | raw1     | raw2     | raw3
    #     | raw4     | raw5     | raw6

    local lst=''
    local cl_cnt='all'
    local header=0
    local sorting=0
    local sep=';'
    local mrg=1

    local usage="
    --help    : Help

    --input   : Input File|Variable
    --column  : Column to Display      [Default=all] (Ex: 1,3|1-3|2)
    --header  : Display Header         [Default=0]
    --sort    : Sort Column            [Default='']  (Ex: k2,n,r)
    --sep     : Input Separator        [Default=';']
    --mrg     : Margin between Column  [Default=1]
    "

    for _ in $(seq 1 $#); do
        case $1 in
            -h|--help  ) echo "$usage"; exit 0;;
            --input    ) lst=$2; shift 2;;
            --column   ) cl_cnt=$2; shift 2;;
            --header   ) header=1; shift 1;;
            --sort     ) sorting=$2; shift 2;;
            --sep      ) sep=$2; shift 2;;
            --mrg      ) mrg=$2; shift 2;;

            ''         ) shift 1;;
            *          ) echo '<!> Bad Argument(s) [--help]'; exit 1;;
        esac
    done

    [[ -z $lst ]] && { echo '<!> Argument --input Needed'; exit 1; }
    [[ -e $lst ]] && lst=$(cat $lst) || lst=$(echo -e "$lst")

    if [ $header == 1 ]]; then
        h=$(echo "$lst" | sed -n '1p')
        h_line=$(echo "$h" | sed -r 's#[A-Z0-9\-\_ ]#-#gi')
        lst=$(echo "$lst" | sed '1d')
    fi

    [[ $sorting != 0 ]] && lst=$(echo "$lst" | sort -$(echo ${sorting} | sed 's/,/\ \-/g'))
    [[ $header == 1 ]] && lst=$(echo "$h"; echo "$h_line"; echo "$lst")

    case $cl_cnt in
        *-*     ) local f_lst=($(seq ${cl_cnt%-*} ${cl_cnt#*-}));;
        *,*     ) local f_lst=($(echo "$cl_cnt" | sed s/,/\\n/g));;
        *[0-9]* ) local f_lst=($cl_cnt);;
        *|all   ) local f_lst=($(seq 1 $(echo "$lst" | head -n 1 | awk -v sep=$sep 'BEGIN{FS=sep} {print NF}')));;
    esac

    for f in ${f_lst[@]}; do
        cl[$f]=$(($(echo "$lst" | awk -v f=$f -v sep=$sep 'BEGIN{FS=sep} {print length($f)}' 2>&- | sort -n | sed -n '$p') + ${mrg}))
    done

    local pr_fmt=$(
        for f in ${f_lst[@]}; do
            echo -e "| %-${cl[$f]}.${cl[$f]}s\c"
        done
        printf "\\\n"
    )

    echo "$lst" | awk -v sep=$sep 'BEGIN{FS=sep}
        {printf "'"$pr_fmt"'", '"$(echo $(for f in ${f_lst[@]}; do echo "\$${f}"; done) | sed 's/\ /,\ /g')"'}
    '
}

# tables "axxxxx,bxxxxxxxxx,cxxxxxxxxxxxxxxxxxxxxxxxxx\n1,2,3" --header
