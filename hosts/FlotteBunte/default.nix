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

  # Kernel 6.12 - stabil und kompatibel mit allen Modulen (v4l2loopback etc.)
  # linuxPackages_latest (6.18) hat noch Kompatibilitätsprobleme
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Kernel-Parameter für NVIDIA Suspend/Resume mit Wayland
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
  ];

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
    open = false;  # Closed-source Treiber (stabiler für RTX)
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

    # Preserve video memory nach Suspend
    nvidiaPersistenced = true;

    # Dynamic Boost für bessere Performance
    dynamicBoost.enable = true;
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

  # Keyboard-Remapping für ROG Zephyrus (Fn-Tasten)
  services.udev.extraHwdb = ''
    evdev:atkbd:dmi:bvn*:bvr*:bd*:svnASUS*:pn*:*
      KEYBOARD_KEY_f7=micmute
      KEYBOARD_KEY_c7=home
      KEYBOARD_KEY_c8=end
  '';

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

    # GStreamer (Videos/Browser-Backends)
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
  ];
}
