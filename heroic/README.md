# Heroic Games Launcher

Heroic Games Launcher runs on this machine as the Flathub Flatpak
`com.heroicgameslauncher.hgl`, installed in user scope.

Install:

    flatpak install --user -y flathub com.heroicgameslauncher.hgl

Start: the "Heroic Games Launcher" icon, or
`flatpak run com.heroicgameslauncher.hgl`.

Games install by default to `~/Games/Heroic`. ARCH.md explains why this
machine uses the Flatpak and not the AppImage; INSTR.md lists the checks.

HD Mod for Heroes of Might and Magic 3 Complete: run `./install_hd_mod.sh`,
then follow INSTR.md, section "HD Mod for the Complete edition".
