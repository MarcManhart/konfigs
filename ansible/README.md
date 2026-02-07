# Ansible Playbook

Setup-Playbook fuer Bunte (ASUS ROG Zephyrus G16 2025).
Entspricht dem NixOS-Profil: base + desktop + hyprland + gnome + container + gaming + i2p + mauschel + home-manager.

## Unterstuetzte Distributionen

- Arch / CachyOS
- Debian / Ubuntu / Pop!_OS
- Fedora

## Voraussetzungen

- Das `konfigs`-Repo muss auf dem Zielhost unter `~/konfigs` ausgecheckt sein
- Auf dem Zielhost muss ein AUR-Helper (`paru`) installiert sein (nur Arch/CachyOS)

## Ansible installieren

### NixOS

```bash
nix-env -iA nixos.ansible
```

### Arch/CachyOS

```bash
sudo pacman -S ansible
```

### Debian/Ubuntu

```bash
sudo apt install ansible
```

## Zielhost vorbereiten (Remote-Ausfuehrung)

Die folgenden Schritte muessen **auf dem Zielhost** ausgefuehrt werden.

### 1. SSH aktivieren

```bash
sudo pacman -S openssh    # falls noch nicht installiert
sudo systemctl enable --now sshd
```

### 2. Firewall fuer SSH oeffnen

```bash
# ufw
sudo ufw allow ssh

# oder firewalld
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
```

### 3. Passwort-Authentifizierung temporaer aktivieren (falls noetig)

Falls nur Public-Key-Auth erlaubt ist und noch kein Key hinterlegt wurde:

```bash
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

Nach dem Key-Transfer kann das wieder rueckgaengig gemacht werden:

```bash
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## SSH-Key auf Zielhost kopieren

Vom Steuerrechner aus:

```bash
ssh-copy-id mauschel@192.168.178.22
```

Verbindung testen:

```bash
ssh mauschel@192.168.178.22
```

## Playbook ausfuehren

```bash
# Nur remote (CachyOS)
ansible-playbook -i inventory playbook.yml --ask-become-pass --limit 192.168.178.22

# Nur lokal
ansible-playbook -i inventory playbook.yml --ask-become-pass --limit localhost

# Auf allen Hosts
ansible-playbook -i inventory playbook.yml --ask-become-pass
```

## Inventory

Die Datei `inventory` definiert die Zielrechner:

```ini
[Bunte]
localhost ansible_connection=local
192.168.178.22 ansible_user=mauschel ansible_connection=ssh
```

Neue Hosts koennen als weitere Zeilen unter `[Bunte]` hinzugefuegt werden.

## Paketstruktur

| Kategorie | Beschreibung | Installationsmethode |
|---|---|---|
| `common_packages` | Distro-uebergreifende Pakete (gleicher Name) | `package`-Modul |
| `base_packages` | Distro-spezifische Paketnamen | `package`-Modul |
| `flatpak_apps` | Proprietaere / Cross-Distro Apps | Flatpak via Flathub |
| AUR-Pakete | Nur Arch/CachyOS | `paru` |

AUR-Pakete werden separat via `paru` installiert und nur auf Arch-basierten Systemen ausgefuehrt.
