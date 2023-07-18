#!/bin/bash
# vi: et ts=2 sw=2

ARGUMENT_ORDER="name"
declare -A ARGUMENT_SELECTION
ARGUMENT_SELECT_ALL=0
ARGUMENT_UNINSTALL=0
ARGUMENTS_PACMAN=()

usage() {
  echo -e "$0 [options] -- [additional arguments for pacman]"
  echo -e "Options:"
  echo -e "\t-d <packagename> | --deselect <packagename>"
  echo -e "\t\tDeselect a package (when using --select-all)"
  echo -e "\t-s <packagename> | --select <packagename>"
  echo -e "\t\tPre select packages"
  echo -e "\t-a | --select-all"
  echo -e "\t\tSelect all (uneeded) packages"
  echo -e "\t-o <order-by>| --order <order-by>"
  echo -e "\t\tOrder by either \"name\" or \"size\""
  echo -e "\t-u | --uninstall"
  echo -e "\t\tUninstall packages without showing a dialog"
  echo -e ""
  echo -e "Example - ask which packages to remove ordered by size:"
  echo -e "\t$0 -o size"
  echo -e "Example - ask which packages to remove and pre-select all:"
  echo -e "\t$0 -a"
  echo -e "Example - ask which packages to remove and pre-select specific ones:"
  echo -e "\t$0 -a -s cmake -s gdb"
  echo -e "Example - remove everything unneeded without asking:"
  echo -e "\t$0 -u -a"
}

error() {
  echo "$@" 1>&2
}

parse_arguments() {
  while [ $# -gt 0 ]
  do
    case "$1" in
      "-d" | "--deselect")
        ARGUMENT_SELECTION+=("$2" off)
        shift 2
        ;;
  
      "-s" | "--select")
        ARGUMENT_SELECTION+=("$2" on)
        shift 2
         ;;
  
      "-a" | "--select-all")
        ARGUMENT_SELECT_ALL=1
        shift 1
        ;;

      "-o" | "--order")
        ARGUMENT_ORDER=$2
        shift 2
        ;;
  
      "-u" | "--uninstall")
        ARGUMENT_UNINSTALL=1
        shift 1
        ;;

      "-h" | "--help")
        return 1
        ;;

      "--")
        ARGUMENTS_PACMAN=("$@")
        shift $#
        ;;
  
      *)
        error "Unknown argument: $1"
        return 1
        ;;
    esac
  done
}

find_superfluous_packages() {
  pacman -Qtdq
}

create_dialog_items_array() {
  declare -n arr=$1
  shift 1

  local sortlocale=${LANG}
  local sortoptions;
  case "$1" in
    "name")
      # sort below list of lines by field 2 (=name)
      sortoptions=("-k" "2")
      ;;

    "size")
      # sort below list of lines by field 3 (=size)
      sortlocale="C"
      sortoptions=("-k" "3rh,3")
      ;;

    *)
      error "create_dialog_items_array() called with invalid sort key: $1"
      return 1
  esac
  shift 1

  # convert list of packages into sorted list of dialog items
  local packages_and_sizes="$( LANG=C pacman -Qii "$@" | grep -Po '(Name\s+:\s+\K.+|Size\s+:\s+\K.+)' | sed -e 's/ //' )"
  local itemlines=$(
    while read item; read size
    do
      local selected=${ARGUMENT_SELECTION[$item]}
      if [ "$selected" == "" ]
      then
        if [ ${ARGUMENT_SELECT_ALL} -eq 1 ]
        then
          selected=on
        else
          selected=off
        fi
      fi

      echo $selected $item $size
    done <<< "${packages_and_sizes}" | LC_ALL=${sortlocale} sort "${sortoptions[@]}"
  )

  # convert each line into a triple (tag, item, selected) of arguments for dialog utility
  while read selected item size
  do
    if [ "$item" == "" ]
    then
      continue
    fi

    arr+=($item)
    arr+=("$item ($size)")
    arr+=($selected)
  done <<< $itemlines
}

create_selected_packages_array() {
  declare -n arr=$1
  shift 1
  local items=("$@")

  for item in "${items[@]}"
  do
    if [ ${ARGUMENT_SELECT_ALL} -ne 1 ] && [ "${ARGUMENT_SELECTION[$item]}" != "on" ]
    then
      continue
    fi

    arr+=($item)
  done
}

unattended_uninstall() {
    declare -a packages_to_remove
    create_selected_packages_array packages_to_remove $( find_superfluous_packages )

    if [ ${#packages_to_remove} -eq 0 ]
    then
      echo "No unneeded packages found or nothing selected"
      return 0
    fi

    sudo pacman -R "${packages_to_remove[@]}" --noconfirm "${ARGUMENTS_PACMAN[@]}"
}

dialog_for_removing_packages() {
    declare -a dialog_items
    create_dialog_items_array dialog_items ${ARGUMENT_ORDER} $( find_superfluous_packages ) || return 1

    if [ ${#dialog_items[@]} -eq 0 ]
    then
      error "No unneeded packages found"
      return 1
    fi

    local selection
    dialog --erase-on-exit --no-tags --checklist "Remove unneeded packages" 0 0 0 "${dialog_items[@]}" 3>&1 1>&2 2>&3
}

main() {
  if ! parse_arguments "$@"
  then
    usage
    exit 1
  fi

  if ! which dialog > /dev/null
  then
    error "dialog is not installed!"
    exit 1
  fi

  if [ ${ARGUMENT_UNINSTALL} -eq 1 ]
  then
    unattended_uninstall
  else
    local selection
    if selection=$( dialog_for_removing_packages )
    then
      if [ "${selection}" == "" ]
      then
        echo "Nothing selected"
        exit 0
      fi

      sudo pacman -R ${selection} "${ARGUMENTS_PACMAN[@]}"
    else
      error "Aborted"
      exit 1
    fi
  fi
}

if [ "${BASH_ARGV0}" == "${BASH_SOURCE[0]}" ]
then
  main "$@"
fi
