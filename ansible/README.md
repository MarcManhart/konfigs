# Ansible Playbook - Mauschel's Linux Setup

Dieses Ansible-Playbook reproduziert die NixOS Flake-Konfiguration auf anderen Linux-Distributionen.

## Unterstützte Distributionen

- **Debian/Ubuntu** (getestet mit Ubuntu 22.04+, Debian 12+)
- **Fedora** (getestet mit Fedora 39+)
- **Arch Linux**

## Voraussetzungen

### Auf dem Control Node (wo Ansible ausgeführt wird)

```bash
# Ansible installieren
pip install ansible

# Oder über Paketmanager:
# Debian/Ubuntu: sudo apt install ansible
# Fedora: sudo dnf install ansible
# Arch: sudo pacman -S ansible

# Galaxy Collections installieren
ansible-galaxy install -r requirements.yml
```

### Auf dem Target Node (Zielrechner)

- SSH-Zugang mit sudo-Rechten
- Python 3 installiert

## Verwendung

### Lokale Ausführung

```bash
cd ansible

# Alle Rollen ausführen
ansible-playbook site.yml --connection=local --ask-become-pass

# Nur bestimmte Tags
ansible-playbook site.yml --connection=local --ask-become-pass --tags "base,desktop"

# Dry-run (nur anzeigen was passieren würde)
ansible-playbook site.yml --connection=local --check
```

### Remote via SSH

1. Inventory anpassen (`inventory/hosts.yml`):

```yaml
all:
  children:
    workstations:
      hosts:
        mein-pc:
          ansible_host: 192.168.1.100
          ansible_user: mauschel
```

2. Playbook ausführen:

```bash
ansible-playbook site.yml --ask-become-pass
```

## Verfügbare Tags

| Tag | Beschreibung |
|-----|--------------|
| `base` | Grundkonfiguration (Locale, SSH, Firewall, Basispakete) |
| `desktop` | Desktop-Umgebung (GDM, Bluetooth, CUPS, Syncthing) |
| `hyprland` | Hyprland Wayland Compositor |
| `gnome` | GNOME Desktop und Extensions |
| `container` | Docker und Container-Tools |
| `gaming` | Steam, Emulatoren, Gaming-Tools |
| `user` | Benutzer-spezifische Konfiguration |
| `dotfiles` | Konfigurationsdateien verlinken |

## Feature-Flags

In `group_vars/all.yml` oder pro Host konfigurierbar:

```yaml
install_gaming: true      # Gaming-Pakete installieren
install_hyprland: true    # Hyprland installieren
install_gnome: true       # GNOME installieren
install_docker: true      # Docker installieren
install_i2p: false        # I2P Netzwerk
```

## Rollen-Übersicht

### base
- Zeitzone und Locale (Europe/Berlin, de_DE.UTF-8)
- NetworkManager
- SSH-Server (ohne Passwort-Auth)
- Firewall (ufw oder firewalld)
- Basispakete (vim, git, htop, curl, etc.)
- Node.js und Bun
- Nerd Fonts
- Zsh als Standard-Shell

### desktop
- X.Org und GDM
- Bluetooth
- CUPS Druckerdienst
- Avahi für Netzwerkdrucker
- Syncthing
- libvirt/KVM
- Desktop-Anwendungen (Firefox, Thunderbird, etc.)
- Flatpak mit Flathub

### hyprland
- Hyprland Wayland Compositor
- Waybar, rofi-wayland
- PipeWire Audio
- Blueman
- Screenshot-Tools (grim, slurp)

### gnome
- GNOME Desktop
- GNOME Extensions (Dash-to-Dock, AppIndicator, etc.)
- dconf-Einstellungen
- GSConnect Firewall-Ports

### container
- Docker CE
- Docker Compose
- dive, lazydocker
- Automatische Bereinigung (weekly prune)

### gaming
- Steam
- Vulkan-Treiber
- MangoHud, GameMode
- Lutris, Bottles
- Emulatoren (Ryujinx, PCSX2, RPCS3, RetroArch)
- Controller-Unterstützung (Xbox, PlayStation, Nintendo)
- Wine

### user_mauschel
- Benutzer mit Gruppen
- OBS Studio
- Godot mit .NET
- Development Tools
- ClamAV Antivirus
- 1Password

### dotfiles
- Symlinks zu Konfigurationsdateien
- Oh-My-Zsh
- Starship Prompt
- Gruvbox GTK Theme
- User-Systemd-Services

## Dotfiles-Pfade

Die Dotfiles werden als Symlinks angelegt, die auf die Dateien im Repository zeigen:

```
~/.zshrc -> /home/mauschel/konfigs/home/mauschel/dotfiles/.zshrc
~/.vimrc -> /home/mauschel/konfigs/home/mauschel/dotfiles/.vimrc
~/.config/hypr/ -> /home/mauschel/konfigs/home/mauschel/dotfiles/.config/hypr/
...
```

## Troubleshooting

### SSH-Verbindung schlägt fehl
```bash
ssh-copy-id user@host
```

### Ansible Galaxy Collections fehlen
```bash
ansible-galaxy install -r requirements.yml --force
```

### Flatpak-Apps werden nicht installiert
Stelle sicher, dass Flatpak und Flathub konfiguriert sind:
```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

### Hyprland nicht verfügbar
Auf einigen Distributionen muss Hyprland aus Source gebaut oder über zusätzliche Repositories installiert werden:
- **Fedora**: `dnf copr enable solopasha/hyprland`
- **Ubuntu**: Muss aus Source gebaut werden

## Unterschiede zu NixOS

Dieses Ansible-Playbook versucht, die NixOS-Konfiguration so gut wie möglich zu reproduzieren, aber es gibt einige Unterschiede:

1. **Paketversionen**: NixOS garantiert reproduzierbare Builds mit exakten Versionen. Ansible verwendet die Pakete aus den Distribution-Repositories.

2. **Rollback**: NixOS ermöglicht einfaches Rollback zu vorherigen Konfigurationen. Mit Ansible muss dies manuell oder über Backup-Strategien gelöst werden.

3. **Deklarative vs. Imperative**: NixOS ist vollständig deklarativ. Ansible ist primär imperativ, obwohl es idempotent ist.

4. **Systemd-Services**: Einige NixOS-spezifische Service-Konfigurationen müssen manuell angepasst werden.

## Lizenz

MIT
