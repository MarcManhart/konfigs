# Wofür diese Datei da ist:
#
# - Definiert *Inputs* (Quellen) wie `nixpkgs`, `home-manager`, `nixos-hardware`.
# - Definiert *Outputs* – insbesondere `nixosConfigurations` für jeden Host.
# - Bindet pro Host Module zusammen: `hardware-configuration.nix`, Host-Defaults und gemeinsame Module # (`./modules/*`).
#
# Was typischerweise hinein gehört:
#
# - Pinning der Channels (z. B. `nixos-25.05`), damit Builds reproduzierbar bleiben.
# - Auflistung aller Hosts unter `nixosConfigurations`.
# - Gemeinsame `specialArgs` bzw. `modules`-Importe, z. B. `base.nix`, `desktop.nix`, `users/ <name>.nix`.
#
# Kommentare & Hinweise:**
# - `home-manager.inputs.nixpkgs.follows = "nixpkgs";` hält HM und nixpkgs konsistent – gut.
# - Der Host `BLX-INV-28` wird über `lib.nixosSystem { ... }` definiert. Weitere Hosts kannst du analog ergänzen.
# - Achte darauf, dass `home-manager.users.mauschel = import ./home/mauschel/home.nix;` nur *User-spezifische* Dinge enthält; systemweite Pakete gehören in Module unter `./modules`.

{
  description = "Mauschels's multi-host NixOS config (flakes)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      ...
    }:
    let
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        BLX-INV-28 = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./modules/base.nix
            ./modules/desktop.nix
            ./modules/hyprland.nix
            ./modules/gnome.nix
            ./modules/blx.nix
            ./modules/users/mauschel.nix
            ./hosts/BLX-INV-28/hardware-configuration.nix
            ./hosts/BLX-INV-28/default.nix

            # sinnvolle HW-Profile
            nixos-hardware.nixosModules.common-cpu-amd
            nixos-hardware.nixosModules.common-pc-ssd
            nixos-hardware.nixosModules.common-pc-laptop

            # Home-Manager als NixOS-Modul; User-Config folgt später
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              # Platzhalter – wir legen die Datei im nächsten Schritt an:
              home-manager.users.mauschel = import ./home/mauschel/home.nix;
            }
          ];
        };
        schwerer = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./modules/base.nix
            ./modules/desktop.nix
            ./modules/hyprland.nix
            ./modules/gnome.nix
            ./modules/blx.nix
            ./modules/i2p.nix
            ./modules/users/mauschel.nix
            ./hosts/schwerer/hardware-configuration.nix
            ./hosts/schwerer/default.nix

            # sinnvolle HW-Profile
            nixos-hardware.nixosModules.common-cpu-amd
            nixos-hardware.nixosModules.common-pc-ssd

            # Home-Manager als NixOS-Modul; User-Config folgt später
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              # Platzhalter – wir legen die Datei im nächsten Schritt an:
              home-manager.users.mauschel = import ./home/mauschel/home.nix;
            }
          ];
        };
      };
    };
}
