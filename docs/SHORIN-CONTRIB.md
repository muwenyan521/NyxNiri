# Shorin-contrib Components

NyxNiri includes the executable command components from
`SHORiN-KiWATA/shorin-contrib` at commit
`c6a768a045a512148f5d99f90190a503f9b5037f`.

They are deployed from `configs/bin/` to `~/.local/bin/` and remain separate
from the desktop configuration tree. Existing NyxNiri names are preserved;
the imported commands are additive unless the user explicitly invokes them.

Included commands:

```text
battery-care       checkallupdates    change-grub-theme
compressvideos     getown             lsi
media-info         mirror-update      pac
pacd               pacr               pacrrr
pak                preview            procusage
quickload          quicksave          searchmodels
shorin-clean       sysup              timer
video2gif          vir
```

Commands that write system state, change ownership, manage snapshots, or
modify package sources keep their upstream elevation and confirmation
behavior. The NyxNiri installer only copies the files and sets executable
permissions; it does not run them during installation.
