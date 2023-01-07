#!/usr/bin/env python3

import json
import math
import os
import sys
import textwrap
import traceback

import psutil
from gi.repository import GLib
from pydbus import SessionBus

MPRIS_PLAYER_OBJ_PATH = '/org/mpris/MediaPlayer2'
MPRIS_PLAYER_IFACE = 'org.mpris.MediaPlayer2.Player'
KNOWN_SERVICES = [
    'org.mpris.MediaPlayer2.mpv',
    'org.kde.plasma.browser_integration'
]
KNOWN_BROWSER_MAP = {
    'mozilla': 'Firefox',
    'chromium': 'Chromium',
    'chrome': 'Google Chrome'
}


class Player:
    def __init__(self, bus, owner_name):
        self._bus = bus
        self.owner_name = owner_name
        self.owner_process = self._get_owner_process()
        self._obj = self._bus.get(owner_name, MPRIS_PLAYER_OBJ_PATH)

    def _get_owner_process(self):
        obj = self._bus.get('org.freedesktop.DBus', '/org/freedesktop/DBus')
        pid = obj.GetConnectionUnixProcessID(self.owner_name)
        if pid is None:
            return None

        return psutil.Process(pid)

    @staticmethod
    def _identify_browser_by_cmdline(cmdline):
        for fragment, browser in KNOWN_BROWSER_MAP.items():
            if fragment in cmdline:
                return browser
        return None

    @property
    def name(self):
        name = self.owner_process.name()
        if name == 'plasma-browser-integration-host':
            cmdline = ' '.join(self.owner_process.cmdline())
            return self._identify_browser_by_cmdline(cmdline)
        return name

    @property
    def status(self):
        return self._obj.PlaybackStatus.lower()

    @property
    def title(self):
        return self._obj.Metadata.get('xesam:title')

    @property
    def album(self):
        return self._obj.Metadata.get('xesam:album')

    @property
    def artist(self):
        artists = self._obj.Metadata.get('xesam:artist')
        return ', '.join(artists) if isinstance(artists, list) else artists

    def playpause(self):
        if self._obj.CanPlay or self._obj.CanPause:
            self._obj.PlayPause()

    def play(self):
        if self._obj.CanPlay:
            self._obj.Play()

    def pause(self):
        if self._obj.CanPause:
            self._obj.Pause()

    def previous(self):
        if self._obj.CanGoPrevious:
            self._obj.Previous()

    def next(self):
        if self._obj.CanGoNext:
            self._obj.Next()


class MediaWatcher:
    def __init__(self, bus, do_print_status=False):
        self._bus = bus

        self._owner_to_player = self._find_players()
        self.player = self._find_active_player()

        if do_print_status:
            self.status_builder = MediaWatcherStatusBuilder(self)
            self.status_builder.print_status()
        else:
            self.status_builder = None

    def __enter__(self):
        self._subscription = self._bus.subscribe(
            iface='org.freedesktop.DBus.Properties',
            signal='PropertiesChanged',
            object=MPRIS_PLAYER_OBJ_PATH,
            arg0=MPRIS_PLAYER_IFACE,
            signal_fired=self._mpris_signal_handler,
        )
        return self

    def __exit__(self, exc_type, exc_value, tb):
        if exc_type is not None:
            traceback.print_exception(exc_type, exc_value, tb)
        self._subscription.unsubscribe()

    def _find_players(self):
        owner_to_player = {}
        for service in KNOWN_SERVICES:
            try:
                owner_name = self._bus.dbus.GetNameOwner(service)
            except GLib.Error:
                continue
            owner_to_player[owner_name] = Player(bus=self._bus, owner_name=owner_name)
        return owner_to_player

    def _group_players_by_status(self):
        status_to_players = {}
        for player in self._owner_to_player.values():
            if player.status in status_to_players:
                status_to_players[player.status].append(player)
            else:
                status_to_players[player.status] = [player]
        return status_to_players

    def _find_active_player(self):
        players_by_status = self._group_players_by_status()

        if players_by_status.get('playing'):
            players_by_status['playing'].sort(key=lambda x: x.owner_process.create_time(), reverse=True)
            return players_by_status['playing'][0]
        elif players_by_status.get('paused'):
            return players_by_status['paused'][0]
        elif players_by_status.get('stopped'):
            return players_by_status['stopped'][0]

        return None

    def _mpris_signal_handler(self, sender_name, *_):
        if sender_name not in self._owner_to_player:
            self._owner_to_player[sender_name] = Player(bus=self._bus, owner_name=sender_name)

        self.player = self._find_active_player()

        if self.status_builder:
            self.status_builder.print_status()


class MediaWatcherStatusBuilder:
    def __init__(self, watcher):
        self.watcher = watcher

    def _build_tooltip(self):
        tooltip = []
        player = self.watcher.player

        if player.status in ['playing', 'paused']:
            tooltip.append(player.status.title() + ':')
        if player.title:
            tooltip.append(player.title)
        if player.album:
            tooltip.append(player.album)
        if player.artist:
            tooltip.append(player.artist)
        if player.name:
            tooltip.append('(' + player.name + ')')

        return '\n'.join(tooltip) if tooltip else None

    def _build_text(self, max_width, title_to_artist_ratio=2 / 3, separator=' - ', placeholder='…'):
        max_width = max_width - len(separator)
        player = self.watcher.player

        if player.title and player.artist:
            title_width = math.floor(max_width * title_to_artist_ratio)
            artist_width = max_width - title_width
        elif player.title and not player.artist:
            title_width = max_width
            artist_width = 0
        elif player.artist and not player.title:
            title_width = 0
            artist_width = max_width
        else:
            return None

        short_title = (
            None if title_width == 0 else textwrap.shorten(player.title, width=title_width, placeholder=placeholder)
        )
        short_artist = (
            None if artist_width == 0 else textwrap.shorten(player.artist, width=artist_width, placeholder=placeholder)
        )

        if short_title and short_artist:
            return separator.join((short_title, short_artist))
        elif short_title and not short_artist:
            return short_title
        elif short_artist and not short_title:
            return short_artist

    def _build_classes(self):
        classes = []
        player = self.watcher.player

        if player.status in ['playing', 'paused']:
            classes.append(player.status)
        else:
            classes.append('stopped')

        return classes

    def build_status(self):
        return json.dumps(
            {'tooltip': self._build_tooltip(), 'text': self._build_text(max_width=80), 'class': self._build_classes()}
        )

    def print_status(self):
        print(self.build_status())
        sys.stdout.flush()


def print_usage():
    name = os.path.basename(sys.argv[0])
    print('Usage:\n\t{} (status|playpause|previous|next)\n'.format(name))


def main():
    bus = SessionBus()
    loop = GLib.MainLoop()

    if len(sys.argv) == 2:
        arg = sys.argv[1]
    else:
        print_usage()
        return

    with MediaWatcher(bus, do_print_status=(arg == 'status')) as media_watcher:
        if arg == 'status':
            while True:
                try:
                    loop.run()
                except GLib.Error:
                    pass
        elif arg == 'playpause':
            media_watcher.player.playpause()
        elif arg == 'play':
            media_watcher.player.play()
        elif arg == 'pause':
            media_watcher.player.pause()
        elif arg == 'previous':
            media_watcher.player.previous()
        elif arg == 'next':
            media_watcher.player.next()
        else:
            print_usage()
            return


if __name__ == '__main__':
    main()
