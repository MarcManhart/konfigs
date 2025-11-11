# NetworkManager USB-C Dock Fallback Konfiguration

## Problem
Beim Abziehen des USB-C Docks (mit Ethernet) verlor das System die Netzwerkverbindung, da WiFi nicht automatisch aktiviert wurde. Zusätzlich froren die GNOME Network Settings ein.

## Lösung
Die Konfiguration in `default.nix` implementiert:

1. **Automatische WiFi-Aktivierung beim Ethernet-Disconnect**
   - NetworkManager Dispatcher-Script überwacht Ethernet-Verbindungen
   - Aktiviert WiFi automatisch wenn Ethernet getrennt wird

2. **Verbindungsprioritäten**
   - Ethernet: Priorität 200, Route-Metrik 100 (bevorzugt)
   - WiFi: Priorität 100, Route-Metrik 600 (Fallback)

3. **Parallel-Betrieb**
   - WiFi läuft parallel zu Ethernet
   - Sofortige Fallback-Verbindung verfügbar

## Nach dem Rebuild
Nach `sudo nixos-rebuild switch` werden:
- Die Prioritäten automatisch gesetzt
- WiFi parallel aktiviert
- Das Dispatcher-Script installiert

## Manuell Testen
```bash
# Zeige aktuelle Verbindungen
nmcli device status

# Zeige Prioritäten
nmcli -f NAME,AUTOCONNECT,AUTOCONNECT-PRIORITY connection show

# Zeige Routing
ip route show

# Logs überwachen
journalctl -u NetworkManager -f
```

## Erwartetes Verhalten
- **Dock angeschlossen:** Ethernet aktiv (metric 100), WiFi aktiv (metric 600)
- **Dock abgezogen:** WiFi übernimmt sofort (metric 600), keine Unterbrechung
- **GNOME Settings:** Keine Freezes mehr

## WiFi-Passwort
Das WiFi-Passwort bleibt in der bestehenden NetworkManager-Konfiguration gespeichert (`/etc/NetworkManager/system-connections/`). Die NixOS-Konfiguration ändert nur Prioritäten und Metriken, nicht die Credentials.
