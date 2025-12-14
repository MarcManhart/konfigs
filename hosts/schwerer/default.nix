######################################################################
# `hosts/schwerer/default.nix` – Host-spezifische Overrides
######################################################################
# Wofür diese Datei da ist:
#
# - Feintuning für DIESEN Host (Hostname, Bootloader, Kernelwahl, HW-Treiber, Gouvernor etc.).
# - Alles, was *nur* diesen Rechner betrifft – nicht global.

{ config, pkgs, lib, ... }:
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

  # Kernel-Parameter für besseres NVIDIA Suspend/Resume mit Wayland
  boot.kernelParams = [
    "nvidia-drm.modeset=1"  # Wichtig für Wayland
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # Bewahrt Video-Memory bei Suspend
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"  # Speicherort für temporäre Dateien
  ];

  # Host-spezifisches kommt hier rein (nur so viel wie nötig).
  networking.hostName = "schwerer";

  # UEFI-Boot mit systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # NVIDIA: Grafiktreiber
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.deviceSection = ''
    Option "Coolbits" "4"
  '';
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # Aktiviert NVIDIA Power Management für Suspend/Resume
    powerManagement.finegrained = false;
    open = false; # closed-source Treiber (für RTX/GTX i. d. R. stabiler)
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # Preserve video memory after suspend (wichtig für Wayland)
    nvidiaPersistenced = true;
  };

  # 25.05: neues Modul 'hardware.graphics' statt 'hardware.opengl'
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
    extraPackages32 = with pkgs; [ ];
  };

  # Cooler Control
  programs.coolercontrol = {
    enable = true;
    nvidiaSupport = true;
  };

  # VA-API/GLX/GBM auf NVIDIA zeigen lassen
  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia"; # VA-API via nvidia-vaapi-driver
    VDPAU_DRIVER = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm"; # Wayland/GBM Stack
  };

  environment.systemPackages = with pkgs; [
    # Diagnose
    mesa-demos      # glxinfo
    vulkan-tools    # vulkaninfo
    libva-utils     # vainfo
    vdpauinfo
    liquidctl

    # GStreamer (Videos/Browser-Backends)
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
  ];

  # Sanfter Governor (optional)
  powerManagement.cpuFreqGovernor = "schedutil";
  powerManagement.enable = true;

  # GPP0 dauerhaft als Wake-Quelle deaktivieren (wie dein echo-Befehl, nur automatisch)
  systemd.services.disable-gpp0-wakeup = {
    description = "Disable ACPI wakeup for GPP0";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-gpp0-wakeup" ''
        set -eu
        if [ -r /proc/acpi/wakeup ]; then
          # Nur toggeln, wenn aktuell *enabled* ist
          if grep -q "^\s*GPP0\s\+S[0-9]\+\s\+\*enabled" /proc/acpi/wakeup; then
            echo "GPP0 > /proc/acpi/wakeup (disable)"
            echo GPP0 > /proc/acpi/wakeup
          else
            echo "GPP0 wakeup already disabled"
          fi
        fi
      '';
      RemainAfterExit = true;
    };
  };

  # Optional, falls Firmware nach Resume wieder einschaltet (selten):
  powerManagement.resumeCommands = lib.mkAfter ''
    if [ -r /proc/acpi/wakeup ]; then
      grep -q "^\s*GPP0\s\+S[0-9]\+\s\+\*enabled" /proc/acpi/wakeup && echo GPP0 > /proc/acpi/wakeup
    fi
  '';

  # Falls nach *korrektem* Suspend/Resume weiterhin Grafik-Artefakte auftreten sollten,
  # kann testweise aktiviert werden (vorerst auskommentiert lassen):
  # boot.kernelParams = [ "amdgpu.reset=1" ];
}
