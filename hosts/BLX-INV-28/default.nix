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

  # Kernel-Parameter für AMD Suspend/Resume Fix + WLAN-Stabilität
  boot.kernelParams = [
    "amdgpu.dc=1"                   # Display Core aktivieren
    "amdgpu.dpm=1"                  # Dynamic Power Management
    "amdgpu.gpu_recovery=1"         # GPU Recovery bei Problemen
    "cfg80211.ieee80211_regdom=DE"  # WiFi: Regulatory Domain auf DE setzen (reduziert Roaming-Probleme)
  ];

  ############################################################################
  # MediaTek MT7925 WiFi-Stabilität (PCI ID 14c3:7925)
  ############################################################################
  # Problem (2025-11-26): System-Freezes durch blockierenden WLAN-Treiber
  # Symptome: GNOME unresponsiv, Terminal hängt, nur Hard-Reset hilft
  # Ursache: mt7925e-Treiber blockiert in ieee80211_ifa_changed (mac80211)
  #          bei Power-Save und AP-Roaming (5GHz/6GHz Mesh-Netzwerk "Blinx")
  # Siehe: dokumentation.md für vollständige Analyse

  # 1. NetworkManager: WiFi Power-Save komplett deaktivieren
  # Power-Save ist die Hauptursache für Treiber-Deadlocks
  networking.networkmanager.wifi.powersave = false;

  # 2. NetworkManager-Einstellungen für Stabilität
  networking.networkmanager.settings = {
    wifi = {
      # MAC-Randomisierung beim Scannen deaktivieren (kann AP-Probleme verursachen)
      scan-rand-mac-address = "no";
    };
    "connection" = {
      # Stabile Verbindungs-ID (verhindert "vergessene" Verbindungen)
      stable-id = "\${CONNECTION}/\${BOOT}";
    };
  };

  # 3. Udev-Regel: Power-Management auf Hardware-Ebene deaktivieren
  # Greift früher als NetworkManager, bereits beim Laden des Treibers
  services.udev.extraRules = ''
    # MediaTek MT7925 WiFi: PCI Power-Management deaktivieren
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x14c3", ATTR{device}=="0x7925", ATTR{power/control}="on"
    # WiFi-Interface: Power-Save via iw deaktivieren
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev %k set power_save off"
  '';

  # 4. Sysctl: TCP Keepalive für stabilere Verbindungen bei kurzen WLAN-Drops
  boot.kernel.sysctl = {
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 6;
    "net.ipv4.tcp_fin_timeout" = 15;
  };

  # 5. Systemd-Service: Power-Save Fallback nach Network-Online
  systemd.services.wifi-powersave-off = {
    description = "Disable WiFi Power Save for MT7925 stability";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wifi-powersave-off" ''
        sleep 2
        for iface in /sys/class/net/wl*; do
          if [ -d "$iface" ]; then
            ifname=$(basename "$iface")
            ${pkgs.iw}/bin/iw dev "$ifname" set power_save off 2>/dev/null || true
          fi
        done
      '';
    };
  };

  # 6. NetworkManager Dispatcher: Power-Save nach jedem Reconnect deaktivieren
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeText "99-wifi-powersave" ''
        #!/bin/sh
        # MT7925: Power-Save nach Verbindungsänderung deaktivieren
        INTERFACE="$1"
        ACTION="$2"
        case "$INTERFACE" in
          wl*)
            case "$ACTION" in
              up|dhcp4-change|dhcp6-change|connectivity-change)
                logger "MT7925-stability: Disabling power save for $INTERFACE after $ACTION"
                ${pkgs.iw}/bin/iw dev "$INTERFACE" set power_save off 2>/dev/null || true
                ;;
            esac
            ;;
        esac
      '';
      type = "basic";
    }
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
    # WiFi-Tools für MT7925 Debugging und Management
    iw              # iw dev wlan0 info, iw dev wlan0 get power_save
    wirelesstools   # iwconfig (Legacy)
    wavemon         # Interaktiver WiFi-Monitor
  ];

  # Sanfter Governor (optional)
  powerManagement.cpuFreqGovernor = "schedutil";

  ############################################################################
  # Suspend/Resume Fixes für MT7925 WiFi + AMDGPU VPE
  ############################################################################
  # Problem (2025-12-10): Bildschirm bleibt schwarz nach Suspend, System hängt
  # Ursache 1: mt7925e-Treiber timeout beim Suspend (error -110)
  # Ursache 2: AMDGPU VPE queue reset schlägt fehl
  # Lösung: WiFi-Modul vor Suspend entladen, nach Resume neu laden

  # Service: WiFi-Treiber VOR dem Suspend entladen
  systemd.services.wifi-suspend-unload = {
    description = "Unload MT7925 WiFi driver before suspend";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kmod}/bin/modprobe -r mt7925e mt7925_common mt792x_lib mt76_connac_lib mt76 || true";
    };
  };

  # Service: WiFi-Treiber NACH dem Resume laden
  systemd.services.wifi-resume-reload = {
    description = "Reload MT7925 WiFi driver after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "wifi-resume" ''
        # Warte kurz bis Hardware bereit
        sleep 1
        # Lade WiFi-Module neu
        ${pkgs.kmod}/bin/modprobe mt7925e || true
        # Warte auf Interface
        sleep 2
        # Deaktiviere Power-Save
        for iface in /sys/class/net/wl*; do
          if [ -d "$iface" ]; then
            ifname=$(basename "$iface")
            ${pkgs.iw}/bin/iw dev "$ifname" set power_save off 2>/dev/null || true
          fi
        done
      '';
    };
  };

  # AMDGPU: VPE (Video Processing Engine) deaktivieren - verhindert den Suspend-Bug
  # Der VPE queue reset schlägt auf diesem Gerät fehl
  boot.extraModprobeConfig = ''
    options amdgpu vpe=0
  '';

  # NetworkManager: USB-C Dock/Ethernet Fallback auf WiFi
  # Problem: Beim Abziehen des USB-C Docks (mit Ethernet) fehlte die Netzwerkverbindung,
  # da WiFi nicht automatisch aktiviert wurde und GNOME-Settings einfroren.
  # Lösung: Nur Metriken setzen, damit beide parallel laufen können.
  # WiFi-Aktivierung erfolgt manuell oder automatisch durch NetworkManager.

  # Setze die Verbindungsmetriken über nmcli nach dem Systemstart
  # Dies läuft NACH dem GNOME-Login, damit der Keyring verfügbar ist
  systemd.user.services.networkmanager-connection-metrics = {
    description = "Set NetworkManager connection metrics for dock fallback";
    after = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Warte bis NetworkManager und GNOME-Session bereit sind
      sleep 5

      # Setze nur Metriken für bestehende Verbindungen (keine Passwörter nötig)
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
    '';
  };
}