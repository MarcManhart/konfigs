# Ansible Configuration

Ansible-basierte Systemkonfiguration als Alternative zur NixOS Flake-Konfiguration.
Ermöglicht die gleiche Konfiguration auf Arch Linux, Debian/Ubuntu, Fedora und anderen Distributionen.

## Struktur

```
ansible/
├── ansible.cfg              # Ansible Konfiguration
├── inventory/
│   └── hosts.yml            # Host-Definitionen
├── group_vars/
│   └── all.yml              # Globale Variablen
├── host_vars/
│   └── schwerer.yml         # Host-spezifische Variablen
├── playbooks/
│   └── schwerer.yml         # Hauptplaybook für schwerer
└── roles/
    ├── base/                # Basis-System (Locale, SSH, Firewall)
    ├── user/                # User-Setup
    ├── desktop/             # Desktop-Umgebung (Audio, Printing, Docker)
    ├── gnome/               # GNOME Desktop
    ├── hyprland/            # Hyprland Wayland WM
    ├── nvidia/              # NVIDIA Treiber
    ├── gaming/              # Steam, Emulators, Controller
    └── dotfiles/            # Dotfiles verlinken
```

## Voraussetzungen

- Ansible >= 2.12
- Python 3.8+
- SSH-Zugang zum Zielhost (oder localhost)

### Ansible installieren

```bash
# Arch Linux
sudo pacman -S ansible

# Debian/Ubuntu
sudo apt install ansible

# Fedora
sudo dnf install ansible

# pip (universal)
pip install ansible
```

## Verwendung

### Lokal ausführen (auf dem gleichen Rechner)

```bash
cd ansible

# Alles installieren
ansible-playbook playbooks/schwerer.yml

# Nur bestimmte Roles
ansible-playbook playbooks/schwerer.yml --tags "base,user"

# Nur Dotfiles
ansible-playbook playbooks/schwerer.yml --tags "dotfiles"

# Dry-run (zeigt was passieren würde)
ansible-playbook playbooks/schwerer.yml --check

# Verbose Output
ansible-playbook playbooks/schwerer.yml -vvv
```

### Remote ausführen

1. Inventory anpassen (`inventory/hosts.yml`):
```yaml
schwerer:
  ansible_host: 192.168.1.100
  ansible_user: mauschel
```

2. Playbook ausführen:
```bash
ansible-playbook playbooks/schwerer.yml --ask-become-pass
```

## Roles

### base
- Locale und Timezone
- SSH Server Konfiguration
- Firewall (UFW/firewalld/iptables)
- NetworkManager
- Basis-Pakete (vim, git, htop, etc.)

### user
- Benutzer erstellen
- Gruppen zuweisen
- SSH Keys
- User-spezifische Pakete

### desktop
- PipeWire Audio
- Bluetooth
- CUPS Printing
- Docker
- Libvirt/QEMU
- Syncthing
- Fonts

### gnome
- GNOME Desktop Environment
- GDM Display Manager
- GNOME Extensions
- GSConnect Firewall-Ports

### hyprland
- Hyprland Compositor
- Waybar, Kitty, Rofi
- XDG Portals
- Blueman

### nvidia
- NVIDIA Proprietary Drivers
- Kernel Parameter für Wayland
- VA-API Support
- Power Management

### gaming
- Steam
- ProtonUp-Qt
- Emulators (RetroArch, PCSX2, RPCS3, etc.)
- Wine
- Controller Support (Xbox, PlayStation, Nintendo)
- GameMode

### dotfiles
- Verlinkt Dotfiles aus `../dotfiles/`
- Verlinkt Themes aus `../resources/styling/`
- Backup existierender Dateien

## Anpassungen

### Neue Hosts hinzufügen

1. In `inventory/hosts.yml`:
```yaml
laptops:
  hosts:
    FlotteBunte:
      ansible_host: 192.168.1.101
```

2. Host-Variablen erstellen: `host_vars/FlotteBunte.yml`

3. Playbook erstellen: `playbooks/FlotteBunte.yml`

### Features aktivieren/deaktivieren

In `group_vars/all.yml` oder `host_vars/<host>.yml`:
```yaml
enable_nvidia: true
enable_gaming: true
enable_hyprland: true
enable_gnome: true
enable_docker: true
```

## Unterstützte Distributionen

- **Arch Linux** - Vollständig unterstützt
- **Fedora** - Vollständig unterstützt
- **Debian/Ubuntu** - Größtenteils unterstützt (manche Pakete müssen manuell installiert werden)

## Unterschiede zu NixOS

| Feature | NixOS | Ansible |
|---------|-------|---------|
| Deklarativ | Ja | Teilweise |
| Rollback | Ja | Nein (manuell) |
| Reproduzierbar | Ja | Teilweise |
| Multi-Distro | Nein | Ja |
| Lernkurve | Hoch | Mittel |

## Fehlerbehebung

### Permission Denied
```bash
ansible-playbook playbooks/schwerer.yml --ask-become-pass
```

### SSH Connection Failed
```bash
# SSH Key kopieren
ssh-copy-id user@host

# Oder Passwort verwenden
ansible-playbook playbooks/schwerer.yml --ask-pass
```

### Pakete nicht gefunden
Manche Pakete haben unterschiedliche Namen je nach Distribution.
Prüfe die `defaults/main.yml` der entsprechenden Role.
