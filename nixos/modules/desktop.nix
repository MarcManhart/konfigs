# `modules/desktop.nix` – Desktop-Rolle
#
# Wofür diese Datei da ist:
#
# - Alle GUI/Workstation-Themen, die *mehrere* Desktop‑Hosts betreffen: Display‑Manager, Desktop‑Environment, Bluetooth, Power‑Daemon, Docker, Dev‑Tools.
#
# Kommentare & Hinweise:
# - GNOME via GDM aktiviert. Alternative DEs (KDE, sway, hyprland) könnten hier als Optionen auswählbar gemacht werden.
# - `virtualisation.docker.enable = true;` + `users.groups.docker.members` – gut für Dev‑Workstations. Für Server separat halten.
# - `environment.systemPackages` hier nur für *Desktop-spezifische* Tools nutzen. Allgemeines besser in `base.nix`.

{ pkgs, ... }:
let
  androidSdk = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [
      "31"
      "34"
      "35"
    ];
    buildToolsVersions = [
      "34.0.0"
      "35.0.0"
    ];
    includeNDK = true;
    ndkVersions = [ "26.1.10909125" ];
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "x86_64" ];
  };
in
{
  # Android SDK Umgebungsvariablen
  environment.variables = {
    ANDROID_HOME = "${androidSdk.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk.androidsdk}/libexec/android-sdk";
  };
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true; # Deaktiviert für Hyprland

  hardware.bluetooth = {
    enable = true;
    # ISO Socket für Bluetooth LE Audio (BAP) aktivieren
    settings = {
      General = {
        Experimental = true; # Aktiviert ISO Socket und LE Audio Features
      };
    };
  };
  hardware.logitech.wireless.enable = true; # Für Solaar - Logitech Wireless-Geräte Support
  services.power-profiles-daemon.enable = true;

  # GNOME Keyring für automatisches Entsperren
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  ############################################################################
  # Audio (PipeWire)
  ############################################################################
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;

    # Low-Latency für Gaming
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 512;
        default.clock.min-quantum = 512;
        default.clock.max-quantum = 512;
      };
    };

    # Virtuelles Audio-Setup für Discord/Gaming + Self-Monitoring
    # (Deaktiviert - bei Bedarf wieder einkommentieren)
    #
    # Aufbau:
    #   Soundboard/Musik ──▶ Soundboard-Sink ──┬──▶ Virtual-Cable ──▶ Virtual-Mic ──▶ Discord
    #                                          │
    #                                          └──▶ Kopfhörer (Self-Monitor)
    #
    #   Echtes Mikrofon ──────────────────────────▶ Virtual-Cable ──▶ Virtual-Mic ──▶ Discord
    #
    # Nutzung:
    # - Discord: "Virtual-Mic" als Eingabegerät wählen
    # - Soundboard/Musik/Spotify: "Soundboard-Sink" als Ausgabegerät wählen
    # - Du hörst nur Soundboard/Musik (NICHT dein eigenes Mikrofon!)
    # - Discord-Leute hören: Mikrofon + Soundboard/Musik
    # extraConfig.pipewire."91-virtual-mic" = {
    #   "context.modules" = [
    #     # 1. Virtual-Cable (Sink) → Virtual-Mic (Source)
    #     # Sammelpunkt für alles was an Discord geht
    #     {
    #       name = "libpipewire-module-loopback";
    #       args = {
    #         "audio.position" = [ "FL" "FR" ];
    #         "capture.props" = {
    #           "media.class" = "Audio/Sink";
    #           "node.name" = "virtual-cable";
    #           "node.description" = "Virtual-Cable (intern)";
    #         };
    #         "playback.props" = {
    #           "media.class" = "Audio/Source";
    #           "node.name" = "virtual-mic";
    #           "node.description" = "Virtual-Mic (für Discord)";
    #         };
    #       };
    #     }
    #     # 2. Soundboard-Sink: Hier Soundboard/Musik/Spotify ausgeben
    #     # Wird an Discord UND Self-Monitor weitergeleitet
    #     {
    #       name = "libpipewire-module-loopback";
    #       args = {
    #         "audio.position" = [ "FL" "FR" ];
    #         "capture.props" = {
    #           "media.class" = "Audio/Sink";
    #           "node.name" = "soundboard-sink";
    #           "node.description" = "Soundboard/Musik (hier ausgeben)";
    #         };
    #         "playback.props" = {
    #           "node.target" = "virtual-cable";
    #         };
    #       };
    #     }
    #     # 3. Self-Monitor: Soundboard-Sink → Kopfhörer
    #     # Du hörst NUR Soundboard/Musik (NICHT dein Mikrofon!)
    #     {
    #       name = "libpipewire-module-loopback";
    #       args = {
    #         "audio.position" = [ "FL" "FR" ];
    #         "node.name" = "self-monitor";
    #         "node.description" = "Self-Monitor (ohne Mikrofon)";
    #         "capture.props" = {
    #           "node.target" = "soundboard-sink";
    #           "stream.capture.sink" = true;
    #         };
    #         "playback.props" = {
    #           # Geht automatisch an Default-Ausgabe (Kopfhörer)
    #         };
    #       };
    #     }
    #     # 4. Mikrofon → Virtual-Cable
    #     # Dein Mikrofon geht nur an Discord, nicht an Self-Monitor
    #     {
    #       name = "libpipewire-module-loopback";
    #       args = {
    #         "audio.position" = [ "FL" "FR" ];
    #         "node.name" = "mic-to-cable";
    #         "node.description" = "Mikrofon zu Discord";
    #         "capture.props" = {
    #           # Kein target = Default-Mikrofon
    #         };
    #         "playback.props" = {
    #           "node.target" = "virtual-cable";
    #         };
    #       };
    #     }
    #   ];
    # };
  };

  ############################################################################
  # Druckerdienst (CUPS)
  ############################################################################
  # CUPS - Common Unix Printing System
  # Web-Interface: http://localhost:631
  services.printing = {
    enable = true;
    # Automatische Treiber-Erkennung für gängige Drucker
    drivers = with pkgs; [
      gutenprint # Viele Drucker (Canon, Epson, HP, etc.)
      cnijfilter2 # Canon PIXMA Inkjet-Drucker (TS, TR, G, etc.)
      hplip # HP Drucker (inkl. Scanner-Support)
      brlaser # Brother Laser-Drucker
    ];
    # Netzwerkdrucker automatisch erkennen (Bonjour/mDNS)
    browsing = true;
    defaultShared = false; # Drucker nicht standardmäßig teilen
  };

  # Avahi für Netzwerkdrucker-Erkennung (mDNS/DNS-SD)
  # Ermöglicht automatische Erkennung von Druckern im lokalen Netzwerk
  services.avahi = {
    enable = true;
    nssmdns4 = true; # .local Hostnamen auflösen (IPv4)
    openFirewall = true; # mDNS Port 5353 öffnen
  };

  # Scanner-Support (SANE) für Canon TS5300 All-in-One
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ]; # eSCL/AirScan für Netzwerk-Scanner
  };

  # Syncthing - Datei-Synchronisation
  services.syncthing = {
    enable = true;
    user = "mauschel";
    dataDir = "/home/mauschel/Documents"; # Standardverzeichnis für Syncthing-Daten
    configDir = "/home/mauschel/.config/syncthing"; # Konfigurationsverzeichnis
    openDefaultPorts = true; # Öffnet Ports 8384 (Web UI) und 22000 (Sync)
    settings = {
      gui = {
        # Web-Interface auf localhost:8384
        enabled = true;
        insecureSkipHostcheck = false;
      };
      options = {
        urAccepted = -1; # Keine Nutzungsstatistiken senden
        relaysEnabled = true; # Relay-Server für NAT-Traversal nutzen
      };
    };
  };

  # Docker wird jetzt in container.nix konfiguriert

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    nixfmt
    firefox
    # qpwgraph          # PipeWire Graph Manager für Audio-Routing (deaktiviert)
    # audacity          # Audio-Editor zum Testen (deaktiviert)
    direnv
    solaar
    # VSCode mit GPU-Beschleunigung deaktiviert und Desktop-Icon
    (pkgs.symlinkJoin {
      name = "vscode-wrapper";
      paths = [
        (pkgs.writeShellScriptBin "code" ''
          exec ${pkgs.vscode.fhs}/bin/code --disable-gpu "$@"
        '')
        (pkgs.makeDesktopItem {
          name = "code";
          desktopName = "Visual Studio Code";
          comment = "Code Editing. Redefined.";
          genericName = "Text Editor";
          exec = "code %F";
          icon = "${pkgs.vscode}/share/pixmaps/vscode.png";
          startupNotify = true;
          startupWMClass = "Code";
          categories = [
            "Utility"
            "TextEditor"
            "Development"
            "IDE"
          ];
          mimeTypes = [
            "text/plain"
            "inode/directory"
          ];
          keywords = [ "vscode" ];
        })
      ];
    })
    # vscode
    brave
    thunderbird
    terminator
    # Blender mit X11/XWayland statt nativem Wayland (bessere Stabilität)
    (pkgs.symlinkJoin {
      name = "blender";
      paths = [ pkgs.blender ];
      postBuild = ''
                rm $out/bin/blender
                cat > $out/bin/blender << 'EOF'
        #!/bin/sh
        export WAYLAND_DISPLAY=
        export XDG_SESSION_TYPE=x11
        exec ${pkgs.blender}/bin/blender "$@"
        EOF
                chmod +x $out/bin/blender
      '';
    })
    inkscape
    krita
    penpot-desktop
    google-fonts
    scribus
    obsidian
    persepolis
    uget-integrator
    androidSdk.androidsdk # Android SDK mit ADB (adb devices etc.)
    mplayer
    tor-browser
    openvpn
    libreoffice
    onlyoffice-desktopeditors
    # CopyQ mit XWayland-Wrapper für Wayland-Kompatibilität
    (pkgs.writeShellScriptBin "copyq" ''
      exec env QT_QPA_PLATFORM=xcb ${pkgs.copyq}/bin/copyq "$@"
    '')
    conky
    img2pdf
  ];

  # GNOME hat seinen eigenen Portal-Backend
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

}
