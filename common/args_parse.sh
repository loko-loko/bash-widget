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
    #   - Use ARG_OPTS_CHECK=0, to skip syntax check of ARG_OPTS
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

    local args=""
    local arg_item_sep='#'
    local max_width=120
    local no_pos_arg=0

    _format_header() {
        local header=$@
        printf "\n%s\n" "$header"
        printf "%s\n" "$header" | sed 's/[[:alnum:]_ -]/-/g'
    }

    _format_text() {
        local header=$1
        shift 1
        local text=$@
        _format_header "$header"
        printf "%s\n\n" "$text" | fold -s -w $max_width
    }

    _format_help() {
        local header=$1
        shift 1
        local help_text=$@
        _format_header "$header"
        awk -F';;' 'BEGIN { maxd = 0 } {
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
        }' <<< $help_text
        printf "\n"
    }

    _err_msg() {
        local msg=$@
        local usage=$(_print_usage 1 | fold -s -w $max_width)
        printf "[ARG] ERROR: %s [Type --help for more details]\n\nUsage: %s\n" "${msg}" "${usage}" >&2
        exit 1
    }

    _conf_err_msg() {
        local msg=$@
        printf "[ARG:CONFIG] ERROR: %s\n" "${msg}" >&2
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
                [[ -n $choices ]] && fmt_arg+=" {${choices}}" || fmt_arg+=" {${var_name}}"
            elif [[ $arg_type = "p" ]]; then
                [[ -n $choices ]] && fmt_arg+=":${choices}"
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
            usage_fmt_arg="${fmt_arg// /=}"
            [[ $arg_type = "p" || $is_required = 1 ]] && help_usage_required+=" $usage_fmt_arg" || help_usage_additional+=" $usage_fmt_arg"
        done < <(printf '%s\n' "${ARG_OPTS[@]}")
        # Build usage
        local help_usage="$(basename $0)${help_usage_required}${help_usage_additional}"
        [[ $only_usage = 1 ]] && { printf "%s\n" "$help_usage"; return; }
        # Add help args
        help_additional+="--help|-h:::Display Help"
        [[ -n $ARG_DESCRIPTION ]] && _format_text "Description" "$ARG_DESCRIPTION"
        _format_text "Usage" "$help_usage"
        [[ -n $help_positional ]] && _format_help "Positional Arguments" $help_positional
        [[ -n $help_required ]] && _format_help "Required Arguments" $help_required
        _format_help "Additional Arguments" $help_additional
    }

    _init_opts() {
        # Declare variables and check arguments syntax
        while IFS="$arg_item_sep" read arg description var_name arg_type is_required default_value choices; do
            if [[ $ARG_CHECK_OPTS = 1 ]]; then
                [[ -z $arg || -z $description ]] && _conf_err_msg "Arg or Description can't be empty."
                declare -p "$var_name" &> /dev/null && _conf_err_msg "Variable '$var_name' already declared"
                [[ " ${args[*]} " == *" ${arg//|/ } "* ]] && _conf_err_msg "Argument '$arg' already used"
                [[ ! $arg_type =~ ^[nbp]$ ]] && _conf_err_msg "Bad Argument type: $arg_type (n: named, b: boolean, p: positional)"
                [[ ! $var_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && _conf_err_msg "Bad var_name format: $var_name (Syntax: 'VAR_NAME', 'my_var')"
                if [[ $arg_type = "p" ]]; then
                    [[ $no_pos_arg = 1 ]] && _conf_err_msg "Positional argument must be declared before other args (named/boolean)"
                    [[ $is_required != 1 ]] && _conf_err_msg "Positional argument must be required"
                    [[ ! $arg =~ ^[a-z0-9_]+$ ]] && _conf_err_msg "Bad positional argument format: $arg (Syntax: 'arg_name')"
                else
                    no_pos_arg=1
                    [[ ! $arg =~ ^--[a-z0-9\-]+(\|-[a-z0-9])?$ ]] && _conf_err_msg "Bad named/boolean argument format: $arg (Syntax: '--long-arg' or '--long-arg|-s')"
                fi
                [[ $arg_type =~ ^[bp]$ && -n $default_value ]] && _conf_err_msg "No default value for positional/boolean args (Set to empty)"
                [[ $arg_type = "b" ]] && [[ -n $is_required || -n $choices ]] && _conf_err_msg "Boolean arg can't be required or have choices (Set to empty)"
                [[ -n $default_value && -n $choices ]] && [[ ! " ${choices//|/ } " =~ " $default_value " ]] && _conf_err_msg "Default value for '$arg' must be present in: $choices"
            fi
            # Get default value (if not set)
            if [[ -z $default_value ]]; then
                [[ $arg_type = "b" ]] && default_value=0 || default_value=""
            fi
            eval "$var_name='${default_value}'"
            args+=" ${arg//|/ }"
        done < <(printf '%s\n' "${ARG_OPTS[@]}")
    }

    _init_opts
    for uidx in $(seq 1 $#); do
        cshift=0
        wegal=0
        if [[ $1 =~ ^--?[a-z0-9-]+=.* ]]; then
            wegal=1
            uarg="${1%%=*}"
            uprm="${1#*=}"
        else
            uarg=$1
            uprm=$2
        fi
        idx=1
        while IFS="$arg_item_sep" read arg _ var_name arg_type is_required _ choices; do
            fmt_arg="${arg//|/ }"
            fmt_choices="${choices//|/ }"
            [[ " --help -h " == *" $uarg "* ]] && { _print_usage; exit 0; }
            if [[ $arg_type = "p" ]] && [[ $idx = $uidx ]]; then
                [[ " $args " == *" $uarg "* ]] && _err_msg "Positional arg needed: '$var_name'"
                [[ -n $choices && " $fmt_choices " != *" $uarg "* ]] && _err_msg "Bad value for positional arg: $uarg"
                eval "$var_name='${uarg}'"
                cshift=1
            elif [[ " $fmt_arg " == *" $uarg "* ]]; then
                if [[ $arg_type = "b" ]]; then
                    eval "$var_name=1"
                    cshift=1
                else
                    [[ " $args " == *" $uprm "* ]] && _err_msg "Param needed for '$uarg'"
                    [[ -n $choices && " $fmt_choices " != *" $uprm "* ]] && _err_msg "Bad value for: $uarg"
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
