# PacUnclutter
An interactive console helper to remove unneeded packages in ArchLinux.

![](screen.png)

## Usage

```
$ ./pacUnclutter.sh --help
./pacUnclutter.sh [options] -- [additional arguments for pacman]
Options:
	-d <packagename> | --deselect <packagename>
		Deselect a package (when using --select-all)
	-s <packagename> | --select <packagename>
		Pre select packages
	-a | --select-all
		Select all (uneeded) packages
	-u | --uninstall
		Uninstall packages without showing a dialog

Example - ask which packages to remove and pre-select all:
	./pacUnclutter.sh -a
Example - ask which packages to remove and pre-select specific ones:
	./pacUnclutter.sh -a -s cmake -s gdb
Example - remove everything unneeded without asking:
	./pacUnclutter.sh -u -a
```

## Dependencies

```
sudo pacman -S --needed dialog
``` 

- [dialog](https://archlinux.org/packages/core/x86_64/dialog/)
- ([pacman](https://archlinux.org/packages/core/x86_64/pacman/))