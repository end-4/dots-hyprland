#!/usr/bin/env python3
"""
Productivity Dashboard - GTK GUI for Digital Wellbeing Settings

Features:
- Focus Mode control (block distracting apps)
- Digital Wellbeing service management
- Usage statistics visualization
- Settings editor with new nested config format support

Config Format Support:
- Old format: {"eye_care": true, "break_reminders": false}
- New format: {"eye_care": {"enabled": true, "interval": 1200, ...}}
- Preserves all settings when toggling switches
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib
import subprocess
import json
from pathlib import Path
from datetime import datetime
import sqlite3

CONFIG_DIR = Path.home() / ".config" / "hypr" / "productivity"
DATA_DIR = Path.home() / ".local" / "share" / "digital-wellbeing"
DB_PATH = DATA_DIR / "usage.db"
SETTINGS_FILE = CONFIG_DIR / "wellbeing.json"
FOCUS_MODE_SCRIPT = CONFIG_DIR / "focus-mode.sh"
WELLBEING_SCRIPT = CONFIG_DIR / "digital-wellbeing.py"


class ProductivityDashboard(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="Productivity Dashboard")
        self.set_default_size(600, 500)
        self.set_border_width(10)
        
        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(main_box)
        
        # Title
        title = Gtk.Label()
        title.set_markup("<big><b>Productivity Dashboard</b></big>")
        main_box.pack_start(title, False, False, 0)
        
        # Notebook for tabs
        notebook = Gtk.Notebook()
        main_box.pack_start(notebook, True, True, 0)
        
        # Focus Mode Tab
        focus_tab = self.create_focus_mode_tab()
        notebook.append_page(focus_tab, Gtk.Label(label="Focus Mode"))
        
        # Digital Wellbeing Tab
        wellbeing_tab = self.create_wellbeing_tab()
        notebook.append_page(wellbeing_tab, Gtk.Label(label="Digital Wellbeing"))
        
        # Statistics Tab
        stats_tab = self.create_stats_tab()
        notebook.append_page(stats_tab, Gtk.Label(label="Statistics"))
        
        # Settings Tab
        settings_tab = self.create_settings_tab()
        notebook.append_page(settings_tab, Gtk.Label(label="Settings"))
        
        # Load saved settings
        self.load_settings()
        
    def load_settings(self):
        """Load settings from JSON file"""
        if SETTINGS_FILE.exists():
            try:
                with open(SETTINGS_FILE, 'r') as f:
                    settings = json.load(f)
                    
                    # Handle both old and new config formats
                    eye_care = settings.get('eye_care', False)
                    if isinstance(eye_care, dict):
                        eye_care = eye_care.get('enabled', False)
                    
                    break_reminders = settings.get('break_reminders', False)
                    if isinstance(break_reminders, dict):
                        break_reminders = break_reminders.get('enabled', False)
                    
                    self.eye_care_switch.set_active(eye_care)
                    self.break_switch.set_active(break_reminders)
            except Exception as e:
                print(f"Error loading settings: {e}")
        
    def save_settings(self):
        """Save settings to JSON file in the new format"""
        try:
            # Load existing config to preserve all settings
            existing_config = {}
            if SETTINGS_FILE.exists():
                with open(SETTINGS_FILE, 'r') as f:
                    existing_config = json.load(f)
            
            # Update only the enabled flags, preserving other settings
            eye_care_enabled = self.eye_care_switch.get_active()
            break_enabled = self.break_switch.get_active()
            
            # Handle both old and new formats
            if 'eye_care' not in existing_config or isinstance(existing_config.get('eye_care'), bool):
                # If old format or missing, create new format
                existing_config['eye_care'] = {
                    "enabled": eye_care_enabled,
                    "interval": 1200,
                    "duration": 20
                }
            else:
                # New format exists, just update enabled flag
                existing_config['eye_care']['enabled'] = eye_care_enabled
            
            if 'break_reminders' not in existing_config or isinstance(existing_config.get('break_reminders'), bool):
                existing_config['break_reminders'] = {
                    "enabled": break_enabled,
                    "interval": 3600,
                    "duration": 300
                }
            else:
                existing_config['break_reminders']['enabled'] = break_enabled
            
            # Ensure tracking settings exist
            if 'tracking' not in existing_config:
                existing_config['tracking'] = {
                    "idle_threshold": 180,
                    "update_interval": 30
                }
            
            CONFIG_DIR.mkdir(parents=True, exist_ok=True)
            with open(SETTINGS_FILE, 'w') as f:
                json.dump(existing_config, f, indent=4)
            return True
        except Exception as e:
            print(f"Error saving settings: {e}")
            return False
        
    def create_focus_mode_tab(self):
        """Create Focus Mode tab"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_border_width(10)
        
        # Description
        desc = Gtk.Label()
        desc.set_markup("<b>Focus Mode</b> temporarily blocks distracting applications\nto help you stay focused on your tasks.")
        desc.set_line_wrap(True)
        box.pack_start(desc, False, False, 0)
        
        # Status
        self.focus_status_label = Gtk.Label()
        self.update_focus_status()
        box.pack_start(self.focus_status_label, False, False, 0)
        
        # Buttons
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        button_box.set_halign(Gtk.Align.CENTER)
        
        enable_btn = Gtk.Button(label="Enable Focus Mode")
        enable_btn.connect("clicked", self.on_enable_focus)
        button_box.pack_start(enable_btn, False, False, 0)
        
        disable_btn = Gtk.Button(label="Disable Focus Mode")
        disable_btn.connect("clicked", self.on_disable_focus)
        button_box.pack_start(disable_btn, False, False, 0)
        
        box.pack_start(button_box, False, False, 10)
        
        # Blocked apps list
        label = Gtk.Label()
        label.set_markup("<b>Blocked Applications:</b>")
        label.set_halign(Gtk.Align.START)
        box.pack_start(label, False, False, 5)
        
        # Scrolled window for blocked apps
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        
        self.blocked_apps_view = Gtk.TextView()
        self.blocked_apps_view.set_editable(False)
        self.blocked_apps_view.set_wrap_mode(Gtk.WrapMode.WORD)
        scrolled.add(self.blocked_apps_view)
        
        self.update_blocked_apps_list()
        box.pack_start(scrolled, True, True, 0)
        
        return box
        
    def create_wellbeing_tab(self):
        """Create Digital Wellbeing tab"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_border_width(10)
        
        # Description
        desc = Gtk.Label()
        desc.set_markup("<b>Digital Wellbeing</b> tracks your application usage\nand reminds you to take care of your eyes and posture.")
        desc.set_line_wrap(True)
        box.pack_start(desc, False, False, 0)
        
        # Service status
        self.wellbeing_status_label = Gtk.Label()
        self.update_wellbeing_status()
        box.pack_start(self.wellbeing_status_label, False, False, 0)
        
        # Control buttons
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        button_box.set_halign(Gtk.Align.CENTER)
        
        start_btn = Gtk.Button(label="Start Service")
        start_btn.connect("clicked", self.on_start_wellbeing)
        button_box.pack_start(start_btn, False, False, 0)
        
        stop_btn = Gtk.Button(label="Stop Service")
        stop_btn.connect("clicked", self.on_stop_wellbeing)
        button_box.pack_start(stop_btn, False, False, 0)
        
        box.pack_start(button_box, False, False, 10)
        
        # Quick stats
        stats_frame = Gtk.Frame(label="Today's Usage")
        stats_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        stats_box.set_border_width(10)
        
        self.today_usage_label = Gtk.Label()
        self.today_apps_label = Gtk.Label()
        self.today_most_used_label = Gtk.Label()
        
        stats_box.pack_start(self.today_usage_label, False, False, 0)
        stats_box.pack_start(self.today_apps_label, False, False, 0)
        stats_box.pack_start(self.today_most_used_label, False, False, 0)
        
        stats_frame.add(stats_box)
        box.pack_start(stats_frame, False, False, 10)
        
        self.update_today_stats()
        
        # Reminders configuration
        reminders_frame = Gtk.Frame(label="Reminders")
        reminders_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        reminders_box.set_border_width(10)
        
        self.eye_care_switch = Gtk.Switch()
        self.eye_care_switch.connect("notify::active", lambda x, y: self.save_settings())
        eye_care_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        eye_care_box.pack_start(Gtk.Label(label="Eye Care Reminders (20-20-20 rule)"), False, False, 0)
        eye_care_box.pack_end(self.eye_care_switch, False, False, 0)
        reminders_box.pack_start(eye_care_box, False, False, 0)
        
        self.break_switch = Gtk.Switch()
        self.break_switch.connect("notify::active", lambda x, y: self.save_settings())
        break_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        break_box.pack_start(Gtk.Label(label="Break Reminders"), False, False, 0)
        break_box.pack_end(self.break_switch, False, False, 0)
        reminders_box.pack_start(break_box, False, False, 0)
        
        reminders_frame.add(reminders_box)
        box.pack_start(reminders_frame, False, False, 0)
        
        return box
        
    def create_stats_tab(self):
        """Create Statistics tab"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_border_width(10)
        
        # Period selector
        period_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        period_box.set_halign(Gtk.Align.CENTER)
        
        today_btn = Gtk.Button(label="Today")
        today_btn.connect("clicked", lambda x: self.load_stats('today'))
        period_box.pack_start(today_btn, False, False, 0)
        
        week_btn = Gtk.Button(label="This Week")
        week_btn.connect("clicked", lambda x: self.load_stats('week'))
        period_box.pack_start(week_btn, False, False, 0)
        
        month_btn = Gtk.Button(label="This Month")
        month_btn.connect("clicked", lambda x: self.load_stats('month'))
        period_box.pack_start(month_btn, False, False, 0)
        
        box.pack_start(period_box, False, False, 0)
        
        # Stats display
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        
        self.stats_view = Gtk.TextView()
        self.stats_view.set_editable(False)
        self.stats_view.set_wrap_mode(Gtk.WrapMode.WORD)
        scrolled.add(self.stats_view)
        
        box.pack_start(scrolled, True, True, 0)
        
        # Load today's stats by default
        self.load_stats('today')
        
        return box
        
    def create_settings_tab(self):
        """Create Settings tab"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_border_width(10)
        
        # Eye care settings
        eye_frame = Gtk.Frame(label="Eye Care Settings")
        eye_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        eye_box.set_border_width(10)
        
        interval_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        interval_box.pack_start(Gtk.Label(label="Reminder Interval (minutes):"), False, False, 0)
        self.eye_interval_entry = Gtk.Entry()
        self.eye_interval_entry.set_text("20")
        self.eye_interval_entry.set_width_chars(5)
        interval_box.pack_start(self.eye_interval_entry, False, False, 0)
        eye_box.pack_start(interval_box, False, False, 0)
        
        eye_frame.add(eye_box)
        box.pack_start(eye_frame, False, False, 0)
        
        # Break settings
        break_frame = Gtk.Frame(label="Break Settings")
        break_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        break_box.set_border_width(10)
        
        break_interval_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        break_interval_box.pack_start(Gtk.Label(label="Break Interval (minutes):"), False, False, 0)
        self.break_interval_entry = Gtk.Entry()
        self.break_interval_entry.set_text("60")
        self.break_interval_entry.set_width_chars(5)
        break_interval_box.pack_start(self.break_interval_entry, False, False, 0)
        break_box.pack_start(break_interval_box, False, False, 0)
        
        break_frame.add(break_box)
        box.pack_start(break_frame, False, False, 0)
        
        # Daily limit settings
        limit_frame = Gtk.Frame(label="Daily Usage Limit")
        limit_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        limit_box.set_border_width(10)
        
        self.limit_enabled_switch = Gtk.Switch()
        limit_enabled_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        limit_enabled_box.pack_start(Gtk.Label(label="Enable Daily Limit"), False, False, 0)
        limit_enabled_box.pack_end(self.limit_enabled_switch, False, False, 0)
        limit_box.pack_start(limit_enabled_box, False, False, 0)
        
        limit_hours_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        limit_hours_box.pack_start(Gtk.Label(label="Daily Limit (hours):"), False, False, 0)
        self.limit_hours_entry = Gtk.Entry()
        self.limit_hours_entry.set_text("8")
        self.limit_hours_entry.set_width_chars(5)
        limit_hours_box.pack_start(self.limit_hours_entry, False, False, 0)
        limit_box.pack_start(limit_hours_box, False, False, 0)
        
        limit_frame.add(limit_box)
        box.pack_start(limit_frame, False, False, 0)
        
        # Save button
        save_btn = Gtk.Button(label="Save Settings")
        save_btn.connect("clicked", self.on_save_settings)
        box.pack_start(save_btn, False, False, 10)
        
        return box
        
    def update_focus_status(self):
        """Update focus mode status"""
        try:
            result = subprocess.run(
                [str(FOCUS_MODE_SCRIPT), 'status'],
                capture_output=True,
                text=True
            )
            status = "ENABLED" if "ENABLED" in result.stdout else "DISABLED"
            color = "green" if status == "ENABLED" else "red"
            self.focus_status_label.set_markup(
                f'<span foreground="{color}"><b>Status: {status}</b></span>'
            )
        except Exception as e:
            self.focus_status_label.set_text(f"Error: {e}")
            
    def update_blocked_apps_list(self):
        """Update list of blocked applications"""
        config_file = CONFIG_DIR / "focus-mode.conf"
        try:
            apps = []
            if config_file.exists():
                with open(config_file, 'r') as f:
                    content = f.read()
                    # Simple parsing - look for app names in quotes
                    for line in content.split('\n'):
                        if '"' in line and not line.strip().startswith('#'):
                            parts = line.split('"')
                            if len(parts) >= 2:
                                apps.append(parts[1])
            
            text = "\n".join(f"• {app}" for app in apps if app)
            self.blocked_apps_view.get_buffer().set_text(text)
        except Exception as e:
            self.blocked_apps_view.get_buffer().set_text(f"Error loading apps: {e}")
            
    def update_wellbeing_status(self):
        """Update wellbeing service status"""
        pid_file = DATA_DIR / "wellbeing.pid"
        status = "RUNNING" if pid_file.exists() else "STOPPED"
        color = "green" if status == "RUNNING" else "red"
        self.wellbeing_status_label.set_markup(
            f'<span foreground="{color}"><b>Service Status: {status}</b></span>'
        )
        
    def update_today_stats(self):
        """Update today's statistics"""
        if not DB_PATH.exists():
            self.today_usage_label.set_text("No data available yet")
            return
            
        try:
            conn = sqlite3.connect(DB_PATH)
            cursor = conn.cursor()
            today = datetime.now().strftime('%Y-%m-%d')
            
            # Total usage
            cursor.execute('SELECT SUM(duration) FROM app_usage WHERE date = ?', (today,))
            total = cursor.fetchone()[0] or 0
            hours = total // 3600
            minutes = (total % 3600) // 60
            self.today_usage_label.set_text(f"Total Usage: {hours}h {minutes}m")
            
            # App count
            cursor.execute('SELECT COUNT(DISTINCT app_class) FROM app_usage WHERE date = ?', (today,))
            count = cursor.fetchone()[0] or 0
            self.today_apps_label.set_text(f"Applications Used: {count}")
            
            # Most used app
            cursor.execute('''
                SELECT app_class, SUM(duration) as total
                FROM app_usage
                WHERE date = ?
                GROUP BY app_class
                ORDER BY total DESC
                LIMIT 1
            ''', (today,))
            result = cursor.fetchone()
            if result:
                app, duration = result
                hours = duration // 3600
                minutes = (duration % 3600) // 60
                self.today_most_used_label.set_text(f"Most Used: {app} ({hours}h {minutes}m)")
            
            conn.close()
        except Exception as e:
            self.today_usage_label.set_text(f"Error: {e}")
            
    def load_stats(self, period):
        """Load statistics for specified period"""
        try:
            result = subprocess.run(
                ['python3', str(WELLBEING_SCRIPT), 'stats', period],
                capture_output=True,
                text=True
            )
            self.stats_view.get_buffer().set_text(result.stdout)
        except Exception as e:
            self.stats_view.get_buffer().set_text(f"Error loading stats: {e}")
            
    def on_enable_focus(self, button):
        """Enable focus mode"""
        subprocess.run([str(FOCUS_MODE_SCRIPT), 'enable'])
        self.update_focus_status()
        
    def on_disable_focus(self, button):
        """Disable focus mode"""
        subprocess.run([str(FOCUS_MODE_SCRIPT), 'disable'])
        self.update_focus_status()
        
    def on_start_wellbeing(self, button):
        """Start wellbeing service"""
        subprocess.Popen(['python3', str(WELLBEING_SCRIPT), 'start'])
        GLib.timeout_add_seconds(1, self.update_wellbeing_status)
        GLib.timeout_add_seconds(1, self.update_today_stats)
        
    def on_stop_wellbeing(self, button):
        """Stop wellbeing service"""
        subprocess.run(['python3', str(WELLBEING_SCRIPT), 'stop'])
        GLib.timeout_add_seconds(1, self.update_wellbeing_status)
        
    def on_save_settings(self, button):
        """Save settings"""
        if self.save_settings():
            dialog = Gtk.MessageDialog(
                transient_for=self,
                flags=0,
                message_type=Gtk.MessageType.INFO,
                buttons=Gtk.ButtonsType.OK,
                text="Settings saved successfully!",
            )
            dialog.run()
            dialog.destroy()
        else:
            dialog = Gtk.MessageDialog(
                transient_for=self,
                flags=0,
                message_type=Gtk.MessageType.ERROR,
                buttons=Gtk.ButtonsType.OK,
                text="Failed to save settings!",
            )
            dialog.run()
            dialog.destroy()


def main():
    win = ProductivityDashboard()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()


if __name__ == '__main__':
    main()
