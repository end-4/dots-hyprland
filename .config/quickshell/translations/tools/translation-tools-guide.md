# Translation Management Tool Suite

This tool suite is used to manage project translation files, automatically extract translatable texts, compare differences between different language files, and provide maintenance functions.

## Tool Components

### 1. `translation-manager.py` - Main Translation Manager
- Extract translatable texts
- Compare and update translation files
- Interactive adding/removing translation keys

### 2. `translation-cleaner.py` - Translation File Maintenance Tool
- Clean unused translation keys
- Sync key structure across different language files

### 3. `manage-translations.sh` - Convenient Wrapper Script
- Provide unified command-line interface
- Display translation status
- Simplify common operations

## Quick Start

### Check Translation Status
```bash
./manage-translations.sh status
```

### Extract Translatable Texts
```bash
./manage-translations.sh extract
```

### Update Translation Files
```bash
# Update all languages
./manage-translations.sh update

# Update specific language
./manage-translations.sh update -l zh_CN
```

### Clean Unused Keys
```bash
./manage-translations.sh clean
```

### Sync Keys Across Languages
```bash
./manage-translations.sh sync
```

## Detailed Usage

### translation-manager.py

The main translation management tool that extracts translatable texts from source code and manages translation files.

#### Command Line Options
```bash
python3 translation-manager.py [options]

Options:
  -h, --help            Show help message
  -t, --translations-dir DIR  Translation files directory (default: .config/quickshell/translations)
  -s, --source-dir DIR  Source code directory (default: .config/quickshell)
  -l, --language LANG   Specify language code to process (e.g., zh_CN)
  -e, --extract-only    Only extract translatable texts to temporary file
  --show-temp           Show temporary extracted file content
```

#### Features
1. **Text Extraction**: Uses regex patterns to extract translatable texts from QML and JavaScript files
2. **Smart Filtering**: Automatically removes duplicates and cleans up extracted texts
3. **Interactive Updates**: Guides users through adding missing keys and removing extra ones
4. **Backup Support**: Creates backups before making changes

#### Supported Text Patterns
- `qsTr("text")` and `qsTr('text')`
- `i18n.t("text")` and `i18n.t('text')`
- Supports nested quotes and escape characters
- Handles multiline strings

### translation-cleaner.py

A maintenance tool for cleaning up and synchronizing translation files.

#### Command Line Options
```bash
python3 translation-cleaner.py [options]

Options:
  -h, --help            Show help message
  -t, --translations-dir DIR  Translation files directory
  -s, --source-dir DIR  Source code directory
  -c, --clean           Clean unused translation keys
  --sync                Sync translation keys
  --source-lang LANG    Source language for syncing (default: en_US)
  --no-backup           Do not create backup files when cleaning
```

#### Features
1. **Unused Key Cleanup**: Identifies and removes translation keys that are no longer used in the source code
2. **Key Synchronization**: Ensures all language files have the same set of keys
3. **Backup Protection**: Creates backup files before making destructive changes
4. **Interactive Confirmation**: Asks for user confirmation before deleting keys

### manage-translations.sh

A convenient wrapper script that provides a unified interface to all translation tools.

#### Commands
```bash
./manage-translations.sh [options] <command>

Commands:
  extract      Extract translatable texts to temporary file
  update       Update translation files (add missing/remove extra keys)
  clean        Clean unused translation keys
  sync         Sync keys across all language files
  status       Show translation status

Options:
  -l, --lang LANG     Specify language (e.g.: zh_CN)
  -t, --trans-dir DIR Translation files directory
  -s, --source-dir DIR Source code directory
  -h, --help          Show help message
```

## Workflow Examples

### Initial Setup
1. Create translation directory structure
2. Extract all translatable texts: `./manage-translations.sh extract`
3. Create initial translation files: `./manage-translations.sh update`

### Regular Maintenance
1. Check status: `./manage-translations.sh status`
2. Update translations after code changes: `./manage-translations.sh update`
3. Clean up unused keys periodically: `./manage-translations.sh clean`

### Adding New Language
1. Create new language file: `./manage-translations.sh update -l new_lang`
2. Sync keys if needed: `./manage-translations.sh sync`

## File Structure

```
translations/
├── tools/                          # Translation management tools
│   ├── translation-manager.py      # Main extraction and update tool
│   ├── translation-cleaner.py      # Cleanup and sync tool
│   ├── manage-translations.sh      # Wrapper script
│   └── translation-tools-guide.md  # This documentation
├── en_US.json                      # English translations (reference)
├── zh_CN.json                      # Chinese translations
└── [other_lang].json               # Other language files
```

## Configuration

### Text Extraction Patterns

The tool uses regex patterns to identify translatable texts. Current patterns include:

1. **QML qsTr patterns**:
   - `qsTr("text")` and `qsTr('text')`
   - Supports escaped quotes and nested quotes

2. **JavaScript i18n patterns**:
   - `i18n.t("text")` and `i18n.t('text')`
   - Supports template literals and complex expressions

3. **Custom patterns** can be added by modifying the patterns list in `translation-manager.py`

### File Extensions

By default, the tool processes:
- `.qml` files (QML/QtQuick)
- `.js` files (JavaScript)

Additional file types can be added by modifying the file extension filters.

## Best Practices

1. **Regular Updates**: Run `./manage-translations.sh status` regularly to check for new translatable texts
2. **Clean Periodically**: Use `./manage-translations.sh clean` to remove unused keys
3. **Backup Important**: Always backup translation files before major changes
4. **Consistent Patterns**: Use consistent function calls (`qsTr`, `i18n.t`) for translatable texts
5. **Review Changes**: Always review the changes before confirming deletions or additions

## Troubleshooting

### Common Issues

1. **Missing Texts**: If some translatable texts are not extracted, check if they match the supported patterns
2. **Path Issues**: Ensure the source and translation directory paths are correct
3. **Permission Errors**: Make sure the script has write permissions to the translation directory
4. **Encoding Issues**: All files should be saved in UTF-8 encoding

### Getting Help

For additional help:
- Use `--help` option with any tool
- Check the console output for error messages
- Verify file paths and permissions

## Advanced Usage

### Custom Regex Patterns

To add support for new translation function patterns, modify the `patterns` list in `TranslationManager.extract_translatable_texts()`:

```python
patterns = [
    # Existing patterns...
    r'customTranslate\s*\(\s*(["\'])((?:\\.|(?!\1)[^\\])*?)\1\s*\)',  # Custom pattern
]
```

### Batch Processing

For processing multiple projects or directories:

```bash
# Process multiple directories
for dir in project1 project2 project3; do
    ./manage-translations.sh -s "$dir" -t "$dir/translations" update
done
```

### Integration with Build Systems

The tools can be integrated into build systems to automatically update translations:

```bash
# In your build script
./manage-translations.sh update --non-interactive
```

## Version History

- **v1.0**: Initial version with basic extraction and update functionality
- **v1.1**: Added improved regex patterns for better text extraction
- **v1.2**: Added cleaning and synchronization tools
- **v1.3**: Added English output and improved user interface
- **v1.4**: Moved all tools to dedicated tools directory and improved documentation
