# Kitty search from https://github.com/trygveaa/kitty-kitten-search
# License: GPLv3

import json
import re
import subprocess
from gettext import gettext as _
from pathlib import Path
from subprocess import PIPE, run

from kittens.tui.handler import Handler
from kittens.tui.line_edit import LineEdit
from kittens.tui.loop import Loop
from kittens.tui.operations import (
    clear_screen,
    cursor,
    set_line_wrapping,
    set_window_title,
    styled,
)
from kitty.config import cached_values_for
from kitty.key_encoding import EventType
from kitty.typing_compat import KeyEventType, ScreenSize

NON_SPACE_PATTERN = re.compile(r"\S+")
SPACE_PATTERN = re.compile(r"\s+")
SPACE_PATTERN_END = re.compile(r"\s+$")
SPACE_PATTERN_START = re.compile(r"^\s+")

NON_ALPHANUM_PATTERN = re.compile(r"[^\w\d]+")
NON_ALPHANUM_PATTERN_END = re.compile(r"[^\w\d]+$")
NON_ALPHANUM_PATTERN_START = re.compile(r"^[^\w\d]+")
ALPHANUM_PATTERN = re.compile(r"[\w\d]+")


def call_remote_control(args: list[str]) -> None:
    subprocess.run(["kitty", "@", *args], capture_output=True)


def reindex(
    text: str, pattern: re.Pattern[str], right: bool = False
) -> tuple[int, int]:
    if not right:
        m = pattern.search(text)
    else:
        matches = [x for x in pattern.finditer(text) if x]
        if not matches:
            raise ValueError
        m = matches[-1]

    if not m:
        raise ValueError

    return m.span()


SCROLLMARK_FILE = Path(__file__).parent.absolute() / "scroll_mark.py"


