
{ config, pkgs, lib, ... }:

{
  ################################################
  # Docker & Podman Container-Virtualisierung
  ################################################

  # Docker-Daemon aktivieren
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    # Docker-Rootless-Mode für zusätzliche Sicherheit (optional)
    # rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
    # Speicherplatz automatisch aufräumen
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };

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
    docker-compose
    podman-compose
    podman-tui      # Terminal UI für Podman
    dive            # Tool zur Analyse von Docker-Images
    lazydocker      # Terminal UI für Docker (bereits in user packages, aber hier zentral)
    skopeo          # Container-Image-Verwaltung
    buildah         # Container-Build-Tool
  ];

  # Benutzer zur docker Gruppe hinzufügen (wichtig!)
  # Ersetze "mauschel" mit deinem Benutzernamen falls anders
  users.users.mauschel = {
    extraGroups = [ "docker" ];
  };
}