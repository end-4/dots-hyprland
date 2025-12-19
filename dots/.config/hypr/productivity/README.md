# Productivity Features for Hyprland

This directory contains productivity-enhancing features for your Hyprland desktop environment:

## 📦 Features

### 🎯 Focus Mode (`focus-mode.sh`)

Block distracting applications temporarily to help you stay focused on your tasks.

**Features:**

- Automatically closes/blocks configured distracting apps (Steam, Discord, Spotify, etc.)
- Prevents new instances from opening while enabled
- Easy toggle via keybind or command
- Customizable list of blocked applications

**Usage:**

```bash
# Toggle focus mode
~/.config/hypr/productivity/focus-mode.sh toggle

# Enable focus mode
~/.config/hypr/productivity/focus-mode.sh enable

# Disable focus mode
~/.config/hypr/productivity/focus-mode.sh disable

# Check status
~/.config/hypr/productivity/focus-mode.sh status
```

**Keybinding:** `Super + Shift + F` (toggle)

**Configuration:**
Edit `~/.config/hypr/productivity/focus-mode.conf` to customize blocked applications.

---

### 👁️ Digital Wellbeing (`digital-wellbeing.py`)

Track your application usage and get reminders to take care of your health.

**Features:**

- **Application Usage Tracking**: Automatically tracks time spent in each application
- **Daily/Weekly/Monthly Statistics**: View detailed usage reports
- **Eye Care Reminders**: Implements the 20-20-20 rule (every 20 minutes, look 20 feet away for 20 seconds)
- **Break Reminders**: Regular reminders to stand up, stretch, and take breaks
- **Daily Usage Limits**: Set daily screen time limits with warnings
- **Database Storage**: All data stored in SQLite database for privacy

**Usage:**

```bash
# Start the tracking service (auto-starts on login)
python3 ~/.config/hypr/productivity/digital-wellbeing.py start

# Stop the service
python3 ~/.config/hypr/productivity/digital-wellbeing.py stop

# View today's statistics
python3 ~/.config/hypr/productivity/digital-wellbeing.py stats today

# View weekly statistics
python3 ~/.config/hypr/productivity/digital-wellbeing.py stats week

# View monthly statistics
python3 ~/.config/hypr/productivity/digital-wellbeing.py stats month
```

**Keybinding:** `Super + Shift + Ctrl + P` (show stats in terminal)

**Configuration:**
Edit `~/.config/hypr/productivity/wellbeing.json` to customize settings:

- Eye care reminder intervals
- Break reminder intervals
- Daily usage limits
- Notification preferences

---

### 🎛️ Productivity Dashboard (`productivity-dashboard.py`)

A GUI application to manage Focus Mode and Digital Wellbeing settings.

**Features:**

- Toggle Focus Mode on/off
- View blocked applications list
- Start/stop Digital Wellbeing service
- View real-time usage statistics
- Configure reminder settings
- Set daily usage limits

**Usage:**

```bash
python3 ~/.config/hypr/productivity/productivity-dashboard.py
```

**Keybinding:** `Super + Shift + P`

---

## 📋 Installation

These features are automatically installed with the dots-hyprland setup script. If you need to set them up manually:

1. **Make scripts executable:**

```bash
chmod +x ~/.config/hypr/productivity/focus-mode.sh
chmod +x ~/.config/hypr/productivity/digital-wellbeing.py
chmod +x ~/.config/hypr/productivity/productivity-dashboard.py
```

2. **Install dependencies:**

   - Python 3
   - GTK 3 (for GUI)
   - python-gobject
   - jq
   - sqlite3
   - libnotify

3. **Start Digital Wellbeing service:**

```bash
python3 ~/.config/hypr/productivity/digital-wellbeing.py start
```

The service will auto-start on subsequent logins (configured in `~/.config/hypr/custom/execs.conf`).

---

## ⚙️ Configuration

### Focus Mode Configuration

Edit `~/.config/hypr/productivity/focus-mode.conf`:

```bash
BLOCKED_APPS=(
    "discord"
    "steam"
    "spotify"
    # Add your apps here
)

FOCUS_DURATION=25  # Pomodoro duration in minutes
```

### Digital Wellbeing Configuration

Configuration is stored in JSON format at `~/.config/hypr/productivity/wellbeing.json`:

```json
{
  "eye_care": {
    "enabled": true,
    "interval": 1200, // 20 minutes
    "reminder_duration": 20,
    "distance": 20
  },
  "break_reminders": {
    "enabled": true,
    "interval": 3600, // 1 hour
    "duration": 300 // 5 minutes
  },
  "daily_limit": {
    "enabled": false,
    "hours": 8,
    "warning_threshold": 0.9
  }
}
```

---

## 📊 Data Storage

All Digital Wellbeing data is stored locally in:

- **Database**: `~/.local/share/digital-wellbeing/usage.db` (SQLite)
- **Configuration**: `~/.config/hypr/productivity/wellbeing.json`

Your data never leaves your computer. You have complete control and privacy.

---

## 🔑 Default Keybindings

| Keybinding                 | Action                      |
| -------------------------- | --------------------------- |
| `Super + Shift + F`        | Toggle Focus Mode           |
| `Super + Shift + P`        | Open Productivity Dashboard |
| `Super + Shift + Ctrl + P` | Show today's usage stats    |

---

## 🎯 How It Helps

### Focus Mode Benefits:

- **Increased Productivity**: Eliminate distractions during focused work sessions
- **Better Time Management**: Use with Pomodoro technique for structured work
- **Reduced Context Switching**: Stay in flow state longer
- **Mindful Computing**: Become aware of automatic distraction habits

### Digital Wellbeing Benefits:

- **Eye Health**: Regular reminders prevent eye strain and fatigue
- **Posture & Movement**: Break reminders promote physical health
- **Usage Awareness**: Track and understand your computing habits
- **Prevent Burnout**: Enforced breaks prevent excessive screen time
- **Data-Driven Insights**: Make informed decisions about digital habits

---

## 🔍 Troubleshooting

### Focus Mode not blocking apps?

- Check if the app class name is correct: `hyprctl clients`
- Ensure the script has execute permissions
- Check Hyprland config loaded correctly: `hyprctl reload`

### Digital Wellbeing not tracking?

- Verify the service is running: `ps aux | grep digital-wellbeing`
- Check logs: `journalctl --user -u digital-wellbeing` (if using systemd)
- Ensure database directory exists: `~/.local/share/digital-wellbeing/`

### Notifications not showing?

- Test notifications: `notify-send "Test" "Testing notifications"`
- Ensure notification daemon is running
- Check notification settings in wellbeing config

---

## 📚 Inspired By

This implementation is inspired by:

- **GNOME's Digital Wellbeing**: Eye care reminders and usage tracking
- **Focus/DND modes**: From various desktop environments
- **20-20-20 Rule**: Optometrist-recommended eye care practice
- **Pomodoro Technique**: Time management method

---

## 🤝 Contributing

Feel free to customize these scripts for your needs! If you add useful features, consider contributing them back to the project.

---

## 📝 License

Part of the illogical-impulse/dots-hyprland project.
Licensed under MIT License.

---

## 🆘 Support

For issues, questions, or feature requests:

- Check the main project README
- Open an issue on GitHub
- Join the community discussions

---

**Stay productive and healthy! 🚀💚**
