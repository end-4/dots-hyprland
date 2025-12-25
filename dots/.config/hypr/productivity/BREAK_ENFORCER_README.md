# Break Enforcer System

Mandatory break overlay with productivity questionnaire for Hyprland + Quickshell.

## Overview

The Break Enforcer is a digital wellbeing system that:
- Displays mandatory fullscreen breaks at configurable intervals
- Auto-pauses media players during breaks
- Collects productivity data through post-break questionnaires
- Stores responses in SQLite for analytics
- Works across multiple monitors without data duplication

## Components

### 1. `break-enforcer.qml` (Quickshell UI)
- Fullscreen break timer with countdown
- 3-question productivity questionnaire
- Media auto-pause on break start
- Multi-monitor support with duplicate prevention

### 2. `digital-wellbeing.py` (Background Service)
- Tracks application usage
- Triggers breaks at configured intervals
- Loads last break time from database (persists across restarts)
- 60-second startup grace period
- Wayland display verification

### 3. `save-break-response.py` (Database Handler)
- Saves questionnaire responses to SQLite
- Updates daily statistics
- Calculates productivity scores

### 4. `productivity-dashboard.py` (Settings GUI)
- GTK interface for configuration
- Toggle break reminders on/off
- View usage statistics
- Preserves nested config format

### 5. `break-questions.json` (Question Definitions)
- JSON schema for questions and answers
- Supports scoring and versioning
- Currently not dynamically loaded (TODO)

## Database Schema

### `break_responses` Table
```sql
CREATE TABLE break_responses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TIMESTAMP NOT NULL,
    break_type TEXT NOT NULL,  -- "eye_care" or "break_reminder"
    duration INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    answer_id INTEGER,
    answer_text TEXT,  -- Only for text-type questions
    date TEXT NOT NULL
)
```

### `break_stats` Table
```sql
CREATE TABLE break_stats (
    date TEXT PRIMARY KEY,
    eye_care_count INTEGER DEFAULT 0,
    break_reminder_count INTEGER DEFAULT 0,
    avg_productivity_score REAL DEFAULT 0,
    compliance_rate REAL DEFAULT 0
)
```

## Configuration

**Location:** `~/.config/hypr/productivity/wellbeing.json`

**Format:**
```json
{
    "eye_care": {
        "enabled": true,
        "interval": 1200,  // 20 minutes
        "duration": 20     // 20 seconds
    },
    "break_reminders": {
        "enabled": true,
        "interval": 3600,  // 1 hour
        "duration": 300    // 5 minutes
    },
    "tracking": {
        "idle_threshold": 180,
        "update_interval": 30
    }
}
```

## Usage

### Start Service
```bash
python3 ~/.config/hypr/productivity/digital-wellbeing.py start
```

### Stop Service
```bash
python3 ~/.config/hypr/productivity/digital-wellbeing.py stop
```

### Test Break Enforcer
```bash
# 5-second break for testing
TESTING=1 BREAK_DURATION=5 qs -p ~/.config/hypr/productivity/break-enforcer.qml
```

### View Statistics
```bash
python3 ~/.config/hypr/productivity/digital-wellbeing.py stats today
python3 ~/.config/hypr/productivity/digital-wellbeing.py stats week
```

## Deployment

Use the deployment script to copy files from repo to active config:
```bash
./deploy-break-enforcer.sh
```

## Multi-Monitor Support

The system uses a `responsesSaved` flag to prevent duplicate database writes:
- Quickshell Variants creates one window per screen
- First monitor to save sets the flag
- Other monitors see the flag and skip saving
- All monitors close after responses are saved

## Recent Fixes

### 1. Config Persistence (Dec 23)
- **Problem:** Dashboard was overwriting new nested config format
- **Solution:** Load existing config, update only `enabled` flags

### 2. Break Timer Reset (Dec 23)
- **Problem:** Timers reset to current time on service restart
- **Solution:** Load last break timestamp from `break_responses` table

### 3. Startup Crashes (Dec 24)
- **Problem:** Quickshell crashes if launched too early during boot
- **Solution:** 60-second grace period + Wayland display verification

### 4. Stale PID Files (Dec 25)
- **Problem:** Service won't start after reboot due to stale PID
- **Solution:** Use `os.kill(pid, 0)` to verify process exists

### 5. Duplicate Responses (Dec 25)
- **Problem:** 6 responses saved instead of 3 on dual monitor setup
- **Solution:** Global `responsesSaved` flag at root level

## Files

```
~/.config/hypr/productivity/
├── break-enforcer.qml          # Quickshell break UI
├── break-questions.json        # Question definitions
├── digital-wellbeing.py        # Background service
├── save-break-response.py      # Database handler
├── productivity-dashboard.py   # GTK settings GUI
└── wellbeing.json             # Configuration

~/.local/share/digital-wellbeing/
└── usage.db                    # SQLite database
```

## TODO

- [ ] Load questions dynamically from `break-questions.json`
- [ ] Add question versioning system
- [ ] Create analytics dashboard
- [ ] Fix Python 3.12 datetime adapter deprecation warnings
- [ ] Add break skip functionality with productivity penalty
- [ ] Implement daily usage limits

## Troubleshooting

### Break doesn't trigger
- Check if service is running: `systemctl --user status digital-wellbeing.service`
- Verify last break time: `sqlite3 ~/.local/share/digital-wellbeing/usage.db "SELECT * FROM break_responses ORDER BY timestamp DESC LIMIT 1"`
- Check grace period (60s after service start)

### Duplicate responses
- Ensure you're using the latest `break-enforcer.qml` with `responsesSaved` flag
- Check database: `sqlite3 ~/.local/share/digital-wellbeing/usage.db "SELECT COUNT(*) FROM break_responses WHERE date = date('now', 'localtime') GROUP BY timestamp"`

### Service won't start
- Check for stale PID: `cat ~/.local/share/digital-wellbeing/wellbeing.pid`
- Remove if process doesn't exist: `rm ~/.local/share/digital-wellbeing/wellbeing.pid`
- Restart: `systemctl --user restart digital-wellbeing.service`

## License

Part of dots-hyprland configuration repository.