class Search(Handler):
    def __init__(
        self, cached_values: dict[str, str], window_ids: list[int], error: str = ""
    ) -> None:
        self.cached_values = cached_values
        self.window_ids = window_ids
        self.error = error
        self.line_edit = LineEdit()
        last_search = cached_values.get("last_search", "")
        self.line_edit.add_text(last_search)
        self.text_marked = bool(last_search)
        self.mode = cached_values.get("mode", "text")
        self.update_prompt()
        self.mark()

    def update_prompt(self) -> None:
        self.prompt = "~> " if self.mode == "regex" else "=> "

    def init_terminal_state(self) -> None:
        self.write(set_line_wrapping(False))
        self.write(set_window_title(_("Search")))

    def initialize(self) -> None:
        self.init_terminal_state()
        self.draw_screen()

    def draw_screen(self) -> None:
        self.write(clear_screen())
        if self.window_ids:
            input_text = self.line_edit.current_input
            if self.text_marked:
                self.line_edit.current_input = styled(input_text, reverse=True)
            self.line_edit.write(self.write, self.prompt)
            self.line_edit.current_input = input_text
        if self.error:
            with cursor(self.write):
                self.print("")
                for l in self.error.split("\n"):
                    self.print(l)

    def refresh(self) -> None:
        self.draw_screen()
        self.mark()

    def switch_mode(self) -> None:
        if self.mode == "regex":
            self.mode = "text"
        else:
            self.mode = "regex"
        self.cached_values["mode"] = self.mode
        self.update_prompt()

    def on_text(self, text: str, in_bracketed_paste: bool = False) -> None:
        if self.text_marked:
            self.text_marked = False
            self.line_edit.clear()
        self.line_edit.on_text(text, in_bracketed_paste)
        self.refresh()

    def on_key(self, key_event: KeyEventType) -> None:
        if (
            self.text_marked
            and key_event.type == EventType.PRESS
            and key_event.key
            not in [
                "TAB",
                "LEFT_CONTROL",
                "RIGHT_CONTROL",
                "LEFT_ALT",
                "RIGHT_ALT",
                "LEFT_SHIFT",
                "RIGHT_SHIFT",
                "LEFT_SUPER",
                "RIGHT_SUPER",
            ]
        ):
            self.text_marked = False
            self.refresh()

        if self.line_edit.on_key(key_event):
            self.refresh()
            return

        if key_event.matches("ctrl+u"):
            self.line_edit.clear()
            self.refresh()
        elif key_event.matches("ctrl+a"):
            self.line_edit.home()
            self.refresh()
        elif key_event.matches("ctrl+e"):
            self.line_edit.end()
            self.refresh()
        elif key_event.matches("ctrl+backspace") or key_event.matches("ctrl+w"):
            before, _ = self.line_edit.split_at_cursor()

            try:
                start, _ = reindex(before, SPACE_PATTERN_END, right=True)
            except ValueError:
                start = -1

            try:
                space = before[:start].rindex(" ")
            except ValueError:
                space = 0
            self.line_edit.backspace(len(before) - space)
            self.refresh()
        elif key_event.matches("ctrl+left") or key_event.matches("ctrl+b"):
            before, _ = self.line_edit.split_at_cursor()
            try:
                start, _ = reindex(before, SPACE_PATTERN_END, right=True)
            except ValueError:
                start = -1

            try:
                space = before[:start].rindex(" ")
            except ValueError:
                space = 0
            self.line_edit.left(len(before) - space)
            self.refresh()
        elif key_event.matches("ctrl+right") or key_event.matches("ctrl+f"):
            _, after = self.line_edit.split_at_cursor()
            try:
                _, end = reindex(after, SPACE_PATTERN_START)
            except ValueError:
                end = 0

            try:
                space = after[end:].index(" ") + 1
            except ValueError:
                space = len(after)
            self.line_edit.right(space)
            self.refresh()
        elif key_event.matches("alt+backspace") or key_event.matches("alt+w"):
            before, _ = self.line_edit.split_at_cursor()

            try:
                start, _ = reindex(before, NON_ALPHANUM_PATTERN_END, right=True)
            except ValueError:
                start = -1
            else:
                self.line_edit.backspace(len(before) - start)
                self.refresh()
                return

            try:
                start, _ = reindex(before, NON_ALPHANUM_PATTERN, right=True)
            except ValueError:
                self.line_edit.backspace(len(before))
                self.refresh()
                return

            self.line_edit.backspace(len(before) - (start + 1))
            self.refresh()
        elif key_event.matches("alt+left") or key_event.matches("alt+b"):
            before, _ = self.line_edit.split_at_cursor()

            try:
                start, _ = reindex(before, NON_ALPHANUM_PATTERN_END, right=True)
            except ValueError:
                start = -1
            else:
                self.line_edit.left(len(before) - start)
                self.refresh()
                return

            try:
                start, _ = reindex(before, NON_ALPHANUM_PATTERN, right=True)
            except ValueError:
                self.line_edit.left(len(before))
                self.refresh()
                return

            self.line_edit.left(len(before) - (start + 1))
            self.refresh()
        elif key_event.matches("alt+right") or key_event.matches("alt+f"):
            _, after = self.line_edit.split_at_cursor()

            try:
                _, end = reindex(after, NON_ALPHANUM_PATTERN_START)
            except ValueError:
                end = 0
            else:
                self.line_edit.right(end)
                self.refresh()
                return

            try:
                _, end = reindex(after, NON_ALPHANUM_PATTERN)
            except ValueError:
                self.line_edit.right(len(after))
                self.refresh()
                return

            self.line_edit.right(end - 1)
            self.refresh()
        elif key_event.matches("tab"):
            self.switch_mode()
            self.refresh()
        elif key_event.matches("up") or key_event.matches("f3"):
            for match_arg in self.match_args():
                call_remote_control(["kitten", match_arg, str(SCROLLMARK_FILE)])
        elif key_event.matches("down") or key_event.matches("shift+f3"):
            for match_arg in self.match_args():
                call_remote_control(["kitten", match_arg, str(SCROLLMARK_FILE), "next"])
        elif key_event.matches("enter"):
            self.quit(0)
        elif key_event.matches("esc"):
            self.quit(1)

    def on_interrupt(self) -> None:
        self.quit(1)

    def on_eot(self) -> None:
        self.quit(1)

    def on_resize(self, screen_size: ScreenSize) -> None:
        self.refresh()

    def match_args(self) -> list[str]:
        return [f"--match=id:{window_id}" for window_id in self.window_ids]

    def mark(self) -> None:
        if not self.window_ids:
            return
        text = self.line_edit.current_input
        if text:
            match_case = "i" if text.islower() else ""
            match_type = match_case + self.mode
            for match_arg in self.match_args():
                try:
                    call_remote_control(
                        ["create-marker", match_arg, match_type, "1", text]
                    )
                except SystemExit:
                    self.remove_mark()
        else:
            self.remove_mark()

    def remove_mark(self) -> None:
        for match_arg in self.match_args():
            call_remote_control(["remove-marker", match_arg])

    def quit(self, return_code: int) -> None:
        self.cached_values["last_search"] = self.line_edit.current_input
        self.remove_mark()
        if return_code:
            for match_arg in self.match_args():
                call_remote_control(["scroll-window", match_arg, "end"])
        self.quit_loop(return_code)


def main(args: list[str]) -> None:
    call_remote_control(
        ["resize-window", "--self", "--axis=vertical", "--increment", "-100"]
    )

    error = ""
    if len(args) < 2 or not args[1].isdigit():
        error = "Error: Window id must be provided as the first argument."

    window_id = int(args[1])
    window_ids = [window_id]
    if len(args) > 2 and args[2] == "--all-windows":
        ls_output = run(["kitty", "@", "ls"], stdout=PIPE)
        ls_json = json.loads(ls_output.stdout.decode())
        current_tab = None
        for os_window in ls_json:
            for tab in os_window["tabs"]:
                for kitty_window in tab["windows"]:
                    if kitty_window["id"] == window_id:
                        current_tab = tab
        if current_tab:
            window_ids = [
                w["id"] for w in current_tab["windows"] if not w["is_focused"]
            ]
        else:
            error = "Error: Could not find the window id provided."

    loop = Loop()
    with cached_values_for("search") as cached_values:
        handler = Search(cached_values, window_ids, error)
        loop.loop(handler)
