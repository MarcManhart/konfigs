
{ config, pkgs, lib, ... }:

{
  ################################################
  # Docker & Podman Container-Virtualisierung
  ################################################

  # Docker-Daemon deaktiviert zugunsten von Podman
  # virtualisation.docker = {
  #   enable = true;
  #   enableOnBoot = true;
  #   # Docker-Rootless-Mode für zusätzliche Sicherheit (optional)
  #   # rootless = {
  #   #   enable = true;
  #   #   setSocketVariable = true;
  #   # };
  #   # Speicherplatz automatisch aufräumen
  #   autoPrune = {
  #     enable = true;
  #     dates = "weekly";
  #     flags = [ "--all" ];
  #   };
  # };

  # Podman als Docker-Alternative
  virtualisation.podman = {
    enable = true;
    # Docker-Kompatibilitätsmodus
    dockerCompat = true;
    # Standardnetzwerk-Backend
    defaultNetwork.settings = {
      dns_enabled = true;
    };
    # Automatisches Aufräumen
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };

  # Container-Tools und Docker-Compose
  environment.systemPackages = with pkgs; [
    docker-compose  # Funktioniert mit Podman dank dockerCompat
    podman-compose
    podman-tui      # Terminal UI für Podman (Alternative zu lazydocker)
    podman-desktop  # Grafische Oberfläche für Podman
    dive            # Tool zur Analyse von Container-Images
    # lazydocker    # Nur für echten Docker-Daemon, nicht Podman-kompatibel
    skopeo          # Container-Image-Verwaltung
    buildah         # Container-Build-Tool
  ];

  # Benutzer zur docker Gruppe hinzufügen (wichtig!)
  # Ersetze "mauschel" mit deinem Benutzernamen falls anders
  users.users.mauschel = {
    extraGroups = [ "docker" ];
  };

  # Docker/Podman CLI Vervollständigung für Bash und Zsh
  programs.bash.enableCompletion = true;
  programs.zsh.enableCompletion = true;

  # Docker-Completion wird automatisch durch dockerCompat bereitgestellt
  # Zusätzliche Shell-Aliase für Docker-Kompatibilität
  environment.shellAliases = {
    docker = "podman";
    docker-compose = "podman-compose";
  };
}