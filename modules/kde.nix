{ config, pkgs, lib, ... }:
{
  # KDE Plasma Desktop aktivieren
  services.xserver.enable = true;
  services.xserver.xkb.layout = "de";
  services.xserver.xkb.variant = "";
  services.displayManager.sddm.enable = lib.mkForce true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE Connect für Phone Integration
  programs.kdeconnect.enable = true;

  # Partition Manager
  programs.partition-manager.enable = true;

  # SSH Askpass auf KDE's ksshaskpass setzen (überschreibt GNOME's seahorse)
  programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

  # KDE Pakete
  environment.systemPackages = with pkgs; [
    # KDE Utilities
    kdePackages.kate
    kdePackages.ark
    kdePackages.kcalc
    kdePackages.spectacle
    kdePackages.dolphin
    kdePackages.konsole
    kdePackages.gwenview
    kdePackages.okular
    kdePackages.plasma-browser-integration
    kdePackages.kdeplasma-addons
    kdePackages.kwalletmanager
    kdePackages.filelight
    kdePackages.partitionmanager
    kdePackages.kcolorchooser
    
    # KDE Entwicklung (optional)
    # kdePackages.kdevelop
    # kdePackages.kate
    
    # KDE Multimedia
    kdePackages.elisa
    kdePackages.kdenlive
    
    # System Tools
    kdePackages.ksystemlog
    kdePackages.kinfocenter
    kdePackages.plasma-systemmonitor
    
    # Themes und Anpassung
    kdePackages.plasma-integration
    kdePackages.breeze-gtk
    kdePackages.breeze-icons
  ];
}
