#!/bin/bash
# vi: et ts=2 sw=2

ARGUMENT_ORDER="name"
declare -A ARGUMENT_SELECTION
ARGUMENT_SEARCH_PACKAGE_TYPE="unneeded"
ARGUMENT_SELECT_ALL=0
ARGUMENT_UNINSTALL=0
ARGUMENTS_PACMAN=()

# make pacUnclutter work with MSYS2 which does not have sudo
SUDO_COMMAND="$( which sudo 2> /dev/null )" || true

usage() {
  echo -e "$0 [options] -- [additional arguments for pacman]"
  echo -e "Options:"
  echo -e "\t-a | --select-all"
  echo -e "\t\tSelect all packages"
  echo -e "\t-d <packagename> | --deselect <packagename>"
  echo -e "\t\tDeselect a package (when using --select-all)"
  echo -e "\t-s <packagename> | --select <packagename>"
  echo -e "\t\tPre select packages"
  echo -e "\t-o <order-by>| --order <order-by>"
  echo -e "\t\tOrder by either \"name\" or \"size\""
  echo -e "\t-t <type> | --search-package-type <type>"
  echo -e "\t\tType of packages to search for."
  echo -e "\t\t\t\"unneeded\" (default)"
  echo -e "\t\t\t\tsearch for installed packages that are not needed anymore"
  echo -e "\t\t\t\"installed\""
  echo -e "\t\t\t\tsearch for all packages that are currently installed"
  echo -e "\t-u | --uninstall"
  echo -e "\t\tUninstall packages without showing a dialog"
  echo -e ""
  echo -e "Example - show superfluous packages ordered by size:"
  echo -e "\t$0 -o size"
  echo -e "Example - show installed packages ordered by size:"
  echo -e "\t$0 -t installed -o size"
  echo -e "Example - show superfluous packages and preselect all in the dialog:"
  echo -e "\t$0 -a"
  echo -e "Example - show superfluous packages and pre-select specific ones:"
  echo -e "\t$0 -a -s cmake -s gdb"
  echo -e "Example - remove all superfluous packages without asking:"
  echo -e "\t$0 -u -a"
}

error() {
  echo "$@" 1>&2
}

parse_arguments() {
  while [ $# -gt 0 ]
  do
    case "$1" in
      "-a" | "--select-all")
        ARGUMENT_SELECT_ALL=1
        shift 1
        ;;

      "-d" | "--deselect")
        if [ "$2" == "" ]
        then
          error "Parameter $1 expects a <packagename> argument"
          return 1
        fi
        ARGUMENT_SELECTION+=("$2" off)
        shift 2
        ;;
  
      "-s" | "--select")
        if [ "$2" == "" ]
        then
          error "Parameter $1 expects a <packagename> argument"
          return 1
        fi
        ARGUMENT_SELECTION+=("$2" on)
        shift 2
         ;;
  
      "-o" | "--order")
        if [ "$2" == "" ] ||
          ( [ "$2" != "name" ] &&
            [ "$2" != "size" ] )
        then
          error "Parameter $1 expects an <order-by> argument, either \"name\" or \"size\""
          return 1
        fi
        ARGUMENT_ORDER=$2
        shift 2
        ;;
  
      "-t" | "--search-package-type")
        if [ "$2" == "" ] ||
          ( [ "$2" != "installed" ] &&
            [ "$2" != "unneeded" ] )
        then
          error "Parameter $1 expects a <type> argument, either \"installed\" or \"unneeded\""
          return 1
        fi
        ARGUMENT_SEARCH_PACKAGE_TYPE=$2
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
        shift 1
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

find_installed_packages() {
  pacman -Qq
}

search_for_packages() {
  case "${ARGUMENT_SEARCH_PACKAGE_TYPE}" in
    "installed")
      find_installed_packages
      ;;
    "unneeded")
      find_superfluous_packages
      ;;
    *)
      error "Unknown package type: ${ARGUMENT_SEARCH_PACKAGE_TYPE}"
      return 1
      ;;
  esac
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
    if [ "${ARGUMENT_SELECTION[$item]}" == "" ] && [ $ARGUMENT_SELECT_ALL -ne 1 ] 
    then
      continue;
    fi

    if [ "${ARGUMENT_SELECTION[$item]}" != "" ] &&  [ "${ARGUMENT_SELECTION[$item]}" != "on" ]
    then
      continue
    fi
    
    arr+=($item)
  done
}

check_and_warn_if_sudo_not_present() {
    [ "${SUDO_COMMAND}" == "" ] && error WARNING: sudo not installed. Will attempt to run pacman commands without usind sudo. 
}

unattended_uninstall() {
    declare -a packages_to_remove
    create_selected_packages_array packages_to_remove $( search_for_packages )

    if [ ${#packages_to_remove} -eq 0 ]
    then
      echo "No unneeded packages found or nothing selected"
      return 0
    fi

    check_and_warn_if_sudo_not_present
    ${SUDO_COMMAND} pacman -R "${packages_to_remove[@]}" --noconfirm "${ARGUMENTS_PACMAN[@]}"
}

dialog_for_removing_packages() {
    declare -a dialog_items
    create_dialog_items_array dialog_items ${ARGUMENT_ORDER} $( search_for_packages ) || return 1

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

      check_and_warn_if_sudo_not_present
      ${SUDO_COMMAND} pacman -R ${selection} "${ARGUMENTS_PACMAN[@]}"
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
