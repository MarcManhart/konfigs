# NetworkManager USB-C Dock Fallback Konfiguration

## Problem
Beim Abziehen des USB-C Docks (mit Ethernet) verlor das System die Netzwerkverbindung, da WiFi nicht automatisch aktiviert wurde. Zusätzlich froren die GNOME Network Settings ein.

## Ursache
- WiFi war nicht parallel zu Ethernet aktiv
- Beim Dock-Disconnect gab es keine Fallback-Verbindung
- GNOME Keyring war beim Boot noch nicht bereit, wenn NetworkManager WiFi aktivieren wollte

## Lösung
Die Konfiguration in `default.nix` implementiert einen **systemd user service**, der:

1. **NACH dem GNOME-Login läuft** (wenn Keyring verfügbar ist)
2. **Verbindungsprioritäten und Metriken setzt:**
   - Ethernet: Priorität 200, Route-Metrik 100 (bevorzugt)
   - WiFi: Priorität 100, Route-Metrik 600 (Fallback)

## Setup (einmalig)
**WiFi muss einmal manuell aktiviert werden:**
```bash
nmcli connection up "Blinx"
```

Danach bleibt WiFi automatisch aktiv und verbindet sich beim Neustart.

## Nach dem Rebuild
Nach `sudo nixos-rebuild switch` und Login werden automatisch die Metriken gesetzt.

## Testen
```bash
# Zeige aktuelle Verbindungen
nmcli device status

# Zeige Prioritäten
nmcli -f NAME,AUTOCONNECT,AUTOCONNECT-PRIORITY connection show | grep -E "NAME|Blinx|Kabel"

# Zeige Default-Routen (niedrigere metric = bevorzugt)
ip route show | grep default

# User-Service Status prüfen
systemctl --user status networkmanager-connection-metrics.service
```

## Erwartetes Verhalten
- **Dock angeschlossen:** Ethernet aktiv (metric 100), WiFi aktiv (metric 600)
- **Dock abgezogen:** WiFi übernimmt sofort, keine Unterbrechung
- **GNOME Settings:** Keine Freezes mehr

## Wichtig
- WiFi-Passwort bleibt in `/etc/NetworkManager/system-connections/` gespeichert
- Die NixOS-Konfiguration ändert nur Prioritäten/Metriken, keine Credentials
- Der Service läuft als User-Service (nicht System-Service) um Keyring-Probleme zu vermeiden
