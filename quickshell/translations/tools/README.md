# Translation Management Tool Suite

This suite is used to manage project translation files, automatically extract translatable texts, compare differences between language files, and provide maintenance functions.

## Tool Components

### 1. `translation-manager.py` - Main Translation Manager
- Extract translatable texts
- Compare and update translation files
- Interactive addition/removal of translation keys

### 2. `translation-cleaner.py` - Translation File Maintenance Tool
- Clean unused translation keys
- Synchronize key structure across different language files

### 3. `manage-translations.sh` - Convenient Wrapper Script
- Provides a unified command-line interface
- Displays translation status
- Simplifies common operations

## Quick Start

### Using the Wrapper Script (Recommended)

```bash
# Enter the tools directory
cd .config/quickshell/translations/tools

# Show help
./manage-translations.sh --help

# Show current translation status
./manage-translations.sh status

# Extract translatable texts
./manage-translations.sh extract

# Update all translation files
./manage-translations.sh update

# Update a specific language
./manage-translations.sh update -l zh_CN

# Clean unused keys
./manage-translations.sh clean

# Synchronize keys across all language files
./manage-translations.sh sync
```

Or run from the project root:
```bash
# Run from the project root
.config/quickshell/translations/tools/manage-translations.sh status
.config/quickshell/translations/tools/manage-translations.sh update
```

## Detailed Usage

### Translation Manager (`translation-manager.py`)

Basic usage:
```bash
# Process all languages
./translation-manager.py

# Specify a particular language
./translation-manager.py --language zh_CN

# Extract translatable texts only
./translation-manager.py --extract-only

# Show extracted texts
./translation-manager.py --extract-only --show-temp
```

Parameter description:
- `--translations-dir`, `-t`: Translation files directory (default: `.config/quickshell/translations`)
- `--source-dir`, `-s`: Source code directory (default: `.config/quickshell`)
- `--language`, `-l`: Specify the language code to process
- `--extract-only`, `-e`: Only extract translatable texts
- `--show-temp`: Show the content of the temporary extraction file

### Translation Cleaner (`translation-cleaner.py`)

```bash
# Clean unused translation keys
./translation-cleaner.py --clean

# Synchronize translation keys (using en_US as the base)
./translation-cleaner.py --sync

# Specify a different source language for syncing
./translation-cleaner.py --sync --source-lang zh_CN

# Clean without creating backups
./translation-cleaner.py --clean --no-backup
```

## Workflow

### Regular Translation Update Workflow

1. **Check status**:
   ```bash
   ./manage-translations.sh status
   ```

2. **Update translations**:
   ```bash
   ./manage-translations.sh update
   ```

3. **Clean unused keys** (optional):
   ```bash
   ./manage-translations.sh clean
   ```

### Adding a New Language

1. **Create a new language file**:
   ```bash
   ./manage-translations.sh update -l new_lang
   ```

2. **Synchronize key structure**:
   ```bash
   ./manage-translations.sh sync
   ```

### Cleanup After Large Refactoring

1. **Backup translation files**:
   ```bash
   cp -r .config/quickshell/translations .config/quickshell/translations.backup
   ```

2. **Clean unused keys**:
   ```bash
   ./manage-translations.sh clean
   ```

3. **Synchronize all languages**:
   ```bash
   ./manage-translations.sh sync
   ```

## Supported Translatable Text Formats

The tool recognizes the following formats for translatable texts:

```qml
// Basic format
Translation.tr("Hello, world!")
Translation.tr('Hello, world!')
Translation.tr(`Hello, world!`)

// With line breaks
Translation.tr("Line 1\nLine 2")

// With escape characters
Translation.tr("Say \"Hello\"")

// With parameter placeholders
Translation.tr("Hello, %1!").arg(name)
```

## Example Output

### Status Display
```
$ ./manage-translations.sh status
Analyzing translation status...
=== Current Project Status ===
166 translatable texts extracted

=== Translation File Status ===
  en_US: 470 keys
  zh_CN: 470 keys
```

### Update Translations
```
$ ./manage-translations.sh update -l zh_CN
Updating translation files...
==================================================
Processing language: zh_CN
==================================================
Analysis result:
  Missing keys: 5
  Extra keys: 20

Found 5 missing translation keys:
1. "New feature text"
2. "Another new text"
...

Add these 5 missing keys? (y/n): y
5 keys added

Found 20 extra translation keys:
1. "Removed old text" -> "已删除的旧文本"
...

Delete these 20 extra keys? (y/n): y
20 keys deleted

Translation file saved
```

### Clean Unused Keys
```
$ ./manage-translations.sh clean
Cleaning unused translation keys...
Processing language: zh_CN
Found 50 unused keys:
  1. "old_unused_text"
  2. "deprecated_message"
  ...

Delete these 50 unused keys? (y/n): y
50 keys deleted
Original key count: 470, after cleaning: 420
```

## Advanced Features

### Custom Directory Structure

```bash
# Use custom directories
./translation-manager.py \
  --translations-dir /path/to/translations \
  --source-dir /path/to/source
```

### Ignore Mark Feature

For dynamic resources or special texts that should not be automatically cleaned, you can add `/*keep*/` at the end of the translation value. The tool will automatically ignore these keys and will not delete them during cleaning or syncing.

Example:
```json
{
  "dynamic_key": "Some dynamic value /*keep*/"
}
```

## Notes

1. **Backup is important**: The tool automatically creates backups before cleaning, but it is recommended to manually back up important files

2. **Text extraction limitations**:
   - ~~Only supports static strings, not dynamically constructed strings~~
   - Dynamic resources (such as variable concatenation or runtime-generated text) cannot be automatically extracted. You need to manually add them to the translation file and use the `/*keep*/` mark for ignore management.
   - Must use the `Translation.tr()` format

3. **File encoding**: All files must use UTF-8 encoding

4. **Key naming conventions**: It is recommended to use English for key names and avoid special characters

## Troubleshooting

### Common Issues

**Q: Text does not appear after adding Translation.tr?**
A: You need to import the translation feature in your QML file using `import "root:/"`, otherwise the translation text will not be displayed correctly.

**Q: The number of extracted texts does not match expectations?**
A: Check whether all translatable texts use the `Translation.tr()` format and ensure there are no dynamically constructed strings.

**Q: Some translations are missing after syncing?**
A: Check whether the source language file contains all necessary keys, and consider using a different source language for syncing.

**Q: The cleaning operation deleted needed keys?**
A: Restore from the automatically created backup file and check whether `Translation.tr()` is used correctly in the source code.

### Restore Backup

```bash
# Restore a single file
cp .config/quickshell/translations/zh_CN.json.backup .config/quickshell/translations/zh_CN.json

# Restore all files
cp .config/quickshell/translations.backup/* .config/quickshell/translations/
```
