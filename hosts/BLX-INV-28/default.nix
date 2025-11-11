######################################################################
# `hosts/BLX-INV-28/default.nix` – Host-spezifische Overrides
######################################################################
# Wofür diese Datei da ist:
#
# - Feintuning für DIESEN Host (Hostname, Bootloader, Kernelwahl, HW-Treiber, Gouvernor etc.).
# - Alles, was *nur* diesen Rechner betrifft – nicht global.
#
# Kommentare & Hinweise:
# - Du pinnst explizit `boot.kernelPackages = pkgs.linuxPackages_6_12;` – das erzwingt Kernel 6.12 für diesen Host.
# - Systemd‑boot + UEFI sind korrekt gesetzt.
# - `services.xserver.videoDrivers = [ "amdgpu" ];` stellt sicher, dass der AMD‑Treiber genutzt wird.
# - Halte diese Datei *schlank*; globale Dinge wandern in `modules/base.nix` oder `modules/desktop.nix`.

{ pkgs, lib, ... }:
{
  system.stateVersion = "25.05";

  # Auf konkreten Kernel pinnen
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Host-spezifisches kommt hier rein (nur so viel wie nötig).
  networking.hostName = "BLX-INV-28";

  # UEFI-Boot mit systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Kernel-Parameter für AMD Suspend/Resume Fix
  boot.kernelParams = [
    "amdgpu.dc=1"           # Display Core aktivieren
    "amdgpu.dpm=1"          # Dynamic Power Management
    "amdgpu.gpu_recovery=1" # GPU Recovery bei Problemen
  ];

  # AMD: Microcode + Grafiktreiber
  hardware.cpu.amd.updateMicrocode = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # für 32-bit OpenGL/Steam/Wine
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
      rocmPackages.clr.icd # OpenCL/ROCr ICD – wichtig fürs Device-Listing
      rocmPackages.rocminfo # "rocminfo" zum Prüfen
      rocmPackages.rocm-smi # Monitoring/Debug
    ];
  };

  # Fingerabdruck-Scanner
  services.fprintd.enable = true; # D-Bus Dienst für Fingerabdrücke
  # PAM: Fingerprint überall gewollt → GDM-Defaults überstimmen
  security.pam.services = {
    # TTY/Console-Login:
    login.fprintAuth = lib.mkForce true;

    # GDM hat eigene PAM-Stacks:
    gdm.fprintAuth = lib.mkForce true;
    gdm-password.fprintAuth = lib.mkForce true;

    # sudo mit Finger:
    sudo.fprintAuth = true;

    # (Optional) polkit-Authentifizierung per Fingerabdruck:
    # "polkit-1".fprintAuth = true;
  };

  # Praktische Tools
  environment.systemPackages = with pkgs; [
    fprintd
    (blender.override {
      hipSupport = true;
      rocmPackages = rocmPackages; # passende ROCm-Variante aus demselben nixpkgs
    })
  ];

  # Sanfter Governor (optional)
  powerManagement.cpuFreqGovernor = "schedutil";

  # AMD GPU Reset nach Suspend (falls Kernel-Params nicht reichen)
  systemd.services.amdgpu-resume-fix = {
    description = "Reset AMD GPU nach Suspend";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kmod}/bin/modprobe -r amdgpu && ${pkgs.kmod}/bin/modprobe amdgpu";
    };
  };

  # NetworkManager: USB-C Dock/Ethernet Fallback auf WiFi
  # Problem: Beim Abziehen des USB-C Docks (mit Ethernet) fehlte die Netzwerkverbindung,
  # da WiFi nicht automatisch aktiviert wurde und GNOME-Settings einfroren.
  # Lösung: Verbindungsprioritäten und Route-Metriken so setzen, dass WiFi parallel
  # läuft und beim Trennen von Ethernet sofort übernimmt.

  # Dispatcher-Script für automatisches WiFi-Aktivierung beim Ethernet-Disconnect
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeText "99-wifi-fallback" ''
        #!/bin/sh
        # Wenn Ethernet getrennt wird, stelle sicher dass WiFi aktiviert ist
        if [ "$2" = "down" ] && [ "$1" = "eth0" ]; then
          logger "NetworkManager: Ethernet disconnected, ensuring WiFi is active"
          ${pkgs.networkmanager}/bin/nmcli connection up "Blinx" || true
        fi
      '';
      type = "basic";
    }
  ];

  # Setze die Verbindungsprioritäten über nmcli nach dem Systemstart
  # (Alternativ: ensureProfiles nutzen, aber das erfordert Secrets-Management)
  systemd.services.networkmanager-connection-priority = {
    description = "Set NetworkManager connection priorities for dock fallback";
    after = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Warte bis NetworkManager bereit ist
      until ${pkgs.networkmanager}/bin/nmcli -t -f STATE general | grep -q 'verbunden\|connected'; do
        sleep 1
      done

      # Setze Prioritäten und Metriken für bestehende Verbindungen
      # WiFi: Priorität 100, Metrik 600 (Fallback)
      if ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show | grep -q '^Blinx$'; then
        ${pkgs.networkmanager}/bin/nmcli connection modify "Blinx" \
          connection.autoconnect-priority 100 \
          ipv4.route-metric 600 || true
      fi

      # Ethernet: Priorität 200, Metrik 100 (bevorzugt)
      if ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show | grep -q '^Kabelgebundene Verbindung 2$'; then
        ${pkgs.networkmanager}/bin/nmcli connection modify "Kabelgebundene Verbindung 2" \
          connection.autoconnect-priority 200 \
          ipv4.route-metric 100 || true
      fi

      # Aktiviere WiFi falls noch nicht verbunden
      if ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show --active | grep -q '^Blinx$'; then
        logger "NetworkManager: WiFi already active"
      else
        logger "NetworkManager: Activating WiFi as fallback"
        ${pkgs.networkmanager}/bin/nmcli connection up "Blinx" || true
      fi
    '';
  };
}
