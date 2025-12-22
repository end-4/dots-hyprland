#!/usr/bin/env python3
"""
Digital Wellbeing - Application usage tracker and eye care reminder
Features:
- Track application usage time
- Monitor daily computer usage
- Eye care reminders (20-20-20 rule)
- Break reminders
- Usage statistics and reports
"""

import json
import sqlite3
import subprocess
import time
import os
from datetime import datetime, timedelta
from pathlib import Path
import sys
import signal

# Configuration
HOME = Path.home()
CONFIG_DIR = HOME / ".config" / "hypr" / "productivity"
DATA_DIR = HOME / ".local" / "share" / "digital-wellbeing"
DB_PATH = DATA_DIR / "usage.db"
CONFIG_FILE = CONFIG_DIR / "wellbeing.json"
PID_FILE = DATA_DIR / "wellbeing.pid"

# Default configuration
DEFAULT_CONFIG = {
    "eye_care": {
        "enabled": True,
        "interval": 1200,  # 20 minutes in seconds
        "reminder_duration": 20,  # Look away for 20 seconds
        "distance": 20  # Look 20 feet away (20-20-20 rule)
    },
    "break_reminders": {
        "enabled": True,
        "interval": 3600,  # 1 hour
        "duration": 300  # 5 minutes break
    },
    "daily_limit": {
        "enabled": False,
        "hours": 8,  # Daily usage limit
        "warning_threshold": 0.9  # Warn at 90%
    },
    "tracking": {
        "enabled": True,
        "update_interval": 30,  # Update every 30 seconds
        "idle_threshold": 300  # Consider idle after 5 minutes of inactivity
    },
    "notifications": {
        "enabled": True,
        "sound": True
    }
}


