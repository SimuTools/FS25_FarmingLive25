# FarmingLive25

Bringt zufällige Chaos-Events in den Farming Simulator 25 – vom blockierten Motor über invertierte Steuerung bis zum Reifenplatzer. Alle Events lassen sich direkt im Spiel per Tastendruck oder Konsole auslösen. Optional kann FarmingLive zusammen mit einer separaten Twitch-App verwendet werden, damit Zuschauer diese Events per Chat-Befehl oder Kanalpunkten selbst auslösen können.

## Inhaltsverzeichnis

- [Installation](#installation)
- [Event-Menü (Taste 0)](#event-menü-taste-0)
- [Events im Überblick](#events-im-überblick)
- [Konsolenbefehle](#konsolenbefehle)
  - [Event-Steuerung](#event-steuerung)
  - [Warteschlange](#warteschlange)
  - [Konfiguration](#konfiguration)
  - [Nachrichten-System](#nachrichten-system)
- [Twitch-Integration (optional)](#twitch-integration-optional)
  - [Twitch-Chat-Befehle](#twitch-chat-befehle)
- [Mehrsprachigkeit](#mehrsprachigkeit)
- [Multiplayer](#multiplayer)
- [Support & Feedback](#support--feedback)

## Installation

1. Mod wie gewohnt über den ModHub oder als `.zip` im `mods`-Ordner von Farming Simulator 25 installieren.
2. Im Spiel aktivieren.
3. Fertig – der Mod funktioniert direkt ohne weitere Einrichtung.

Die optionale Twitch-App wird **nicht** benötigt, damit der Mod funktioniert – sie erweitert ihn nur um die Zuschauer-Interaktion (siehe [Twitch-Integration](#twitch-integration-optional)).

## Event-Menü (Taste 0)

Der einfachste Weg, ein Event auszulösen: Taste **`0`** drücken. Es öffnet sich ein Auswahlmenü, in dem du mit den Pfeilen ein Event auswählst und mit **OK** auslöst.

## Events im Überblick

Alle Events haben eine zufällige Laufzeit/Intensität (über die Config einstellbar, siehe [Konfiguration](#konfiguration)).

| Event | Beschreibung |
|---|---|
| `adjustDiesel` | Diesel-Füllstand zufällig ändern |
| `AdjustMoney` | Geld zufällig ändern |
| `AttachmentDrop` | Anbaugerät abwerfen |
| `lockDoor` | Motor blockieren & Tür verriegeln |
| `BlockEngine` | Motor blockieren |
| `cameraFun` | Kamera-Spaß |
| `lockInteriorCam` | In Innenkamera einsperren |
| `ClearAll` | Tank leeren |
| `detachAll` | Alle Anbaugeräte abkoppeln |
| `BlockTab` | Fahrzeugwechsel sperren |
| `DriveThat` | Zufälliges Fahrzeug erzwingen |
| `SetDrivingDirection` | Fahrtrichtung erzwingen |
| `FadeScreen` | Bildschirm abdunkeln |
| `FlatTire` | Reifenplatzer |
| `SteerBan` | Lenkrichtung verbieten |
| `HonkiHonkiHonk` | Hupe aktivieren |
| `InvertControls` | Steuerung invertieren |
| `launchVehicle` | Fahrzeug in die Luft schießen |
| `MathGame` | Matherätsel |
| `Uselessnotifi` | Nutzlose Benachrichtigung |
| `showSimu` | Simu-Nachricht anzeigen |
| `showHi` | Grußnachricht anzeigen |
| `RandomCam` | Zufällige Kamera |
| `RandomSteer` | Zufällige Lenkstörung |
| `RandomTabTrap` | Tab-Falle (mehrfacher Fahrzeugwechsel) |
| `SetBroken` | Fahrzeug kaputt setzen |
| `SetDirt` | Fahrzeug einschmutzen |
| `SpeedLimit` | Geschwindigkeitsbegrenzung setzen |
| `MassChange` | Gewicht temporär erhöhen |
| `SetRandomTime` | Zufällige Uhrzeit setzen |
| `TireParty` | Reifen-Hüpfparty |
| `TireChaos` | Reifen-Chaos (zufällig FlatTire oder TireParty) |
| `SwitchSeat` | Fahrzeug wechseln |
| `LockOut` | Aus Fahrzeug aussperren |
| `GoWalk` | Spieler zum Laufen zwingen |
| `toggleWipers` | Scheibenwischer umschalten |
| `UselessBox` | Infobox anzeigen |

## Konsolenbefehle

Konsole im Spiel öffnen (Standard: `°`/`^` oder in den Spieleinstellungen nachschauen) und folgende Befehle nutzen.

### Event-Steuerung

| Befehl | Beschreibung |
|---|---|
| `flEventList` | Listet alle registrierten Event-Commands |
| `flEventRun <command> [player] [input]` | Startet ein Event manuell, z.B. `flEventRun MathGame Console` |
| `flEventStop` | Stoppt das aktive Event bestmöglich und leert alle Warteschlangen |
| `flEventDisable <command>` | Deaktiviert ein Event-Command |
| `flEventEnable <command>` | Aktiviert ein Event-Command wieder |
| `flEventStatus` | Zeigt Status von aktivem Event und Warteschlangen |
| `flEventCooldowns` | Zeigt letzte Ausführungen / Cooldowns je Event |

### Warteschlange

| Befehl | Beschreibung |
|---|---|
| `flQueueList` | Listet XML-, Event- und Fahrzeug-Warteschlangen |
| `flQueueClear` | Leert alle Warteschlangen |
| `flQueueRemove <index>` | Entfernt einen Warteschlangen-Eintrag nach Index |
| `flQueuePause` | Pausiert die Warteschlangen |
| `flQueueResume` | Setzt die Warteschlangen fort |
| `flQueueRunNext` | Führt den nächsten Warteschlangen-Eintrag sofort aus |

### Konfiguration

| Befehl | Beschreibung |
|---|---|
| `flCfgGet <pfad>` | Liest einen Config-Wert, z.B. `flCfgGet setSpeed.maxspeed` |
| `flCfgSet <pfad> <wert>` | Setzt einen Config-Wert, z.B. `flCfgSet setSpeed.maxspeed 22` |
| `flCfgList [section]` | Listet Config-Werte, z.B. `flCfgList tireParty` |
| `flCfgSearch <text>` | Sucht Config-Pfade, z.B. `flCfgSearch steer` |
| `flCfgReload` | Lädt die Runtime-Config neu aus der XML |
| `flCfgFile` | Zeigt den Pfad der Config-Datei |
| `flCfgHelp` | Zeigt Hilfe zu allen Config-Commands |

Die Config-Datei liegt unter `.../modSettings/FS25_FarmingLive/FarmingLiveConfig.xml` und wird beim ersten Start automatisch angelegt.

### Nachrichten-System

FarmingLive hat ein eigenes Nachrichten-/HUD-System mit vielen Anzeige-Modi.

| Befehl | Beschreibung |
|---|---|
| `flMessageMode <mode1[+mode2...]>` | Setzt den/die aktiven Anzeige-Modi, z.B. `flMessageMode warning+banner` |
| `flMessageTest <text>` | Zeigt eine Testnachricht im aktuellen Modus |
| `flMessageClear` | Blendet alle aktiven Nachrichten aus |
| `flMessagePos <mode> <x> <y>` | Setzt die Position eines Modus |
| `flMessageScale <mode> <wert>` | Setzt die Textgröße eines Modus |
| `flMessageWidth <mode> <w> <h>` | Setzt die Breite/Höhe eines Modus |
| `flMessageAlign <mode> <left\|center\|right>` | Setzt die Textausrichtung |
| `flMessageText <mode> <r> <g> <b> <a>` | Setzt die Textfarbe (0–255) |
| `flMessageBg <mode> <r> <g> <b> <a>` | Setzt die Hintergrundfarbe (0–255) |
| `flMessageFrame <mode> <on\|off> <r> <g> <b> <a>` | Aktiviert/deaktiviert einen Rahmen und setzt dessen Farbe |
| `flMessageReset <mode\|all>` | Setzt einen Modus oder alle Modi auf Standard zurück |

**Verfügbare Modi:** `warning` (Standard), `headline`, `banner`, `top`, `topSlim`, `big`, `center`, `lowCenter`, `subtitle`, `objective`, `midLeft`, `midRight`, `leftToast`, `rightToast`, `toast`, `mini`, `slim`, `twitch`, `danger`, `success`, `radio`, `chip`, `neon`

## Twitch-Integration (optional)

FarmingLive kann optional zusammen mit einer separaten **FarmingLive-App** (EXE) verwendet werden. Diese verbindet sich mit deinem Twitch-Chat und schreibt Befehle in eine lokale Datei, die der Mod ausliest und als Event auslöst – dafür ist **keine** Verbindung des Mods selbst zum Internet nötig.

📥 **Download der App:** *[Github-Link hier einfügen]*

Ohne die App funktioniert der Mod vollständig eigenständig über das Event-Menü und die Konsole.

### Twitch-Chat-Befehle

Diese Befehle tippen deine Zuschauer in deinen Twitch-Chat (nicht im Spiel):

**Punkte & Hilfe**
```
!flpunkte
!flhelp
```

**Sofort-Spiele**
```
!gamble 100
!gamble alle
!roulette 100 rot
!roulette 100 schwarz
!roulette 100 17
!slots 100
!fish
!steal <user>
```

**Duell**
```
!duel <user> 100
!accept
```

**Coup (Gruppen-Event)**
```
!heist join 100
```

**Crash-Game**
```
!silo 100
!silo cashout
```

**Aussaat (Langzeit-Investment)**
```
!saatgut 100
```

**Lotterie**
```
!lottery 5
!lotterie 5
```

**Schrott (Trostpreis-Währung)**
```
!schrott
!schrott einlösen
```

**Kuh-Karten**
```
!kuh kaufen
!kuh verkaufen <name>
!kuh inventar
```

**Kuhrennen**
```
!kuhrennen <kartenname>
!kuhrennen <kartenname> 100
!kuhrennen <kartenname> karte
```

**Event-Einlösung mit Punkten**
```
!fllösen <eventname>
!flspin
```

Ein-/Ausschalten und Feintuning der einzelnen Chat-Games: **FarmingLive-App → Einstellungen → "Chat Games ..."-Kategorien**.

## Mehrsprachigkeit

FarmingLive unterstützt aktuell:
- 🇩🇪 Deutsch
- 🇬🇧 Englisch
- 🇫🇷 Französisch

Die Sprache wird automatisch anhand der Spielsprache erkannt.

## Multiplayer

FarmingLive ist vollständig multiplayer-fähig. Events werden serverseitig synchronisiert, sodass alle Spieler auf einem Server dieselben Effekte sehen.

## Support & Feedback

- 💬 Discord: *[Link einfügen]*
- 🐦 Twitch: *[Link einfügen]*
- 🐛 Bugs & Feature-Wünsche: über die [Issues](../../issues) dieses Repos

---

Danke, dass du FarmingLive nutzt! 🚜
