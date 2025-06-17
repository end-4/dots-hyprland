# Translation Management Tools

This directory contains a toolset for managing project translation files.

## Directory Structure

```
translations/
├── tools/                          # Translation management tools directory
│   ├── translation-manager.py      # Main translation manager
│   ├── translation-cleaner.py      # Translation maintenance tool
│   ├── manage-translations.sh      # Convenient wrapper script
│   ├── translation-tools-guide.md  # Detailed usage documentation
│   └── README.md                   # This file
├── en_US.json                      # English translation file
├── zh_CN.json                      # Chinese translation file
└── ...                             # Other language files
```

## Quick Start

### Running from tools directory

```bash
# Enter tools directory
cd .config/quickshell/translations/tools

# Check current translation status
./manage-translations.sh status

# Update all translation files
./manage-translations.sh update

# Update specific language
./manage-translations.sh update -l zh_CN

# Clean unused keys
./manage-translations.sh clean

# Sync all language files
./manage-translations.sh sync
```

### Running from project root directory

```bash
# Run from project root directory (recommended to use relative paths)
.config/quickshell/translations/tools/manage-translations.sh status
.config/quickshell/translations/tools/manage-translations.sh update
```

## Tool Description

### 🛠️ `manage-translations.sh` - Main Entry Point
Convenient command-line interface that integrates all translation management functions.

### 🔍 `translation-manager.py` - Core Manager
- Extract translatable texts
- Compare translation file differences
- Interactive translation updates

### 🧹 `translation-cleaner.py` - Maintenance Tool
- Clean unused translation keys
- Sync language file structure
- Create backup files

## Common Workflows

### After adding new translatable texts
```bash
./manage-translations.sh update
```

### Clean up after code refactoring
```bash
./manage-translations.sh clean
```

### Add new language
```bash
./manage-translations.sh update -l new_language_code
```

### Check translation status
```bash
./manage-translations.sh status
```

## Documentation

- 📖 [Detailed Usage Guide](./translation-tools-guide.md)

## Important Notes

1. **Running Location**: Tools automatically detect relative paths, can be run from tools directory or project root
2. **Backup**: Cleanup operations automatically create backup files
3. **Encoding**: All files use UTF-8 encoding
4. **Permissions**: Ensure scripts have execution permissions

## Supported Translation Formats

The tool recognizes translatable texts in the following formats:
```qml
qsTr("Your text here")
qsTr('Single quotes work too')
i18n.t("JavaScript translations")
```

---

If you have any issues, please refer to the detailed documentation or check error messages in script output.
