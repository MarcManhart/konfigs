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

{ pkgs, ... }:
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

  # AMD: Microcode + Grafiktreiber
  hardware.cpu.amd.updateMicrocode = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Sanfter Governor (optional)
  powerManagement.cpuFreqGovernor = "schedutil";
}

