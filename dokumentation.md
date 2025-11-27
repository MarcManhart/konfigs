# Dokumentation: NixOS-Konfiguration Entscheidungen

Diese Datei dokumentiert wichtige Konfigurationsentscheidungen und deren Hintergründe.
Sie dient als Referenz für zukünftige Änderungen und Troubleshooting.

---

## MediaTek MT7925 WiFi-Stabilität

**Datum:** 2025-11-26
**Datei:** `hosts/BLX-INV-28/default.nix` (Zeilen 38-122)
**Betroffener Host:** BLX-INV-28 (host-spezifisch, da nur dieser den MT7925 Chip hat)

### Problem

Der Rechner fror regelmäßig komplett ein, wenn er mit dem WLAN "Blinx" verbunden war:
- GNOME reagierte nicht mehr
- Terminal-Befehle hingen nach Eingabe
- Browser lud ewig
- Nur Hard-Reset (PC killen) half

### Analyse der System-Logs

```
journalctl -b -1 --priority=0..4
```

**Kernfunde:**

1. **Blockierte Kernel-Tasks** (um 14:38):
   ```
   INFO: task NetworkManager:1629 blocked for more than 122 seconds.
   ieee80211_ifa_changed+0x6f/0xf0 [mac80211]
   ```

2. **Kaskaden-Effekt** - Folgende Prozesse blockierten ebenfalls:
   - `avahi-daemon`
   - `wpa_supplicant`
   - `syncthing` (mehrere Threads)
   - `.xdg-desktop-po`
   - `.goa-daemon-wra`
   - `.evolution-cale`

3. **Suspend-Probleme**:
   ```
   Freezing user space processes failed after 20.004 seconds (28 tasks refusing to freeze)
   ```

4. **WLAN-Hardware identifiziert**:
   ```
   DRIVER=mt7925e
   PCI_ID=14C3:7925
   ```

### Ursache

Der **MediaTek MT7925** ist ein WiFi 7 Chip mit relativ neuem Treiber (`mt7925e`).
Bekannte Probleme:

1. **Power-Save Deadlocks**: Der Treiber versucht den Chip in Stromsparmodus zu versetzen, aber der Chip antwortet nicht mehr korrekt.

2. **AP-Roaming**: Das WLAN "Blinx" hat mehrere Access Points (5GHz, 6GHz). Der Treiber hat Probleme beim Wechsel zwischen diesen.

3. **IP-Konfiguration**: Die Funktion `ieee80211_ifa_changed` im mac80211-Subsystem blockiert bei IP-Adressänderungen.

### Implementierte Lösungen

#### 1. NetworkManager WiFi Power-Save deaktivieren
```nix
networking.networkmanager.wifi.powersave = false;
```
**Warum:** Power-Save ist die Hauptursache für Deadlocks. Ohne Power-Save bleibt der Chip permanent aktiv und antwortet zuverlässig.

#### 2. Udev-Regel für Hardware Power-Management
```nix
services.udev.extraRules = ''
  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x14c3", ATTR{device}=="0x7925", ATTR{power/control}="on"
  ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev %k set power_save off"
'';
```
**Warum:** Greift früher als NetworkManager, bereits beim Laden des Treibers.

#### 3. Systemd-Service als Fallback
```nix
systemd.services.wifi-powersave-off = { ... };
```
**Warum:** Falls Udev-Regel nicht greift oder der Treiber Power-Save später wieder aktiviert.

#### 4. NetworkManager Dispatcher Script
**Warum:** Deaktiviert Power-Save nach jedem Reconnect (z.B. nach AP-Wechsel).

#### 5. Sysctl TCP Keepalive
```nix
boot.kernel.sysctl = {
  "net.ipv4.tcp_keepalive_time" = 60;
  "net.ipv4.tcp_keepalive_intvl" = 10;
  "net.ipv4.tcp_keepalive_probes" = 6;
};
```
**Warum:** Stabilere TCP-Verbindungen bei kurzzeitigen WLAN-Aussetzern.

### Nicht implementiert (aber verfügbar)

#### iwd statt wpa_supplicant
Als Alternative zu `wpa_supplicant` kann `iwd` (iNet Wireless Daemon) verwendet werden.
**Warum nicht aktiviert:** Erfordert Neukonfiguration aller WLAN-Verbindungen. Kann als nächster Schritt versucht werden, falls Power-Save-Deaktivierung nicht reicht.

Bei Bedarf in `hosts/BLX-INV-28/default.nix` hinzufügen:
```nix
networking.wireless.iwd.enable = true;
networking.networkmanager.wifi.backend = "iwd";
```

### Speicherort

Die Konfiguration ist direkt in `hosts/BLX-INV-28/default.nix` integriert (Zeilen 38-122),
da der MT7925 Chip nur in diesem Host verbaut ist. Für andere Hosts mit gleichem Chip
kann der entsprechende Abschnitt kopiert werden.

### Verifizierung nach Neustart

Nach `sudo nixos-rebuild switch` prüfen:

```bash
# Power-Save Status prüfen (sollte "off" sein)
iw dev wlp194s0 get power_save

# NetworkManager-Einstellungen prüfen
nmcli -f WIFI-PROPERTIES device show wlp194s0

# Systemd-Service Status
systemctl status wifi-powersave-off

# Bei Problemen: Logs checken
journalctl -u wifi-powersave-off
journalctl -u NetworkManager | grep -i power
```

### Referenzen

- [Arch Wiki: Wireless Power Saving](https://wiki.archlinux.org/title/Network_configuration/Wireless#Power_saving)
- [Kernel Docs: Power Management](https://wireless.wiki.kernel.org/en/users/documentation/power_management)
- Kernel-Logs: `journalctl -b -1 --priority=0..4`

---

## Druckerdienst (CUPS)

**Datum:** 2025-11-26
**Datei:** `modules/desktop.nix`
**Betrifft:** Alle Desktop-Hosts

### Konfiguration

- **CUPS** aktiviert mit Web-Interface unter http://localhost:631
- **Treiber:**
  - `gutenprint` – Universell (Canon, Epson, HP, Lexmark, etc.)
  - `hplip` – HP Drucker (inkl. Scanner-Support)
  - `brlaser` – Brother Laser-Drucker
- **Avahi** für automatische Netzwerkdrucker-Erkennung (mDNS/Bonjour)

### Drucker hinzufügen

1. **GNOME-Einstellungen** → Drucker → Drucker hinzufügen
2. **Oder via CUPS Web-Interface:** http://localhost:631 → Verwaltung → Drucker hinzufügen
3. **Netzwerkdrucker** werden automatisch erkannt (Avahi/mDNS)

### Bei Problemen

```bash
# CUPS-Status prüfen
systemctl status cups

# Drucker-Logs
journalctl -u cups -f

# Avahi-Status (Netzwerkerkennung)
systemctl status avahi-daemon
```

---

## Weitere Einträge

*(Hier zukünftige Dokumentationen hinzufügen)*
