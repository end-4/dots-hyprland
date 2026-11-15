# Game mode state tests

From the repository root:

```sh
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -import tests/game-mode-state/mocks -input tests/game-mode-state
```

Tests load the actual shared GameModeToggle model with mocked compositor services. They cover unknown/loading state, Lua booleans, legacy numbers, valid configuration values, and keeping the state binding after a click.
They do not change the compositor or verify a physical session restart.
