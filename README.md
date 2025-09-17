# Konfigs - Meine NixOS Konfiguration

Nach frisch installiertem NixOS:

```bash
ssh-keygen # public key dann zu github
```

```bash
sudo nixos-generate-config
cp /etc/nixos/hardware-configuration.nix ./hosts/BLX-INV-28/hardware-configuration.nix
sudo nixos-rebuild switch --flake .#BLX-INV-28
```

```bash
sudo nixos-generate-config
cp /etc/nixos/hardware-configuration.nix ./hosts/schwerer/hardware-configuration.nix
sudo nixos-rebuild switch --flake .#schwerer
```

# Alte Generations wegwerfen

```bash
nix-collect-garbage  --delete-old
sudo nix-collect-garbage -d
# wird manchmal empfohlen, als sudo auszuführen, um zusätzlichen Müll zu sammeln

```

# NordVPN via OpenVPN einrichten
Wichtig: Unbedingt auch IP6 sowohl in den VPN Einstellungen (in Gnome Einstellungsmenu) als auch für das Ethernet deaktivieren. Ansonsten wird doch die IP exposed.

Wird bereits in der mauschel.nix konfiguriert. Hier weiter notwendige Schritte von claude.
Daten und opnvpn datei bekommt man hier: https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/service-credentials/

1. Erstelle die auth.txt Datei:
   nano /home/mauschel/.config/openvpn/auth.txt # erste Zeile Username; zweite Zeile passwort
2. Füge ein:
   dein-nordvpn-benutzername
   dein-nordvpn-passwort
3. Sichere die Datei:
   chmod 600 /home/mauschel/.config/openvpn/auth.txt
4. Rebuild NixOS:
   sudo nixos-rebuild switch
5. VPN starten:
   sudo systemctl start openvpn-nordvpn-de

Wichtig: Du brauchst keine separaten ca.crt, client.crt oder client.key Dateien - NordVPN hat alle Zertifikate
bereits in der .ovpn Datei integriert!
