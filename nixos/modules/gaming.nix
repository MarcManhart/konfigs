{ config, pkgs, lib, ... }:

{
  # Steam mit allen notwendigen Abh�ngigkeiten
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;

    # Proton GE f�r bessere Kompatibilit�t
    gamescopeSession.enable = true;

    # Extra Pakete f�r Steam
    extraPackages = with pkgs; [
      xorg.libXcursor
      xorg.libXi
      xorg.libXinerama
      xorg.libXScrnSaver
      libpng
      libpulseaudio
      libvorbis
      stdenv.cc.cc.lib
      libkrb5
      keyutils
    ];
  };

  # Hardware-Unterst�tzung f�r Gaming
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Controller-Unterst�tzung
    # xone.enable = true; # Xbox One Controller - nicht kompatibel mit Kernel 6.18+
    # xpadneo.enable = true; # nicht kompatibel mit Kernel 6.18+ # Xbox Controller �ber Bluetooth
  };

  # Gaming-Pakete
  environment.systemPackages = with pkgs; [
    # Steam-Zusatztools
    mangohud # Performance-Overlay
    goverlay # GUI zur MangoHud-Konfiguration
    gamemode # Performance-Optimierung
    gamescope # Wayland-Compositor f�r Gaming
    protonup-qt # Proton-Version-Manager
    lutris # Alternative Game-Launcher

    # Nintendo Switch Emulator
    ryujinx # Stabiler Switch-Emulator

    # PlayStation Emulatoren
    pcsx2 # PlayStation 2 Emulator
    rpcs3 # PlayStation 3 Emulator
    duckstation # PlayStation 1 Emulator (moderner als ePSXe)

    # Nintendo 64 Emulator
    mupen64plus # N64 Emulator
    retroarch # Multi-System-Emulator mit N64-Cores
    retroarch-assets
    retroarch-joypad-autoconfig
    libretro.mupen64plus
    libretro.parallel-n64

    # Zus�tzliche Gaming-Tools
    joycond # Nintendo Switch Controller Support
    antimicrox # Controller zu Tastatur-Mapping

    # Vulkan-Tools
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers

    # Wine f�r Windows-Spiele au�erhalb von Steam
    wineWowPackages.staging
    winetricks
    bottles # Wine-Frontend
  ];

  # Systemd-Services f�r Gaming
  systemd.user.services = {
    # GameMode automatisch aktivieren
    gamemode = {
      description = "GameMode Daemon";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.gamemode}/bin/gamemoded";
        Restart = "on-failure";
      };
    };
  };

  # Kernel-Module f�r bessere Gaming-Performance
  boot = {
    kernelModules = [
      "v4l2loopback" # F�r virtuelle Kameras (Streaming)
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
    ];

    # Kernel-Parameter f�r Gaming-Performance
    kernelParams = [
      "mitigations=off" # Bessere Performance (weniger sicher)
      "nowatchdog" # Deaktiviert Watchdog
      "nmi_watchdog=0"
    ];
  };

  # Zus�tzliche Udev-Regeln f�r Controller
  services.udev.extraRules = ''
    # Nintendo Switch Pro Controller
    KERNEL=="hidraw*", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0666"

    # PlayStation Controller
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", MODE="0666"

    # 8BitDo Controller
    KERNEL=="hidraw*", ATTRS{idVendor}=="2dc8", MODE="0666"

    # Steam Controller
    KERNEL=="hidraw*", ATTRS{idVendor}=="28de", MODE="0666"
  '';

  # Firewall-Ausnahmen f�r Gaming
  networking.firewall = {
    allowedTCPPorts = [
      27015 # Steam
      27036 # Steam
      27037 # Steam
    ];

    allowedUDPPorts = [
      27015 # Steam
      27031 # Steam
      27036 # Steam
      4380 # Steam
    ];

    allowedTCPPortRanges = [
      { from = 27015; to = 27030; } # Steam
    ];

    allowedUDPPortRanges = [
      { from = 27000; to = 27100; } # Steam
    ];
  };

  # Limits f�r Gaming erh�hen
  security.pam.loginLimits = [
    {
      domain = "@users";
      type = "soft";
      item = "memlock";
      value = "unlimited";
    }
    {
      domain = "@users";
      type = "hard";
      item = "memlock";
      value = "unlimited";
    }
  ];

  # Zus�tzliche Bibliotheken f�r 32-bit Kompatibilit�t
  hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
    libva
    vaapiVdpau
    libvdpau-va-gl
  ];

  # Fonts f�r Spiele
  fonts.packages = with pkgs; [
    corefonts
    vistafonts
  ];

  # Audio-Optimierungen f�r Gaming
  services.pipewire = {
    extraConfig.pipewire = {
      "92-low-latency" = {
        context.properties = {
          default.clock.rate = 48000;
          default.clock.quantum = 512;
          default.clock.min-quantum = 512;
          default.clock.max-quantum = 512;
        };
      };
    };
  };
}