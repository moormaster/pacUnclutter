#!/bin/bash
# vi: et ts=2 sw=2

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
  echo -e "\t-u | --uninstall"
  echo -e "\t\tUninstall packages without showing a dialog"
  echo -e ""
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
  local items=("$@")

  for item in "${items[@]}"
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

    local size=$( LANG=C pacman -Qii $item | grep "Installed Size" | grep -P -o '\d.*' )

    arr+=($item)
    arr+=("$item ($size)")
    arr+=($selected)
  done
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
    declare -a packages_to_remove
    create_selected_packages_array packages_to_remove $( find_superfluous_packages )

    if [ ${#packages_to_remove} -eq 0 ]
    then
      echo "No unneeded packages found or nothing selected"
      exit 0
    fi

    sudo pacman -R "${packages_to_remove[@]}" --noconfirm "${ARGUMENTS_PACMAN[@]}"
  else
    declare -a dialog_items
    create_dialog_items_array dialog_items $( find_superfluous_packages )

    if [ ${#dialog_items} -eq 0 ]
    then
      echo "No unneeded packages found"
      exit 0
    fi

    local selection
    if selection=$( 
      dialog --no-tags --checklist "Remove unneeded packages" 24 72 20 "${dialog_items[@]}" 3>&1 1>&2 2>&3
    )
    then
      if [ "${selection}" == "" ]
      then
        echo "Nothing selected"
        exit 0
      fi

      sudo pacman -R ${selection} "${ARGUMENTS_PACMAN[@]}"
    else
      echo "Aborted"
      exit 1
    fi
  fi
}

main "$@"
