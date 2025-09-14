######################################################################
# `hosts/schwerer/default.nix` – Host-spezifische Overrides
######################################################################
# Wofür diese Datei da ist:
#
# - Feintuning für DIESEN Host (Hostname, Bootloader, Kernelwahl, HW-Treiber, Gouvernor etc.).
# - Alles, was *nur* diesen Rechner betrifft – nicht global.

{ config, pkgs, ... }:
let
  # coolerDir = /home/mauschel/konfigs/home/mauschel/dotfiles/etc/coolercontrol;
  # # Deine versionierten Defaults (werden in den Store gepackt)
  # ccDefaults = builtins.path {
  #   path = /home/mauschel/konfigs/home/mauschel/dotfiles/etc/coolercontrol;
  #   name = "coolercontrol-defaults";
  # };
in
{
  system.stateVersion = "25.05";

  # Auf konkreten Kernel pinnen
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Host-spezifisches kommt hier rein (nur so viel wie nötig).
  networking.hostName = "schwerer";

  # UEFI-Boot mit systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # NVIDIA: Grafiktreiber
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.finegrained = false;
    open = false; # Nutze closed-source Treiber (oder true für open source bei RTX/GTX 16xx)
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # 25.05: neues Modul 'hardware.graphics' statt 'hardware.opengl'
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # hier statt environment.systemPackages → saubere Einbindung
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
    extraPackages32 = with pkgs; [ ];
  };

  hardware.opengl = {
    enable = true;
    #driSupport = true; system told me I didn't need this any more
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      #vaaiVdupau # keeping disabled for now
      libvdpau-va-gl
    ];
  };

  # Cooler Control
  programs.coolercontrol = {
    enable = true;
    nvidiaSupport = true;
  };

  # VA-API/GLX/GBM sauber auf NVIDIA zeigen lassen
  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia"; # VA-API via nvidia-vaapi-driver
    VDPAU_DRIVER = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm"; # Wayland/GBM Stack
  };

  environment.systemPackages = with pkgs; [
    # Diagnose
    mesa-demos # liefert glxinfo
    vulkan-tools # liefert vulkaninfo
    libva-utils # liefert vainfo
    vdpauinfo
    liquidctl

    # GStreamer (Videos/Browser-Backends)
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi # wichtig für VA-API
  ];

  # Sanfter Governor (optional)
  powerManagement.cpuFreqGovernor = "schedutil";
}
