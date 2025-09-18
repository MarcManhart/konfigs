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
      megasync
      tor-browser
      openvpn # Alternative für VPN-Verbindungen
      _1password-gui
      _1password-cli
      mplayer
      uget
      uget-integrator
      spotify
      spotify-player
    ];
  };

  # Für Spotify Local discovery
  networking.firewall.allowedTCPPorts = [ 57621 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

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
