#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Translation File Maintenance Helper
Used to clean and organize translation files, removing unused keys
"""

import os
import sys
import json
import argparse
import importlib.util
from pathlib import Path
from typing import Dict, Set, List

# Import from the same directory using importlib
current_dir = os.path.dirname(os.path.abspath(__file__))
manager_path = os.path.join(current_dir, 'translation-manager.py')
spec = importlib.util.spec_from_file_location("translation_manager", manager_path)
translation_manager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(translation_manager)
TranslationManager = translation_manager.TranslationManager

def clean_translation_files(translations_dir: str, source_dir: str, backup: bool = True):
    """Clean translation files by removing unused keys"""
    print("Starting translation file cleanup...")
    
    # Create manager
    manager = TranslationManager(translations_dir, source_dir)
    
    # Extract currently used texts
    print("Extracting currently used translatable texts...")
    current_texts = manager.extract_translatable_texts()
    print(f"Extracted {len(current_texts)} currently used texts")
    
    # Get all language files
    languages = manager.get_available_languages()
    if not languages:
        print("No translation files found")
        return
    
    print(f"Found language files: {', '.join(languages)}")
    
    total_removed = 0
    
    for lang in languages:
        print(f"\nProcessing language: {lang}")
        
        # Load translation file
        translations = manager.load_translation_file(lang)
        original_count = len(translations)
        
        # Find unused keys, skip those whose value ends with /*keep*/
        unused_keys = set()
        for k in translations.keys():
            v = translations[k]
            if k not in current_texts:
                if isinstance(v, str) and v.strip().endswith('/*keep*/'):
                    continue
                unused_keys.add(k)

        if unused_keys:
            print(f"Found {len(unused_keys)} unused keys:")
            for i, key in enumerate(sorted(unused_keys)[:10], 1):  # Only show first 10
                print(f"  {i}. \"{key[:50]}{'...' if len(key) > 50 else ''}\"")
            if len(unused_keys) > 10:
                print(f"  ... and {len(unused_keys) - 10} more keys")

            response = input(f"Delete these {len(unused_keys)} unused keys? (y/n): ")
            if response.lower().strip() in ['y', 'yes']:
                if backup:
                    # Create backup only when user confirms deletion
                    backup_file = Path(translations_dir) / f"{lang}.json.bak"
                    with open(backup_file, 'w', encoding='utf-8') as f:
                        json.dump(translations, f, ensure_ascii=False, indent=2)
                    print(f"Created backup: {backup_file}")
                # Delete unused keys
                for key in unused_keys:
                    del translations[key]

                # Save cleaned file
                manager.save_translation_file(lang, translations)
                removed_count = len(unused_keys)
                total_removed += removed_count
                print(f"Deleted {removed_count} keys")
            else:
                print("Skipped deletion")
        else:
            print("No unused keys found")

        new_count = len(translations)
        print(f"Original key count: {original_count}, after cleanup: {new_count}")
    
    print(f"\nCleanup completed! Total deleted {total_removed} unused keys.")

def sync_translations(translations_dir: str, source_lang: str = "en_US", target_langs: List[str] = None):
    """Sync translation keys to ensure all language files have the same keys"""
    print(f"Starting translation key sync using {source_lang} as reference...")
    
    translations_path = Path(translations_dir)
    
    # Load source language file
    source_file = translations_path / f"{source_lang}.json"
    if not source_file.exists():
        print(f"Error: Source language file does not exist: {source_file}")
        return
    
    with open(source_file, 'r', encoding='utf-8') as f:
        source_translations = json.load(f)
    
    source_keys = set(source_translations.keys())
    print(f"Source language {source_lang} has {len(source_keys)} keys")
    
    # Get target language list
    if target_langs is None:
        target_langs = []
        for file_path in translations_path.glob("*.json"):
            lang_code = file_path.stem
            if lang_code != source_lang:
                target_langs.append(lang_code)
    
    if not target_langs:
        print("No target language files found")
        return
    
    print(f"Target languages: {', '.join(target_langs)}")
    
    for target_lang in target_langs:
        print(f"\nSyncing language: {target_lang}")
        
        target_file = translations_path / f"{target_lang}.json"
        if target_file.exists():
            with open(target_file, 'r', encoding='utf-8') as f:
                target_translations = json.load(f)
        else:
            target_translations = {}
        
        target_keys = set(target_translations.keys())
        
        # Find missing and extra keys
        missing_keys = source_keys - target_keys
        extra_keys = target_keys - source_keys
        
        print(f"  Missing keys: {len(missing_keys)}")
        print(f"  Extra keys: {len(extra_keys)}")
        
        # Add missing keys
        if missing_keys:
            for key in missing_keys:
                # Use source language value as placeholder by default
                target_translations[key] = source_translations[key]
            print(f"  Added {len(missing_keys)} missing keys")
        
        # Ask whether to delete extra keys
        if extra_keys:
            response = input(f"  Delete {len(extra_keys)} extra keys? (y/n): ")
            if response.lower().strip() in ['y', 'yes']:
                for key in extra_keys:
                    del target_translations[key]
                print(f"  Deleted {len(extra_keys)} extra keys")
        
        # Save file (ensure UTF-8, fix for special chars)
        with open(target_file, 'w', encoding='utf-8', newline='') as f:
            json.dump(target_translations, f, ensure_ascii=False, indent=2)
        print(f"  Saved: {target_file}")

def main():
    parser = argparse.ArgumentParser(description="Translation File Maintenance Helper")
    parser.add_argument("--translations-dir", "-t", 
                       default=".config/quickshell/translations",
                       help="Translation files directory")
    parser.add_argument("--source-dir", "-s", 
                       default=".config/quickshell",
                       help="Source code directory")
    parser.add_argument("--clean", "-c", action="store_true",
                       help="Clean unused translation keys")
    parser.add_argument("--sync", action="store_true",
                       help="Sync translation keys")
    parser.add_argument("--source-lang", default="en_US",
                       help="Source language for syncing (default: en_US)")
    parser.add_argument("--no-backup", action="store_true",
                       help="Do not create backup files when cleaning")
    
    args = parser.parse_args()
    
    # Convert to absolute paths
    translations_dir = os.path.abspath(args.translations_dir)
    source_dir = os.path.abspath(args.source_dir)
    
    if args.clean:
        clean_translation_files(translations_dir, source_dir, backup=not args.no_backup)
    elif args.sync:
        sync_translations(translations_dir, args.source_lang)
    else:
        print("Please specify an operation:")
        print("  --clean: Clean unused translation keys")
        print("  --sync: Sync translation keys")

if __name__ == "__main__":
    main()
