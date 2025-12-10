
{ config, pkgs, lib, ... }:

{
  ################################################
  # Docker Container-Virtualisierung
  ################################################

  # Docker-Daemon aktivieren
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    # Speicherplatz automatisch aufräumen
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };

  # Container-Tools und Docker-Compose
  environment.systemPackages = with pkgs; [
    docker-compose  # Docker Compose für Multi-Container-Anwendungen
    dive            # Tool zur Analyse von Container-Images
    lazydocker      # Terminal UI für Docker
  ];

  # Benutzer zur docker Gruppe hinzufügen (wichtig!)
  # Ersetze "mauschel" mit deinem Benutzernamen falls anders
  users.users.mauschel = {
    extraGroups = [ "docker" ];
  };

  # Docker CLI Vervollständigung für Bash und Zsh
  programs.bash.completion.enable = true;
  programs.zsh.enableCompletion = true;
} 