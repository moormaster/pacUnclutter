# PacUnclutter
An interactive console helper to remove unneeded packages in ArchLinux.

![](screen.png)

## Usage

```
$ ./pacUnclutter.sh --help
./pacUnclutter.sh [options] -- [additional arguments for pacman]
Options:
	-a | --select-all
		Select all packages
	-d <packagename> | --deselect <packagename>
		Deselect a package (when using --select-all)
	-s <packagename> | --select <packagename>
		Pre select packages
	-o <order-by>| --order <order-by>
		Order by either "name" or "size"
	-t <type> | --search-package-type <type>
		Type of packages to search for.
			"unneeded" (default)
				search for installed packages that are not needed anymore
			"installed"
				search for all packages that are currently installed
	-u | --uninstall
		Uninstall packages without showing a dialog

Example - show superfluous packages ordered by size:
	./pacUnclutter.sh -o size
Example - show installed packages ordered by size:
	./pacUnclutter.sh -t installed -o size
Example - show superfluous packages and preselect all in the dialog:
	./pacUnclutter.sh -a
Example - show superfluous packages and pre-select specific ones:
	./pacUnclutter.sh -a -s cmake -s gdb
Example - remove all superfluous packages without asking:
	./pacUnclutter.sh -u -a
```

## Installation

```
sudo pacman -S base-devel --needed
makepkg -si
```

## Dependencies

```
sudo pacman -S --asdeps --needed dialog
``` 

- [dialog](https://archlinux.org/packages/core/x86_64/dialog/)
- ([pacman](https://archlinux.org/packages/core/x86_64/pacman/))
- ([shellspec](https://aur.archlinux.org/packages/shellspec))

## UnitTests

To run the unittests [shellspec](https://aur.archlinux.org/packages/shellspec) must be installed.

```
shellspec -f d
```
