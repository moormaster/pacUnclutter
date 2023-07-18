# vi: et ts=2 sw=2

Describe "pacUnclutter.sh"
  pacman() {
    echo "Name  : shellspec"
    echo "Size  : 300.37 KiB"
    echo "Name  : man-db"
    echo "Size  : 3.47 MiB"
    echo "Name  : vim"
    echo "Size  : 55.93 MiB"
  }

  Include ./pacUnclutter.sh

  Describe "create_dialog_items_array()"
    It "displays each package sorted by name"
      When call create_dialog_items_array items_returned name man-db shellspec vim
      The value "${#items_returned[@]}" should eq 9
      The value "${items_returned[0]}" should eq "man-db"
      The value "${items_returned[1]}" should eq "man-db (3.47MiB)"
      The value "${items_returned[2]}" should eq "off"
      The value "${items_returned[3]}" should eq "shellspec"
      The value "${items_returned[4]}" should eq "shellspec (300.37KiB)"
      The value "${items_returned[5]}" should eq "off"
      The value "${items_returned[6]}" should eq "vim"
      The value "${items_returned[7]}" should eq "vim (55.93MiB)"
      The value "${items_returned[8]}" should eq "off"
    End

    It "displays each package sorted by size"
      When call create_dialog_items_array items_returned size man-db shellspec vim
      The value "${#items_returned[@]}" should eq 9
      The value "${items_returned[0]}" should eq "vim"
      The value "${items_returned[1]}" should eq "vim (55.93MiB)"
      The value "${items_returned[2]}" should eq "off"
      The value "${items_returned[3]}" should eq "man-db"
      The value "${items_returned[4]}" should eq "man-db (3.47MiB)"
      The value "${items_returned[5]}" should eq "off"
      The value "${items_returned[6]}" should eq "shellspec"
      The value "${items_returned[7]}" should eq "shellspec (300.37KiB)"
      The value "${items_returned[8]}" should eq "off"
    End

    It "should deselect given packages"
      ARGUMENT_SELECT_ALL=1
      declare -A ARGUMENT_SELECTION
      ARGUMENT_SELECTION[shellspec]=off
      ARGUMENT_SELECTION[vim]=off

      When call create_dialog_items_array items_returned name man-db shellspec vim
      The value "${#items_returned[@]}" should eq 9
      The value "${items_returned[0]}" should eq "man-db"
      The value "${items_returned[1]}" should eq "man-db (3.47MiB)"
      The value "${items_returned[2]}" should eq "on"
      The value "${items_returned[3]}" should eq "shellspec"
      The value "${items_returned[4]}" should eq "shellspec (300.37KiB)"
      The value "${items_returned[5]}" should eq "off"
      The value "${items_returned[6]}" should eq "vim"
      The value "${items_returned[7]}" should eq "vim (55.93MiB)"
      The value "${items_returned[8]}" should eq "off"
    End

    It "should select given packages"
      declare -A ARGUMENT_SELECTION
      ARGUMENT_SELECTION[shellspec]=on
      ARGUMENT_SELECTION[vim]=on

      When call create_dialog_items_array items_returned name man-db shellspec vim
      The value "${#items_returned[@]}" should eq 9
      The value "${items_returned[0]}" should eq "man-db"
      The value "${items_returned[1]}" should eq "man-db (3.47MiB)"
      The value "${items_returned[2]}" should eq "off"
      The value "${items_returned[3]}" should eq "shellspec"
      The value "${items_returned[4]}" should eq "shellspec (300.37KiB)"
      The value "${items_returned[5]}" should eq "on"
      The value "${items_returned[6]}" should eq "vim"
      The value "${items_returned[7]}" should eq "vim (55.93MiB)"
      The value "${items_returned[8]}" should eq "on"
    End

    It "should select all packages"
      ARGUMENT_SELECT_ALL=1

      When call create_dialog_items_array items_returned name man-db shellspec vim
      The value "${#items_returned[@]}" should eq 9
      The value "${items_returned[0]}" should eq "man-db"
      The value "${items_returned[1]}" should eq "man-db (3.47MiB)"
      The value "${items_returned[2]}" should eq "on"
      The value "${items_returned[3]}" should eq "shellspec"
      The value "${items_returned[4]}" should eq "shellspec (300.37KiB)"
      The value "${items_returned[5]}" should eq "on"
      The value "${items_returned[6]}" should eq "vim"
      The value "${items_returned[7]}" should eq "vim (55.93MiB)"
      The value "${items_returned[8]}" should eq "on"
    End
  End

  Describe "create_selected_packages_array"
    It "should return all packages but the deselected ones"
      ARGUMENT_SELECT_ALL=1
      declare -A ARGUMENT_SELECTION
      ARGUMENT_SELECTION[shellspec]=off
      ARGUMENT_SELECTION[vim]=off

      When call create_selected_packages_array items_returned man-db shellspec vim
      The value "${#items_returned[@]}" should eq 1
      The value "${items_returned[0]}" should eq "man-db"
    End

    It "should return selected packages"
      declare -A ARGUMENT_SELECTION
      ARGUMENT_SELECTION[shellspec]=on
      ARGUMENT_SELECTION[vim]=on

      When call create_selected_packages_array items_returned man-db shellspec vim
      The value "${#items_returned[@]}" should eq 2
      The value "${items_returned[0]}" should eq "shellspec"
      The value "${items_returned[1]}" should eq "vim"
    End

    It "should return all packages"
      ARGUMENT_SELECT_ALL=1

      When call create_selected_packages_array items_returned man-db shellspec vim
      The value "${#items_returned[@]}" should eq 3
      The value "${items_returned[0]}" should eq "man-db"
      The value "${items_returned[1]}" should eq "shellspec"
      The value "${items_returned[2]}" should eq "vim"
    End
  End
End
