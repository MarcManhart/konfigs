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
    gnomeExtensions.gsconnect

    # NetworkManager OpenVPN Support für GNOME
    networkmanager-openvpn

    # gnome-screenshot # altes (eigentlich von gnome-shell abgelöstes) Screenshot-Tool als Workaround für shortcut in home.nix
    (flameshot.override { enableWlrSupport = true; })
  ];

  # GSConnect benötigt diese Ports für die Gerätekommunikation
  networking.firewall.allowedTCPPortRanges = [
    { from = 1716; to = 1764; }  # KDE Connect / GSConnect TCP ports
  ];
  networking.firewall.allowedUDPPortRanges = [
    { from = 1716; to = 1764; }  # KDE Connect / GSConnect UDP ports
  ];
}
