# FarmingLive25

Adds random chaos events to Farming Simulator 25 – from a blocked engine and inverted controls to a flat tire. All events can be triggered directly in-game via a hotkey or the console. Optionally, FarmingLive can be used together with a separate Twitch app so viewers can trigger these events via chat commands or channel points.

## Table of Contents

- [Installation](#installation)
- [Event Menu (Key 0)](#event-menu-key-0)
- [Events Overview](#events-overview)
- [Console Commands](#console-commands)
  - [Event Control](#event-control)
  - [Queue](#queue)
  - [Configuration](#configuration)
  - [Message System](#message-system)
- [Twitch Integration (optional)](#twitch-integration-optional)
  - [Twitch Chat Commands](#twitch-chat-commands)
- [Languages](#languages)
- [Multiplayer](#multiplayer)
- [Support & Feedback](#support--feedback)

## Installation

1. Install the mod as usual via ModHub or as a `.zip` in the Farming Simulator 25 `mods` folder.
2. Enable it in-game.
3. Done – the mod works right away without any extra setup.

The optional Twitch app is **not** required for the mod to work – it only extends it with viewer interaction (see [Twitch Integration](#twitch-integration-optional)).

## Event Menu (Key 0)

The easiest way to trigger an event: press key **`0`**. A selection menu opens where you can pick an event with the arrows and trigger it with **OK**.

## Events Overview

All events have a randomized duration/intensity (configurable, see [Configuration](#configuration)).

| Event | Description |
|---|---|
| `adjustDiesel` | Randomize diesel level |
| `AdjustMoney` | Randomly change money |
| `AttachmentDrop` | Drop an attachment |
| `lockDoor` | Block engine & lock door |
| `BlockEngine` | Block engine |
| `cameraFun` | Camera fun |
| `lockInteriorCam` | Lock inside interior camera |
| `ClearAll` | Empty fuel tank |
| `detachAll` | Detach all implements |
| `BlockTab` | Block vehicle switching |
| `DriveThat` | Force random vehicle |
| `SetDrivingDirection` | Enforce driving direction |
| `FadeScreen` | Fade screen |
| `FlatTire` | Flat tire |
| `SteerBan` | Forbid steering direction |
| `HonkiHonkiHonk` | Trigger horn |
| `InvertControls` | Invert controls |
| `launchVehicle` | Launch vehicle |
| `MathGame` | Math game |
| `Uselessnotifi` | Useless notification |
| `showSimu` | Show Simu message |
| `showHi` | Show greeting |
| `RandomCam` | Random camera |
| `RandomSteer` | Random steering interference |
| `RandomTabTrap` | Tab trap (forced vehicle switching) |
| `SetBroken` | Break vehicle |
| `SetDirt` | Get vehicle dirty |
| `SpeedLimit` | Set speed limit |
| `MassChange` | Temporarily increase mass |
| `SetRandomTime` | Set random time |
| `TireParty` | Tire bounce party |
| `TireChaos` | Random tire chaos (randomly picks FlatTire or TireParty) |
| `SwitchSeat` | Switch vehicle |
| `LockOut` | Lock player out of vehicle |
| `GoWalk` | Force player to walk |
| `toggleWipers` | Toggle wipers |
| `UselessBox` | Show info box |

## Console Commands

Open the in-game console (default: `°`/`^`, check your game settings) and use the following commands.

### Event Control

| Command | Description |
|---|---|
| `flEventList` | Lists all registered event commands |
| `flEventRun <command> [player] [input]` | Manually starts an event, e.g. `flEventRun MathGame Console` |
| `flEventStop` | Best-effort stop of the active event and clears all queues |
| `flEventDisable <command>` | Disables an event command |
| `flEventEnable <command>` | Re-enables an event command |
| `flEventStatus` | Shows the status of the active event and queues |
| `flEventCooldowns` | Shows last runs / cooldowns per event |

### Queue

| Command | Description |
|---|---|
| `flQueueList` | Lists XML, event, and vehicle queues |
| `flQueueClear` | Clears all queues |
| `flQueueRemove <index>` | Removes a queue entry by index |
| `flQueuePause` | Pauses the queues |
| `flQueueResume` | Resumes the queues |
| `flQueueRunNext` | Immediately runs the next queue entry |

### Configuration

| Command | Description |
|---|---|
| `flCfgGet <path>` | Reads a config value, e.g. `flCfgGet setSpeed.maxspeed` |
| `flCfgSet <path> <value>` | Sets a config value, e.g. `flCfgSet setSpeed.maxspeed 22` |
| `flCfgList [section]` | Lists config values, e.g. `flCfgList tireParty` |
| `flCfgSearch <text>` | Searches config paths, e.g. `flCfgSearch steer` |
| `flCfgReload` | Reloads the runtime config from the XML file |
| `flCfgFile` | Shows the path of the config file |
| `flCfgHelp` | Shows help for all config commands |

The config file is located at `.../modSettings/FS25_FarmingLive/FarmingLiveConfig.xml` and is created automatically on first start.

### Message System

FarmingLive has its own message/HUD system with many display modes.

| Command | Description |
|---|---|
| `flMessageMode <mode1[+mode2...]>` | Sets the active display mode(s), e.g. `flMessageMode warning+banner` |
| `flMessageTest <text>` | Shows a test message in the current mode |
| `flMessageClear` | Hides all active messages |
| `flMessagePos <mode> <x> <y>` | Sets the position of a mode |
| `flMessageScale <mode> <value>` | Sets the text size of a mode |
| `flMessageWidth <mode> <w> <h>` | Sets the width/height of a mode |
| `flMessageAlign <mode> <left\|center\|right>` | Sets the text alignment |
| `flMessageText <mode> <r> <g> <b> <a>` | Sets the text color (0–255) |
| `flMessageBg <mode> <r> <g> <b> <a>` | Sets the background color (0–255) |
| `flMessageFrame <mode> <on\|off> <r> <g> <b> <a>` | Enables/disables a frame and sets its color |
| `flMessageReset <mode\|all>` | Resets one mode or all modes to default |

**Available modes:** `warning` (default), `headline`, `banner`, `top`, `topSlim`, `big`, `center`, `lowCenter`, `subtitle`, `objective`, `midLeft`, `midRight`, `leftToast`, `rightToast`, `toast`, `mini`, `slim`, `twitch`, `danger`, `success`, `radio`, `chip`, `neon`

## Twitch Integration (optional)

FarmingLive can optionally be used together with a separate **FarmingLive app** (EXE). It connects to your Twitch chat and writes commands into a local file, which the mod reads and turns into events – no internet connection is required by the mod itself.

📥 **App download:** *[insert Github link here]*

Without the app, the mod works fully standalone through the event menu and the console.

### Twitch Chat Commands

Your viewers type these commands in your Twitch chat (not in the game):

**Points & Help**
```
!flpunkte
!flhelp
```

**Instant Games**
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

**Duel**
```
!duel <user> 100
!accept
```

**Heist (Group Event)**
```
!heist join 100
```

**Crash Game**
```
!silo 100
!silo cashout
```

**Sowing (Long-Term Investment)**
```
!saatgut 100
```

**Lottery**
```
!lottery 5
!lotterie 5
```

**Scrap (Consolation Currency)**
```
!schrott
!schrott einlösen
```

**Cow Cards**
```
!kuh kaufen
!kuh verkaufen <name>
!kuh inventar
```

**Cow Race**
```
!kuhrennen <cardname>
!kuhrennen <cardname> 100
!kuhrennen <cardname> karte
```

**Point-Based Event Redemption**
```
!fllösen <eventname>
!flspin
```

Enable/disable and fine-tune each chat game: **FarmingLive app → Settings → "Chat Games ..." categories**.

## Languages

FarmingLive currently supports:
- 🇬🇧 English
- 🇩🇪 German
- 🇫🇷 French

The language is detected automatically based on the game's language setting.

## Multiplayer

FarmingLive fully supports multiplayer. Events are synchronized server-side, so every player on a server sees the same effects.

## Support & Feedback

- 💬 Discord: *[insert link]*
- 🐦 Twitch: *[insert link]*
- 🐛 Bugs & feature requests: via this repo's [Issues](../../issues)

---

Thanks for using FarmingLive! 🚜
