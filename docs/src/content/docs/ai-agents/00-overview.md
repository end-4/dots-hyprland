---
title: AI Agent Overview
description: Start here — how AI agents should navigate this codebase
---

:::important
**Read [`CLAUDE.md`](https://github.com/omsenjalia/dots-hyprland/blob/main/CLAUDE.md) first.** It is the canonical architecture reference for this repository and contains the most detailed information about project structure, key files, coding conventions, and development patterns.
:::

## How to use this documentation

This site provides **richer context** beyond what `CLAUDE.md` covers. After reading `CLAUDE.md`, use this site for:

1. **Guide section** — understand how end-users install, configure, and use the dotfiles
2. **Architecture** — component relationships, data flow, and file organization
3. **Workflow** — step-by-step processes for common development tasks
4. **Updating Docs** — how to keep this documentation in sync with code changes
5. **Changelog** — recent commit history with structured notes on what changed and why

## Check the changelog first

Before starting any work, **check the [Changelog](/ai-agents/changelog/)** for recent entries. Each entry includes:
- Which files were changed
- The full commit message
- An **AI Agent Notes** section with context from the agent (or human) who made the change

This prevents duplicate work and helps you understand recent decisions.

## Key files to read

| Priority | File | Why |
|----------|------|-----|
| 1 | `CLAUDE.md` | Full architecture, all key files, coding conventions |
| 2 | `dots/custom/WRITEABLE.md` | Complete list of every user-editable file with descriptions |
| 3 | `dots/custom/README.md` | How the custom additions system works |
| 4 | `dots/custom/EDITED.md` | Changelog of fork-specific modifications |
| 5 | This site | Richer context, usage guides, troubleshooting |

## Repository structure at a glance

```
dots-hyprland/
├── CLAUDE.md                    # ← Read this first
├── docs/                        # This documentation site (Astro Starlight)
├── dots/
│   ├── .config/
│   │   ├── hypr/
│   │   │   ├── hyprland/        # Upstream Hyprland config (.lua)
│   │   │   ├── custom/          # User customizations (.lua)
│   │   │   ├── hyprland.lua     # Main entry point
│   │   │   ├── hyprlock.conf    # Lock screen
│   │   │   └── hypridle.conf    # Idle management
│   │   ├── quickshell/ii/       # Shell widgets (QML)
│   │   └── ...                  # Other app configs
│   └── custom/                  # Install-time custom additions
│       ├── README.md
│       ├── WRITEABLE.md
│       ├── EDITED.md
│       ├── packages.sh
│       ├── files.sh
│       ├── commands.sh
│       └── misc.sh
├── sdata/                       # Install scripts, package lists
└── .github/workflows/           # CI/CD
```

## What NOT to do

- **Don't modify `dots/.config/hypr/hyprland/`** — these are upstream-managed files. Use `custom/` instead.
- **Don't modify `dots/.config/quickshell/ii/modules/`** directly unless implementing a feature — use the Settings app or `defaults/` for config changes.
- **Don't forget to update docs** — after making any code change, update the relevant guide page and changelog entry. See [Updating Docs](/ai-agents/03-update-docs/).
