# `modules/desktop.nix` – Desktop-Rolle
#
# Wofür diese Datei da ist:
#
# - Alle GUI/Workstation-Themen, die *mehrere* Desktop‑Hosts betreffen: Display‑Manager, Desktop‑Environment, Bluetooth, Power‑Daemon, Docker, Dev‑Tools.
#
# Kommentare & Hinweise:
# - GNOME via GDM aktiviert. Alternative DEs (KDE, sway, hyprland) könnten hier als Optionen auswählbar gemacht werden.
# - `virtualisation.docker.enable = true;` + `users.groups.docker.members` – gut für Dev‑Workstations. Für Server separat halten.
# - `environment.systemPackages` hier nur für *Desktop-spezifische* Tools nutzen. Allgemeines besser in `base.nix`.

{ pkgs, ... }:
{
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true; # Deaktiviert für Hyprland

  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;

  virtualisation.docker.enable = true;

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    firefox
    direnv
    vscode
    brave
    thunderbird
    terminator
    blender
    obsidian
    persepolis
    uget-integrator
    mplayer
    tor-browser
    openvpn
  ];

  # GNOME hat seinen eigenen Portal-Backend
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
}