class DigitalWellbeing:
    def __init__(self):
        self.setup_directories()
        self.load_config()
        self.setup_database()
        self.running = True
        self.current_window = None
        self.last_eye_care_reminder = time.time()
        self.last_break_reminder = time.time()
        self.session_start = time.time()
        self.last_activity_time = time.time()
        self.last_update_time = time.time()
        self.is_idle = False
        
    def setup_directories(self):
        """Create necessary directories"""
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        
    def load_config(self):
        """Load or create configuration"""
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE, 'r') as f:
                self.config = {**DEFAULT_CONFIG, **json.load(f)}
        else:
            self.config = DEFAULT_CONFIG
            self.save_config()
            
    def save_config(self):
        """Save configuration to file"""
        with open(CONFIG_FILE, 'w') as f:
            json.dump(self.config, f, indent=4)
            
    def setup_database(self):
        """Initialize SQLite database"""
        self.conn = sqlite3.connect(DB_PATH)
        self.cursor = self.conn.cursor()
        
        # Create tables
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS app_usage (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                app_class TEXT NOT NULL,
                app_title TEXT,
                start_time TIMESTAMP NOT NULL,
                end_time TIMESTAMP,
                duration INTEGER DEFAULT 0,
                date TEXT NOT NULL
            )
        ''')
        
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS daily_stats (
                date TEXT PRIMARY KEY,
                total_usage INTEGER DEFAULT 0,
                app_count INTEGER DEFAULT 0,
                most_used_app TEXT
            )
        ''')
        
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS reminders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT NOT NULL,
                timestamp TIMESTAMP NOT NULL,
                acknowledged BOOLEAN DEFAULT 0
            )
        ''')
        
        self.conn.commit()
        
    def get_active_window(self):
        """Get currently active window information"""
        try:
            result = subprocess.run(
                ['hyprctl', 'activewindow', '-j'],
                capture_output=True,
                text=True,
                timeout=2
            )
            if result.returncode == 0:
                data = json.loads(result.stdout)
                return {
                    'class': data.get('class', 'unknown'),
                    'title': data.get('title', 'unknown'),
                    'address': data.get('address', '')
                }
        except Exception as e:
            print(f"Error getting active window: {e}", file=sys.stderr)
        return None
    
    def check_idle_status(self):
        """Check if user is idle using hypridle or input activity"""
        try:
            # Check time since last input event
            result = subprocess.run(
                ['hyprctl', 'cursorpos'],
                capture_output=True,
                text=True,
                timeout=1
            )
            # If we can get cursor position, user is not idle
            # This is a simple check - in a real implementation, you'd track cursor movement
            current_time = time.time()
            idle_threshold = self.config['tracking']['idle_threshold']
            
            # Simple idle detection: if no window changes for idle_threshold seconds
            if current_time - self.last_activity_time > idle_threshold:
                return True
            return False
        except Exception:
            return False
    
    def mark_activity(self):
        """Mark that user activity was detected"""
        self.last_activity_time = time.time()
        if self.is_idle:
            print("User is now active")
            self.is_idle = False
        
    def track_usage(self, window):
        """Track application usage"""
        now = datetime.now()
        date_str = now.strftime('%Y-%m-%d')
        
        self.cursor.execute('''
            INSERT INTO app_usage (app_class, app_title, start_time, date)
            VALUES (?, ?, ?, ?)
        ''', (window['class'], window['title'], now, date_str))
        
        self.conn.commit()
        self.last_update_time = time.time()
        return self.cursor.lastrowid
        
    def update_usage(self, usage_id):
        """Update usage duration using time delta to prevent overcounting"""
        now = datetime.now()
        current_time = time.time()
        
        # Calculate time delta since last update
        time_delta = current_time - self.last_update_time
        
        # Only add delta if not idle and delta is reasonable (< 2 * update_interval)
        if not self.is_idle and time_delta < (self.config['tracking']['update_interval'] * 2):
            self.cursor.execute('''
                UPDATE app_usage
                SET end_time = ?,
                    duration = duration + ?
                WHERE id = ?
            ''', (now, int(time_delta), usage_id))
            
            self.conn.commit()
        
        self.last_update_time = current_time
        
    def check_eye_care_reminder(self):
        """Check if it's time for eye care reminder"""
        if not self.config['eye_care']['enabled']:
            return
            
        current_time = time.time()
        interval = self.config['eye_care']['interval']
        
        if current_time - self.last_eye_care_reminder >= interval:
            self.send_eye_care_notification()
            self.last_eye_care_reminder = current_time
            
            # Log reminder
            self.cursor.execute('''
                INSERT INTO reminders (type, timestamp)
                VALUES (?, ?)
            ''', ('eye_care', datetime.now()))
            self.conn.commit()
            
    def check_break_reminder(self):
        """Check if it's time for a break"""
        if not self.config['break_reminders']['enabled']:
            return
            
        current_time = time.time()
        interval = self.config['break_reminders']['interval']
        
        if current_time - self.last_break_reminder >= interval:
            self.send_break_notification()
            self.last_break_reminder = current_time
            
            # Log reminder
            self.cursor.execute('''
                INSERT INTO reminders (type, timestamp)
                VALUES (?, ?)
            ''', ('break', datetime.now()))
            self.conn.commit()
            
    def check_daily_limit(self):
        """Check daily usage limit"""
        if not self.config['daily_limit']['enabled']:
            return
            
        today = datetime.now().strftime('%Y-%m-%d')
        
        self.cursor.execute('''
            SELECT SUM(duration) FROM app_usage
            WHERE date = ?
        ''', (today,))
        
        result = self.cursor.fetchone()
        total_seconds = result[0] if result[0] else 0
        total_hours = total_seconds / 3600
        
        limit_hours = self.config['daily_limit']['hours']
        threshold = self.config['daily_limit']['warning_threshold']
        
        if total_hours >= limit_hours * threshold and total_hours < limit_hours:
            self.send_limit_warning(total_hours, limit_hours)
        elif total_hours >= limit_hours:
            self.send_limit_exceeded(total_hours, limit_hours)
            
    def send_eye_care_notification(self):
        """Send eye care reminder notification"""
        duration = self.config['eye_care']['reminder_duration']
        distance = self.config['eye_care']['distance']
        
        message = f"Time for eye care! 👁️\nLook {distance} feet away for {duration} seconds.\n(20-20-20 rule)"
        
        subprocess.run([
            'notify-send',
            '-a', 'Digital Wellbeing',
            '-i', 'eye-symbolic',
            '-u', 'critical',
            '-t', str(duration * 1000),
            'Eye Care Reminder',
            message
        ])
        
        if self.config['notifications']['sound']:
            subprocess.run(['paplay', '/usr/share/sounds/freedesktop/stereo/complete.oga'], 
                         stderr=subprocess.DEVNULL)
            
    def send_break_notification(self):
        """Send break reminder notification"""
        duration = self.config['break_reminders']['duration'] // 60
        
        message = f"Time for a break! 🧘\nStand up, stretch, and rest for {duration} minutes."
        
        subprocess.run([
            'notify-send',
            '-a', 'Digital Wellbeing',
            '-i', 'appointment-soon',
            '-u', 'critical',
            'Break Reminder',
            message
        ])
        
        if self.config['notifications']['sound']:
            subprocess.run(['paplay', '/usr/share/sounds/freedesktop/stereo/bell.oga'],
                         stderr=subprocess.DEVNULL)
            
    def send_limit_warning(self, current, limit):
        """Send warning about approaching daily limit"""
        remaining = limit - current
        
        message = f"You've used {current:.1f} hours today.\n{remaining:.1f} hours remaining until your daily limit."
        
        subprocess.run([
            'notify-send',
            '-a', 'Digital Wellbeing',
            '-i', 'dialog-warning',
            '-u', 'normal',
            'Daily Usage Warning',
            message
        ])
        
    def send_limit_exceeded(self, current, limit):
        """Send notification about exceeded daily limit"""
        exceeded = current - limit
        
        message = f"You've exceeded your daily limit!\nUsed: {current:.1f} hours\nLimit: {limit:.1f} hours\nOver by: {exceeded:.1f} hours"
        
        subprocess.run([
            'notify-send',
            '-a', 'Digital Wellbeing',
            '-i', 'dialog-error',
            '-u', 'critical',
            'Daily Limit Exceeded',
            message
        ])
        
    def update_daily_stats(self):
        """Update daily statistics"""
        today = datetime.now().strftime('%Y-%m-%d')
        
        # Get total usage
        self.cursor.execute('''
            SELECT SUM(duration), COUNT(DISTINCT app_class)
            FROM app_usage
            WHERE date = ?
        ''', (today,))
        
        total_usage, app_count = self.cursor.fetchone()
        
        # Get most used app
        self.cursor.execute('''
            SELECT app_class, SUM(duration) as total
            FROM app_usage
            WHERE date = ?
            GROUP BY app_class
            ORDER BY total DESC
            LIMIT 1
        ''', (today,))
        
        result = self.cursor.fetchone()
        most_used = result[0] if result else None
        
        # Update or insert daily stats
        self.cursor.execute('''
            INSERT OR REPLACE INTO daily_stats (date, total_usage, app_count, most_used_app)
            VALUES (?, ?, ?, ?)
        ''', (today, total_usage or 0, app_count or 0, most_used))
        
        self.conn.commit()
        
    def run(self):
        """Main tracking loop"""
        print("Digital Wellbeing service started")
        
        # Write PID file using proper os.getpid()
        with open(PID_FILE, 'w') as f:
            f.write(str(os.getpid()))
        
        current_usage_id = None
        last_update = time.time()
        
        try:
            while self.running:
                # Check idle status
                was_idle = self.is_idle
                self.is_idle = self.check_idle_status()
                
                if self.is_idle and not was_idle:
                    print("User is now idle")
                    # Close current tracking when going idle
                    if current_usage_id:
                        self.update_usage(current_usage_id)
                        current_usage_id = None
                        self.current_window = None
                
                # Only track if not idle
                if not self.is_idle:
                    window = self.get_active_window()
                    
                    if window and window['class'] != 'unknown':
                        # Mark activity detected
                        self.mark_activity()
                        
                        # New window or window changed
                        if self.current_window != window['class']:
                            # Close previous tracking
                            if current_usage_id:
                                self.update_usage(current_usage_id)
                                
                            # Start new tracking
                            current_usage_id = self.track_usage(window)
                            self.current_window = window['class']
                        else:
                            # Update existing tracking with time delta
                            if current_usage_id:
                                self.update_usage(current_usage_id)
                
                # Check reminders (only if not idle)
                if not self.is_idle:
                    self.check_eye_care_reminder()
                    self.check_break_reminder()
                    self.check_daily_limit()
                
                # Update daily stats every minute
                if time.time() - last_update >= 60:
                    self.update_daily_stats()
                    last_update = time.time()
                
                # Sleep for update interval
                time.sleep(self.config['tracking']['update_interval'])
                
        except KeyboardInterrupt:
            print("\nShutting down gracefully...")
        finally:
            if current_usage_id:
                self.update_usage(current_usage_id)
            self.conn.close()
            PID_FILE.unlink(missing_ok=True)
            
    def stop(self):
        """Stop the tracking service"""
        self.running = False


def start_service():
    """Start the digital wellbeing service"""
    # Check if already running
    if PID_FILE.exists():
        print("Digital Wellbeing service is already running")
        return
        
    wellbeing = DigitalWellbeing()
    
    # Setup signal handlers
    def signal_handler(signum, frame):
        wellbeing.stop()
        
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    wellbeing.run()


def stop_service():
    """Stop the digital wellbeing service"""
    if not PID_FILE.exists():
        print("Digital Wellbeing service is not running")
        return
        
    try:
        with open(PID_FILE, 'r') as f:
            pid = int(f.read().strip())
        subprocess.run(['kill', str(pid)])
        print("Digital Wellbeing service stopped")
    except Exception as e:
        print(f"Error stopping service: {e}")


def show_stats(period='today'):
    """Show usage statistics"""
    if not DB_PATH.exists():
        print("No usage data available yet")
        return
        
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    if period == 'today':
        date = datetime.now().strftime('%Y-%m-%d')
        print(f"\n📊 Usage Statistics for {date}")
        print("=" * 50)
        
        # Total usage
        cursor.execute('''
            SELECT SUM(duration) FROM app_usage WHERE date = ?
        ''', (date,))
        total = cursor.fetchone()[0] or 0
        hours = total // 3600
        minutes = (total % 3600) // 60
        print(f"\nTotal usage: {hours}h {minutes}m")
        
        # App breakdown
        cursor.execute('''
            SELECT app_class, SUM(duration) as total
            FROM app_usage
            WHERE date = ?
            GROUP BY app_class
            ORDER BY total DESC
            LIMIT 10
        ''', (date,))
        
        print("\nTop Applications:")
        for app, duration in cursor.fetchall():
            hours = duration // 3600
            minutes = (duration % 3600) // 60
            print(f"  • {app:20s} {hours}h {minutes}m")
    
    elif period == 'week-json':
        # Output weekly data in JSON format for QML
        import json
        
        # Get last 7 days
        dates = [(datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d') for i in range(6, -1, -1)]
        day_names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        
        week_data = []
        total_week_usage = 0
        app_colors = {}
        # Bright, vibrant colors avoiding dark shades
        color_palette = ["#FF7139", "#007ACC", "#5865F2", "#1DB954", "#FF9500", "#0088CC", 
                        "#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#6C5CE7",
                        "#FF4757", "#2ED573", "#5F27CD", "#00D2D3", "#FFA502", "#FF6348",
                        "#1E90FF", "#FF69B4", "#3742FA", "#70A1FF"]
        color_index = 0
        
        for i, date in enumerate(dates):
            cursor.execute('''
                SELECT app_class, SUM(duration) as total
                FROM app_usage
                WHERE date = ?
                GROUP BY app_class
                ORDER BY total DESC
            ''', (date,))
            
            apps_data = []
            day_total = 0
            
            for app, duration in cursor.fetchall():
                if app not in app_colors:
                    app_colors[app] = color_palette[color_index % len(color_palette)]
                    color_index += 1
                
                apps_data.append({
                    "name": app,
                    "time": duration,
                    "color": app_colors[app]
                })
                day_total += duration
            
            total_week_usage += day_total
            hours = day_total // 3600
            minutes = (day_total % 3600) // 60
            
            # Use actual day name for today
            day_label = "Today" if i == 6 else day_names[datetime.strptime(date, '%Y-%m-%d').weekday()]
            
            week_data.append({
                "day": day_label,
                "apps": apps_data[:5],  # Top 5 apps per day
                "total": f"{hours}h {minutes}m"
            })
        
        # Calculate daily average
        avg_seconds = total_week_usage / 7 if week_data else 0
        avg_hours = int(avg_seconds // 3600)
        avg_minutes = int((avg_seconds % 3600) // 60)
        daily_average = f"{avg_hours}h {avg_minutes}m"
        
        # Get previous week's average for comparison
        prev_week_dates = [(datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d') for i in range(13, 6, -1)]
        cursor.execute(f'''
            SELECT SUM(duration) FROM app_usage
            WHERE date IN ({','.join(['?'] * len(prev_week_dates))})
        ''', prev_week_dates)
        prev_week_total = cursor.fetchone()[0] or 1
        prev_week_avg = prev_week_total / 7
        
        # Calculate percent change
        percent_change = 0
        if prev_week_avg > 0:
            percent_change = int(((avg_seconds - prev_week_avg) / prev_week_avg) * 100)
        
        # Get most used apps
        cursor.execute('''
            SELECT app_class, SUM(duration) as total
            FROM app_usage
            WHERE date IN ({})
            GROUP BY app_class
            ORDER BY total DESC
            LIMIT 6
        '''.format(','.join(['?'] * len(dates))), dates)
        
        most_used = []
        for app, _ in cursor.fetchall():
            if app in app_colors:
                most_used.append({
                    "name": app,
                    "color": app_colors[app]
                })
        
        result = {
            "dailyAverage": daily_average,
            "percentChange": percent_change,
            "weekData": week_data,
            "mostUsedApps": most_used,
            "insights": f"Your screen time this week averaged {daily_average} per day."
        }
        
        print(json.dumps(result, indent=2))
            
    elif period == 'week':
        start_date = (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')
        print(f"\n📊 Usage Statistics for the past week")
        print("=" * 50)
        
        cursor.execute('''
            SELECT date, total_usage
            FROM daily_stats
            WHERE date >= ?
            ORDER BY date
        ''', (start_date,))
        
        print("\nDaily Usage:")
        for date, usage in cursor.fetchall():
            hours = usage // 3600
            minutes = (usage % 3600) // 60
            print(f"  {date}: {hours}h {minutes}m")
            
    elif period == 'month':
        start_date = (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d')
        print(f"\n📊 Usage Statistics for the past month")
        print("=" * 50)
        
        cursor.execute('''
            SELECT SUM(total_usage), AVG(total_usage)
            FROM daily_stats
            WHERE date >= ?
        ''', (start_date,))
        
        total, avg = cursor.fetchone()
        if total:
            total_hours = total // 3600
            avg_hours = avg // 3600
            avg_minutes = (avg % 3600) // 60
            print(f"\nTotal usage: {total_hours}h")
            print(f"Average daily usage: {avg_hours}h {avg_minutes}m")
            
        # Most used apps
        cursor.execute('''
            SELECT app_class, SUM(duration) as total
            FROM app_usage
            WHERE date >= ?
            GROUP BY app_class
            ORDER BY total DESC
            LIMIT 10
        ''', (start_date,))
        
        print("\nMost Used Applications (past month):")
        for app, duration in cursor.fetchall():
            hours = duration // 3600
            print(f"  • {app:20s} {hours}h")
    
    conn.close()


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: digital-wellbeing.py [start|stop|stats|config]")
        sys.exit(1)
        
    command = sys.argv[1]
    
    if command == 'start':
        start_service()
    elif command == 'stop':
        stop_service()
    elif command == 'stats':
        period = sys.argv[2] if len(sys.argv) > 2 else 'today'
        show_stats(period)
    elif command == 'config':
        print(f"Configuration file: {CONFIG_FILE}")
        print("Edit this file to customize Digital Wellbeing settings")
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == '__main__':
    main()
