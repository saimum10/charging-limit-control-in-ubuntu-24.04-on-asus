# 🔋 ASUS TUF Battery Control

A lightweight battery charge limit controller for ASUS TUF laptops on Ubuntu — no extra software required.

---

## 📋 Compatibility

| | Details |
|---|---|
| **Device** | ASUS TUF Gaming Series |
| **Tested Model** | ASUS TUF FX505GM |
| **OS** | Ubuntu 22.04 / 24.04 (GNOME) |
| **Kernel** | 5.4+ (with `asus-wmi` module) |

> ⚠️ May work on other ASUS models that expose `/sys/class/power_supply/BAT0/charge_control_end_threshold`

---

## ✨ Features

- Set charging limit to **60% / 70% / 80%**
- Remove charging limit (reset to 100%)
- View current charging limit
- **Persists after reboot** via systemd service
- Single `.desktop` file — no installation needed

---

## 🚀 Usage

**1. Download** `asuscontrol.desktop` and move it to Desktop

```bash
mv asuscontrol.desktop ~/Desktop/
```

**2. Make it executable**

```bash
chmod +x ~/Desktop/asuscontrol.desktop
```

**3. Allow launching**

> Right-click the file → **Allow Launching**

**4. Double-click** to run — enter your sudo password in the terminal → use the menu

---

## 🖥️ Menu Options

```
1) Set Charging Limit - 60%
2) Set Charging Limit - 70%
3) Set Charging Limit - 80%
4) Charging Limit Off
5) View Charging Limit
0) Exit
```

---

## ⚙️ How It Works

- Writes the limit to `/sys/class/power_supply/BAT0/charge_control_end_threshold`
- Creates a **systemd service** to restore the limit on every boot
- Single `.desktop` file with embedded script — no external files needed

---

## 📦 Requirements

- `gnome-terminal`
- `sudo` access
- `systemd`

---

## 📄 License

MIT License — free to use and modify.
