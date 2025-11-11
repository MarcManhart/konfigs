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
}
