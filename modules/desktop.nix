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
  hardware.logitech.wireless.enable = true;  # Für Solaar - Logitech Wireless-Geräte Support
  services.power-profiles-daemon.enable = true;

  # Syncthing - Datei-Synchronisation
  services.syncthing = {
    enable = true;
    user = "mauschel";
    dataDir = "/home/mauschel/Documents";    # Standardverzeichnis für Syncthing-Daten
    configDir = "/home/mauschel/.config/syncthing";   # Konfigurationsverzeichnis
    openDefaultPorts = true;  # Öffnet Ports 8384 (Web UI) und 22000 (Sync)
    settings = {
      gui = {
        # Web-Interface auf localhost:8384
        enabled = true;
        insecureSkipHostcheck = false;
      };
      options = {
        urAccepted = -1;  # Keine Nutzungsstatistiken senden
        relaysEnabled = true;  # Relay-Server für NAT-Traversal nutzen
      };
    };
  };

  # virtualisation.docker.enable = true;  # Deaktiviert zugunsten von Podman in container.nix

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    firefox
    direnv
    solaar
    vscode.fhs
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
    libreoffice
    onlyoffice-bin
    # CopyQ mit XWayland-Wrapper für Wayland-Kompatibilität
    (pkgs.writeShellScriptBin "copyq" ''
      exec env QT_QPA_PLATFORM=xcb ${pkgs.copyq}/bin/copyq "$@"
    '')
    conky
  ];

  # GNOME hat seinen eigenen Portal-Backend
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
}
