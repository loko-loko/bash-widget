#!/bin/bash

args_parse() {
    # Source file on your script and declare:
    #   ARG_DESCRIPTION: Description of script
    #   ARG_OPTS (List with '#' separator for item):
    #     1: Argument (separator If short and long, Ex: --long|-l
    #     2: Description of argument
    #     3: Variable name: declared and usable in script (Ex: my_variable)
    #     4: Argument type:
    #       - n: named argument : --arg {value}
    #       - b: boolean argument: --arg
    #       - p: positional argument: <arg>
    #     5: Is required: Only for named and positional argument (Only 1) (With value: 0 or 1)
    #     6: Default value: Only for named argument (If not set , variable will be: "")
    #     7: Choices: Only for named and positional argument (With separator '|' , Ex: tutu|tata)
    #
    # Notes:
    #   - Positional argument(s) must be declared in top of ARG_OPTS
    #   - Named argument can be used with syntax: --arg value or --arg-value
    #   - Script add --help argument so don't add it in ARG_OPTS
    #
    # Examples:
    #   source ./args.sh
    #   ARG_DESCRIPTION="Tools for testing argparse"
    #   ARG_OPTS=(
    #     "mode#Script Mode#mode#p#1##add|remove"
    #     "--account-id#Account ID#account_id#n#0#my_account#"
    #     "--dry-run#Dry Run Mode#dry_run#b###"
    #     "--debug#Debug Mode#DEBUG#b###"
    #   )
    #   args_parse "$@"
    #
    # Display Help:
    #   my-script.sh -h
    #   my-script.sh --help

    local arg_item_sep='#'
    local max_width=100

    _format_header() {
        local header=$@
        echo $header
        echo $header | sed -r 's#[A-Z0-9\-\_ ]#-#gi'
    }

    _format_text() {
        local header=$1
        shift 1
        local text=$@
        echo
        _format_header $header
        echo -e "$text" | fold -s -w $max_width
        echo
    }

    _format_help() {
        local header=$1
        shift 1
        local help_text=$@
        echo
        _format_header $header
        echo "$help_text" | awk -F';;' 'BEGIN { maxd = 0 } {
            for (i = 1; i <= NF; i++) {
                split($i, parts, ":::")
                len = length(parts[1])
                if (len > maxd) maxd = len
                data[i] = $i
            }
            for (i = 1; i <= NF; i++) {
                split(data[i], parts, ":::")
                if (parts[1]) printf "%-*s : %s\n", maxd, parts[1], parts[2]
            }
        }'
        echo
    }

    _err_msg() {
        local msg=$@
        local help_msg="[Type --help for more details]\n\nUsage: $(_print_usage 1)"
        echo -e "[ARG] ERROR: ${msg} ${help_msg}" >&2
        exit 1

    }

    _conf_err_msg() {
        local msg=$@
        echo -e "[ARG:CONFIG] ERROR: ${msg}" >&2
        exit 11
    }

    _print_usage() {
        local only_usage=${1:-0}
        local help_usage_required=""
        local help_usage_additional=""
        local help_positional=""
        local help_required=""
        local help_additional=""
        # Build usage
        while IFS="$arg_item_sep" read arg description var_name arg_type is_required default_value choices; do
            # Build help
            fmt_arg="$arg"
            fmt_description=$description
            if [[ $arg_type = "n" ]]; then
                [[ -n $choices ]]  && fmt_arg+=" {${choices}}" || fmt_arg+=" {${var_name}}"
            elif [[ $arg_type = "p" ]]; then
                [[ -n $choices ]]  && fmt_arg+=":${choices}"
                fmt_arg="<${fmt_arg}>"
            fi
            [[ -n $default_value ]] && fmt_description+=" [Default: '$default_value']"
            arg_help="$fmt_arg:::$fmt_description"
            # Add helper depends on arg type
            if [[ $arg_type =  "p" ]]; then
                help_positional+="$arg_help;;"
            else
                [[ $is_required = 1 ]] && help_required+="$arg_help;;" || help_additional+="$arg_help;;"
            fi
            # Add help usage
            [[ $is_required != 1 ]] && fmt_arg="(${fmt_arg})"
            [[ $arg_type = "p" || $is_required = 1 ]] && help_usage_required+=" $fmt_arg" || help_usage_additional+=" $fmt_arg"
        done < <(printf '%s\n' "${ARG_OPTS[@]}")
        # Build usage
        local help_usage="$(basename $0)${help_usage_required}${help_usage_additional}"
        [[ $only_usage = 1 ]] && { echo "$help_usage"; return; }
        # Add help args
        help_additional+="--help|-h:::Help"
        [[ -n $ARG_DESCRIPTION ]] && _format_text "Description" "$ARG_DESCRIPTION"
        _format_text "Usage" "$help_usage"
        [[ -n $help_positional ]] && _format_help "Positional Arguments" $help_positional
        [[ -n $help_required ]] && _format_help "Required Arguments" $help_required
        _format_help "Additional Arguments" $help_additional
    }

    local args=""
    local no_pos_arg=0
    # Declare variables and check arguments syntax
    while IFS="$arg_item_sep" read arg _ var_name arg_type is_required default_value _; do
        [[ -z $arg ]] && _conf_err_msg "Arg can't be empty."
        declare -p "$var_name" &> /dev/null && _conf_err_msg "Variable '$var_name' already declared"
        echo "$args" | grep -qE -- "$arg" && _conf_err_msg "Argument '$arg' already used"
        ! echo $arg_type | grep -qE '^[nbp]$' && _conf_err_msg "Bad Argument type: $arg_type (n: named, b: boolean, p: positional)"
        ! echo $var_name | grep -iqE '^[a-z0-9\_]+$' && _conf_err_msg "Bad var_name format: $var_name (Syntax: 'VAR_NAME', 'my_var')"
        if [[ $arg_type = "p" ]]; then
            [[ $no_pos_arg = 1 ]] && _conf_err_msg "Positional argument must be declared before other args (named/boolean)"
            [[ $is_required != 1 ]] && _conf_err_msg "Positional argument must be required"
            ! echo $arg | grep -qE '^[a-z0-9\_]+$' && _conf_err_msg "Bad positional argument format: $arg (Syntax: 'arg_name')"
        else
            no_pos_arg=1
            ! echo $arg | grep -qE -- '^--[a-z0-9\-]+(\|-[a-z0-9])?$' && _conf_err_msg "Bad named/boolean argument format: $arg (Syntax: '--long-arg' or '--long-arg|-s')"
        fi
        echo $arg_type | grep -qE '^[bp]$' && [[ -n $default_value ]] && _conf_err_msg "No default value for positional/boolean args (Set to empty)"
        [[ $arg_type = "b" ]] && [[ -n $is_required || -n $choices ]] && _conf_err_msg "Boolean arg can't be required or have choices (Set to empty)"
        # Get default value (if not set)
        if [[ -z $default_value ]]; then
            [[ $arg_type = "b" ]] && default_value=0 || default_value=""
        fi
        eval "$var_name='${default_value}'"
        args+="$(echo $arg | tr '|' ' ')"
    done < <(printf '%s\n' "${ARG_OPTS[@]}")

    for uidx in $(seq 1 $#); do
        cshift=0
        wegal=0
        uarg=$1
        uprm=$2
        if echo $uarg | grep -qE -- "--?[a-z0-9\-]+\=.*"; then
            wegal=1
            uarg=$(echo "$1" | cut -d'=' -f1)
            uprm=$(echo "$1" | cut -d'=' -f2-)
        fi
        idx=1
        while IFS="$arg_item_sep" read arg _ var_name arg_type is_required _ choices; do
            fmt_arg=$(echo $arg | tr '|' ' ')
            fmt_choices=$(echo $choices | tr '|' ' ')
            echo "--help -h" | grep -qE -- "(^| )$uarg($| )" && { _print_usage; exit 0; }
            if [[ $arg_type = "p" ]] && [[ $idx = $uidx ]]; then
                [[ -z $uarg ]] || echo "$args" | grep -qE -- "(^| )$uarg($| )" && _err_msg "Positional arg needed: '$var_name'"
                [[ -n $choices ]] && ! echo "$fmt_choices" | grep -qE -- "(^| )$uarg($| )" && _err_msg "Bad value for positional arg: $var_name"
                eval "$var_name='${uarg}'"
                cshift=1
            elif echo "$fmt_arg" | grep -qE -- "(^| )$uarg($| )"; then
                if [[ $arg_type = "b" ]]; then
                    eval "$var_name=1"
                    cshift=1
                else
                    [[ -z $uprm ]] || echo "$args" | grep -qE -- "(^| )$uprm($| )" && _err_msg "Param needed for '$uarg'"
                    [[ -n $choices ]] && ! echo "$fmt_choices" | grep -qE -- "(^| )$uprm($| )" && _err_msg "Bad value for: $uarg"
                    eval "$var_name='${uprm}'"
                    [[ $wegal = 1 ]] && cshift=1 || cshift=2
                fi
            elif [[ $uarg = "" ]]; then
                cshift=1
            fi
            [[ $cshift != 0 ]] && { shift $cshift; break; }
            (( idx++ ))
        done < <(printf '%s\n' "${ARG_OPTS[@]}")
        [[ $cshift = 0 ]] && _err_msg "Bad argument: '$uarg'"
    done
    # Check mandatory variables
    while IFS="$arg_item_sep" read arg _ var_name _ is_required _ _; do
       [[ $is_required = 1 && -z ${!var_name} ]] && _err_msg "Argument: '$arg' is required"
    done < <(printf '%s\n' "${ARG_OPTS[@]}")
}

# ARG_DESCRIPTION="Tools for testing argparse"
# ARG_OPTS=(
#   "mode#Script Mode#mode#p#1##add|remove"
#   "--account-id#Account ID#account_id#n#0#my_account#"
#   "--dry-run#Dry Run Mode#dry_run#b###"
#   "--debug#Debug Mode#DEBUG#b###"
# )
# args_parse "$@"
