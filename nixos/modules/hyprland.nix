{ config, pkgs, ... }:
{
  # GDM wird bereits in desktop.nix konfiguriert
  services.xserver.displayManager.gdm.wayland = true;

  programs.hyprland.enable = true;

  # Wichtige Tools für „erste Lebenszeichen“
  environment.systemPackages = with pkgs; [
    kitty
    waybar
    hyprpaper # Wallpaper-Setter
    networkmanagerapplet # bringt auch nm-connection-editor mit
    networkmanager_dmenu # schlankes TUI für Verbindungen
    rofi-wayland # <- wichtig für networkmanager_dmenu
    lxqt.lxqt-policykit # Polkit-Agent
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    wl-clipboard
    grim
    slurp
    hypridle
    hyprlock
    swappy # Screenshots/Clipboard (nice to have)
    wdisplays
  ];

  # Polkit-Agent als User-Service (wichtig!)
  # systemd.user.services.polkit-agent = {
  #   Unit.Description = "LXQt PolicyKit agent";
  #   Service.ExecStart = "${pkgs.lxqt.lxqt-policykit}/libexec/lxqt-policykit-agent";
  #   Install.WantedBy = [ "graphical-session.target" ];
  # };

  # Optional: networkmanager_dmenu auf rofi festnageln
  environment.sessionVariables.NMD_MENU = "rofi";

  #bluetooth
  hardware.bluetooth.enable = true; # BlueZ aktivieren
  hardware.bluetooth.settings = {
    # optional, gute Defaults
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };
  services.blueman.enable = true; # Blueman (Manager + Applet)

  # Portale: ohne die zicken Browser, Flatpaks, File-Picker etc.
  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-hyprland
    pkgs.xdg-desktop-portal-gtk
  ];

  # OpenGL / VA-API (generisch; NVIDIA siehe unten)
  hardware.graphics.enable = true;

  # Electron/Chromium auf Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
