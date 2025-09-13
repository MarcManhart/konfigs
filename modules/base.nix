# Wofür diese Datei da ist:
#
# - Globale, host‑unabhängige Grundeinstellungen (Locale, Timezone, SSH, Firewall, GC, unfree‑Allow, Standardpakete, Login‑Shell …).
#
# Kommentare & Hinweise:
# - `system.stateVersion = "25.05";` an die tatsächliche Release‑Basis koppeln – NICHT unreflektiert erhöhen.
# - `networking.useDHCP = lib.mkDefault true;` ist klassisch; bei komplexeren Netzwerken evtl. NetworkManager‑Konfiguration zentral hier.
# - SSH ohne Passwort, Agent an, Firewall an – solide Defaults.
# - Achte bei `nix.gc.automatic`/`dates`/`options` (in deinem Ausschnitt durch `...` gekürzt) auf sinnvolle Intervalle.

{ lib, pkgs, ... }:
{
  i18n.defaultLocale = "de_DE.UTF-8";
  time.timeZone = "Europe/Berlin";

  # NetworkManager aktivieren
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  programs.ssh.startAgent = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  ################################################
  # Flatpack
  ################################################
  # services.flatpak = {
  #   enable = true;

  #   # Flathub als Quelle hinzufügen (einmalig, deklarativ)
  #   remotes = [
  #     {
  #       name = "flathub";
  #       location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
  #     }
  #   ];

  #   # Systemweit zu installierende Flatpak-Apps (per App-ID)
  #   packages = [
  #     "gnome-tweaks"
  #   ];

  #   # Optional, aber praktisch:
  #   update.onActivation = true; # Aktualisiert Flatpaks bei jedem switch
  #   uninstallUnmanaged = true; # Entfernt manuell installierte, nicht deklarierte Flatpaks
  # };

  ################################################
  # System Packages
  ################################################
  environment.systemPackages = with pkgs; [
    vim
    git
    git-lfs
    vlc
    htop
    curl
    wget
    jq
    tree
    nodejs_22
  ];

  fonts.packages =
    with pkgs;
    [

    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # NordVPN Firewall-Einstellung
  networking.firewall.checkReversePath = false;  # Notwendig für VPN-Clients
}
