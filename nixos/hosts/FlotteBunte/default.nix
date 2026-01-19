######################################################################
# `hosts/FlotteBunte/default.nix` – ASUS ROG Zephyrus G16 2025 (GU605)
######################################################################
# Hardware:
# - CPU: Intel Core Ultra 9 285H (Arrow Lake)
# - iGPU: Intel Arc Pro 140T
# - dGPU: NVIDIA GeForce RTX 5070 Max-Q (Blackwell GB206M)
# - Display: OLED 2.5K 240Hz

{ config, pkgs, lib, ... }:

{
  system.stateVersion = "25.05";

  networking.hostName = "FlotteBunte";

  # Intel Microcode Updates (behebt MCE Hardware Errors)
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Kernel 6.18 - enthält WiFi 7 BE201 Fix (Scan-Bug behoben in 6.16.6)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel-Parameter werden im Backlight-Abschnitt definiert

  # UEFI-Boot mit systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # ══════════════════════════════════════════════════════════════════
  # NVIDIA Prime (Hybrid-Grafik: Intel iGPU + NVIDIA dGPU)
  # ══════════════════════════════════════════════════════════════════
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;  # Schaltet dGPU bei Nichtgebrauch aus
    open = true;  # Open Kernel Module (erforderlich für RTX 50-Serie/Blackwell)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # NVIDIA Optimus / Prime
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Stellt `nvidia-offload` Befehl bereit
      };
      # PCI Bus IDs (lspci | grep VGA)
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # nvidiaPersistenced und dynamicBoost nicht kompatibel mit Prime Offload
    nvidiaPersistenced = false;
  };

  # ══════════════════════════════════════════════════════════════════
  # Grafik (Intel Arc + NVIDIA)
  # ══════════════════════════════════════════════════════════════════
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver    # VAAPI für Intel Arc
      nvidia-vaapi-driver   # VAAPI via NVIDIA
    ];
  };

  # ══════════════════════════════════════════════════════════════════
  # ASUS ROG Features (asusd)
  # ══════════════════════════════════════════════════════════════════
  services.asusd = {
    enable = true;
    enableUserService = true;
  };

  # supergfxd braucht pciutils für GPU-Erkennung
  systemd.services.supergfxd.path = [ pkgs.pciutils ];

  # nvidia-powerd Dummy-Service (verhindert udev/supergfxd Fehler)
  # nvidia-powerd ist nicht kompatibel mit Prime Offload, wird aber von udev-Regeln erwartet
  systemd.services.nvidia-powerd = {
    description = "NVIDIA Power Daemon (Dummy für Prime Offload)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };
  };

  # Keyboard-Remapping für ROG Zephyrus (Fn-Tasten)
  services.udev.extraHwdb = ''
    evdev:atkbd:dmi:bvn*:bvr*:bd*:svnASUS*:pn*:*
      KEYBOARD_KEY_f7=micmute
      KEYBOARD_KEY_c7=home
      KEYBOARD_KEY_c8=end
  '';

  # ══════════════════════════════════════════════════════════════════
  # Backlight (OLED + Intel Arc)
  # ══════════════════════════════════════════════════════════════════
  # OLED-Displays mit Intel Arc nutzen intel_backlight
  programs.light.enable = true;

  # udev-Regel für Backlight-Zugriff (video-Gruppe)
  services.udev.extraRules = ''
    # Intel Backlight für alle Benutzer der video-Gruppe
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/backlight/intel_backlight/brightness"
    # ASUS Screenpad / OLED Backlight (falls vorhanden)
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="asus_screenpad", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/backlight/asus_screenpad/brightness"
    # ACPI Video Backlight (Fallback)
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  # Kernel-Parameter für korrektes Backlight-Verhalten
  boot.kernelParams = [
    # NVIDIA Suspend/Resume
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    # Backlight: Intel soll Kontrolle haben, nicht NVIDIA
    "acpi_backlight=native"
    "i915.enable_dpcd_backlight=1"              # DPCD-Backlight für OLED/eDP
    "nvidia.NVreg_EnableBacklightHandler=0"     # NVIDIA Backlight deaktivieren
    "nvidia.NVreg_RegistryDwords=EnableBrightnessControl=0"
  ];

  # DDC/CI für Monitor-Helligkeitssteuerung (externe Displays)
  services.ddccontrol.enable = true;

  # ══════════════════════════════════════════════════════════════════
  # Audio (Cirrus Logic CS35L41 Smart-Amplifier)
  # ══════════════════════════════════════════════════════════════════
  # ROG Laptops nutzen CS35L41 Verstärker, die Sound Open Firmware brauchen
  # WICHTIG: Alle Firmware-Pakete für CS35L41 DSP
  hardware.firmware = with pkgs; [
    sof-firmware           # Sound Open Firmware (HDA-Codec + DSP)
    linux-firmware         # Enthält CS35L41 Firmware-Dateien
    alsa-firmware          # Zusätzliche ALSA Firmware
  ];

  # Kernel-Module für CS35L41 sicherstellen
  boot.initrd.kernelModules = [ "snd_hda_intel" "snd_sof" ];
  boot.kernelModules = [
    "snd_hda_intel"
    "snd_sof"
    "snd_sof_pci"
    "snd_sof_intel_hda_common"
    "snd_soc_cs35l41_spi"
    "snd_soc_cs35l41_i2c"
  ];

  # Kernel-Parameter für Intel HDA mit SOF
  boot.extraModprobeConfig = ''
    # Intel HDA: SOF-Treiber für DSP-basierte Codecs verwenden
    options snd_intel_dspcfg dsp_driver=3
    # CS35L41: Reset-Verzögerung für stabiles Laden
    options snd_soc_cs35l41_spi reset_gpio_delay_ms=100
  '';

  # ALSA UCM2 Konfiguration für CS35L41 (behebt blechernen Sound)
  environment.etc."alsa/conf.d/99-asus-rog-fix.conf".text = ''
    # Cirrus Logic CS35L41 Fix für ASUS ROG
    defaults.pcm.dmix.rate 48000
    defaults.pcm.dmix.format S32_LE
  '';

  # PipeWire-Optimierungen für den Laptop-Lautsprecher
  services.pipewire.extraConfig.pipewire."92-asus-audio" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.allowed-rates" = [ 44100 48000 ];
    };
  };

  # WirePlumber-Konfiguration für bessere Lautsprecher-Erkennung
  services.pipewire.wireplumber.extraConfig."92-asus-alsa" = {
    "monitor.alsa.rules" = [
      {
        matches = [{ "node.name" = "~alsa_output.*"; }];
        actions = {
          update-props = {
            "audio.format" = "S32LE";
            "audio.rate" = 48000;
            "api.alsa.period-size" = 1024;
            "api.alsa.headroom" = 8192;
          };
        };
      }
    ];
  };

  # ══════════════════════════════════════════════════════════════════
  # Power Management
  # ══════════════════════════════════════════════════════════════════
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";

  # power-profiles-daemon für Performance-Profile (via asusd)
  services.power-profiles-daemon.enable = true;

  # Thermald für Intel-CPUs
  services.thermald.enable = true;

  # ══════════════════════════════════════════════════════════════════
  # Pakete
  # ══════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    # Diagnose
    mesa-demos       # glxinfo
    vulkan-tools     # vulkaninfo
    libva-utils      # vainfo
    nvtopPackages.full  # GPU-Monitor

    # ROG Control
    asusctl          # CLI für asusd

    # Audio-Diagnose und UCM-Profile
    alsa-utils       # aplay, amixer, alsamixer
    alsa-ucm-conf    # UCM-Profile (inkl. CS35L41)

    # Helligkeitssteuerung
    brightnessctl    # Alternative zu light
    ddcutil          # DDC/CI für externe Monitore

    # GStreamer (Videos/Browser-Backends)
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
  ];
}
