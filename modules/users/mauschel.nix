# `modules/users/mauschel.nix` – System-User
#
# Wofür diese Datei da ist:
#
# - Systembenutzer & Gruppen, SSH‑Keys, Passwort‑Policy. Nicht zu verwechseln mit *Home‑Manager* (Userland‑Pakete & Dotfiles).
#
# Kommentare & Hinweise:
# - `hashedPassword = "*";` → keine Passwort‑Logins. Login via SSH‑Key – sicher.
# - `extraGroups` passend zu Desktop‑/Docker‑Nutzung. Prüfe `networkmanager` vs. systemweite Netzprofile.
# - Den öffentlichen SSH‑Key regelmäßig rotieren und ggf. zusätzlich FIDO2/ed25519‑sk nutzen.

{ pkgs, dconf, ... }:
{
  users.users.mauschel = {
    isNormalUser = true;
    description = "Mauschel";
    extraGroups = [
      "wheel"
      "docker"
      "video"
      "audio"
      "networkmanager"
      "libvirtd"
    ];
    hashedPassword = "*"; # kein Login per Passwort, nur SSH-Key
    packages = with pkgs; [
      slack
      discord
      obs-studio
      megasync
      tor-browser
      openvpn # Alternative für VPN-Verbindungen
      _1password-gui
      _1password-cli
      mplayer
      uget
      uget-integrator
      spotify
      (spotify-player.override {
        withImage = true;
      })
      localsend
      cava
      lazygit
      bruno
      parted
      veracrypt
      direnv
      nix-direnv
      starship
      sassc
      gnome-themes-extra
      gtk-engine-murrine
      (chromium.override {
        enableWideVine = true;
      })
      (pkgs.writeShellApplication {
        name = "claude";
        runtimeInputs = [ pkgs.nodejs_22 ]; # oder _20/_18 je nach Setup
        text = ''
          #!/usr/bin/env bash
          exec npx -y @anthropic-ai/claude-code "$@"
        '';
      })
    ];
  };

  # Für Spotify Local discovery
  networking.firewall.allowedTCPPorts = [ 57621 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

  ######################################################
  # ClamAV Antivirus Scanner
  ######################################################
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
    updater.interval = "daily"; # Automatische Updates der Virendefinitionen
    updater.frequency = 12; # Updates alle 12 Stunden
  };

  # ClamAV Scanner-Einstellungen
  systemd.services.clamav-scan = {
    description = "ClamAV virus scan";
    after = [ "clamav-freshclam.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.clamav}/bin/clamscan --recursive --infected --log=/var/log/clamav/scan.log /home";
      User = "clamav";
      Group = "clamav";
    };
  };

  # Wöchentlicher Scan-Timer
  systemd.timers.clamav-scan = {
    description = "Schedule ClamAV scan";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly"; # Wöchentlicher Scan, kann angepasst werden
      Persistent = true;
    };
  };

  # Log-Verzeichnis für ClamAV
  systemd.tmpfiles.rules = [
    "d /var/log/clamav 0755 clamav clamav -"
  ];

  ######################################################
  # 1Password
  ######################################################
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "mauschel" ];
  };
}
