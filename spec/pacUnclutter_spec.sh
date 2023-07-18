# vi: et ts=2 sw=2

Describe "pacUnclutter.sh"
  Include ./pacUnclutter.sh

  Describe "create_dialog_items_array()"
    pacman() {
      echo "Name  : shellspec"
      echo "Size  : 300.37 KiB"
      echo "Name  : man-db"
      echo "Size  : 3.47 MiB"
      echo "Name  : vim"
      echo "Size  : 55.93 MiB"
    }

    It "displays each package sorted by name"
      When call create_dialog_items_array items name man shellspec vim
      The value "${#items[@]}" should eq 9
      The value "${items[0]}" should eq "man-db"
      The value "${items[1]}" should eq "man-db (3.47MiB)"
      The value "${items[2]}" should eq "off"
      The value "${items[3]}" should eq "shellspec"
      The value "${items[4]}" should eq "shellspec (300.37KiB)"
      The value "${items[5]}" should eq "off"
      The value "${items[6]}" should eq "vim"
      The value "${items[7]}" should eq "vim (55.93MiB)"
      The value "${items[8]}" should eq "off"
    End

    It "displays each package sorted by size"
      When call create_dialog_items_array items size man shellspec vim
      The value "${#items[@]}" should eq 9
      The value "${items[0]}" should eq "vim"
      The value "${items[1]}" should eq "vim (55.93MiB)"
      The value "${items[2]}" should eq "off"
      The value "${items[3]}" should eq "man-db"
      The value "${items[4]}" should eq "man-db (3.47MiB)"
      The value "${items[5]}" should eq "off"
      The value "${items[6]}" should eq "shellspec"
      The value "${items[7]}" should eq "shellspec (300.37KiB)"
      The value "${items[8]}" should eq "off"
    End

    It "should deselect given packages"
      ARGUMENT_SELECT_ALL=1
      declare -A ARGUMENT_SELECTION
      ARGUMENT_SELECTION[shellspec]=off
      ARGUMENT_SELECTION[vim]=off

      When call create_dialog_items_array items name man shellspec vim
      The value "${#items[@]}" should eq 9
      The value "${items[0]}" should eq "man-db"
      The value "${items[1]}" should eq "man-db (3.47MiB)"
      The value "${items[2]}" should eq "on"
      The value "${items[3]}" should eq "shellspec"
      The value "${items[4]}" should eq "shellspec (300.37KiB)"
      The value "${items[5]}" should eq "off"
      The value "${items[6]}" should eq "vim"
      The value "${items[7]}" should eq "vim (55.93MiB)"
      The value "${items[8]}" should eq "off"
    End

    It "should select given packages"
      declare -A ARGUMENT_SELECTION
      ARGUMENT_SELECTION[shellspec]=on
      ARGUMENT_SELECTION[vim]=on

      When call create_dialog_items_array items name man shellspec vim
      The value "${#items[@]}" should eq 9
      The value "${items[0]}" should eq "man-db"
      The value "${items[1]}" should eq "man-db (3.47MiB)"
      The value "${items[2]}" should eq "off"
      The value "${items[3]}" should eq "shellspec"
      The value "${items[4]}" should eq "shellspec (300.37KiB)"
      The value "${items[5]}" should eq "on"
      The value "${items[6]}" should eq "vim"
      The value "${items[7]}" should eq "vim (55.93MiB)"
      The value "${items[8]}" should eq "on"
    End

    It "should select all packages"
      ARGUMENT_SELECT_ALL=1

      When call create_dialog_items_array items name man shellspec vim
      The value "${#items[@]}" should eq 9
      The value "${items[0]}" should eq "man-db"
      The value "${items[1]}" should eq "man-db (3.47MiB)"
      The value "${items[2]}" should eq "on"
      The value "${items[3]}" should eq "shellspec"
      The value "${items[4]}" should eq "shellspec (300.37KiB)"
      The value "${items[5]}" should eq "on"
      The value "${items[6]}" should eq "vim"
      The value "${items[7]}" should eq "vim (55.93MiB)"
      The value "${items[8]}" should eq "on"
    End
  End
End
