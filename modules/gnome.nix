{ config, pkgs, ... }:
{
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Fingerabdruckscanner
  security.pam.services.gdm.fprintAuth = true;

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.user-themes
    gnomeExtensions.mock-tray

    # NetworkManager OpenVPN Support für GNOME
    networkmanager-openvpn
  ];
}
