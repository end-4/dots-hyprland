# hyprland-settings/generate_colors.py
import sys
import json
import os
from pathlib import Path
from PIL import Image
from materialyoucolor.quantize import QuantizeCelebi
from materialyoucolor.score.score import Score
from materialyoucolor.hct import Hct
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.utils.color_utils import argb_from_rgb, red_from_argb, green_from_argb, blue_from_argb

# ИСПРАВЛЕНО: Динамический импорт всех возможных схем, как в quickshell
def get_scheme_class(scheme_name):
    if scheme_name == 'scheme-fruit-salad':
        from materialyoucolor.scheme.scheme_fruit_salad import SchemeFruitSalad as Scheme
    elif scheme_name == 'scheme-expressive':
        from materialyoucolor.scheme.scheme_expressive import SchemeExpressive as Scheme
    elif scheme_name == 'scheme-monochrome':
        from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome as Scheme
    elif scheme_name == 'scheme-rainbow':
        from materialyoucolor.scheme.scheme_rainbow import SchemeRainbow as Scheme
    elif scheme_name == 'scheme-neutral':
        from materialyoucolor.scheme.scheme_neutral import SchemeNeutral as Scheme
    elif scheme_name == 'scheme-fidelity':
        from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity as Scheme
    elif scheme_name == 'scheme-content':
        from materialyoucolor.scheme.scheme_content import SchemeContent as Scheme
    elif scheme_name == 'scheme-vibrant':
        from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant as Scheme
    else: # По умолчанию используем tonal-spot, как в quickshell
        from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot as Scheme
    return Scheme

def argb_to_hex(argb: int) -> str:
    return "#{:02x}{:02x}{:02x}".format(red_from_argb(argb), green_from_argb(argb), blue_from_argb(argb))

def get_config_data():
    """Читает и возвращает данные из двух ключевых файлов конфигурации."""
    config = {}
    quickshell_config_file = Path.home() / ".config/illogical-impulse/config.json"

    if quickshell_config_file.exists():
        try:
            with open(quickshell_config_file, "r") as f:
                config = json.load(f)
        except Exception as e:
            print(f"[generate_colors.py] Error reading {quickshell_config_file}: {e}", file=sys.stderr)
    
    return config

def get_wallpaper_path(config):
    """Получает путь к обоям из данных конфигурации."""
    thumbnail_path_str = config.get("background", {}).get("thumbnailPath")
    if thumbnail_path_str:
        thumbnail_path = Path(thumbnail_path_str).expanduser()
        if thumbnail_path.exists():
            return thumbnail_path

    wallpaper_path_str = config.get("background", {}).get("wallpaperPath")
    if wallpaper_path_str:
        wallpaper_path = Path(wallpaper_path_str).expanduser()
        if wallpaper_path.exists():
            return wallpaper_path
    return None

def get_scheme_type_from_config(config):
    """Получает название схемы из конфигурации, по умолчанию 'auto'."""
    return config.get("appearance", {}).get("palette", {}).get("type", "auto")

def generate_colors(image_path: Path, scheme_name: str):
    if not image_path or not image_path.exists():
        return None
    try:
        image = Image.open(image_path)
        if image.mode in ["L", "P", "RGBA"]:
            image = image.convert('RGB')
        image.thumbnail((128, 128))
        pixels = list(image.getdata())
        quantized_colors = QuantizeCelebi(pixels, 128)
        main_color_argb = Score.score(quantized_colors)[0]
        hct = Hct.from_int(main_color_argb)
        
        # ИСПРАВЛЕНО: Используем класс схемы, который был динамически выбран
        Scheme = get_scheme_class(scheme_name)
        scheme = Scheme(hct, is_dark=True, contrast_level=0.0)

        colors = {
            # Основные
            "background": argb_to_hex(MaterialDynamicColors.background.get_hct(scheme).to_int()),
            "primary": argb_to_hex(MaterialDynamicColors.primary.get_hct(scheme).to_int()),
            "outline": argb_to_hex(MaterialDynamicColors.outline.get_hct(scheme).to_int()),
            "error": argb_to_hex(MaterialDynamicColors.error.get_hct(scheme).to_int()),
            # Текст
            "text": argb_to_hex(MaterialDynamicColors.onSurface.get_hct(scheme).to_int()),
            "subtext": argb_to_hex(MaterialDynamicColors.onSurfaceVariant.get_hct(scheme).to_int()),
            # Поверхности (для выделения элементов)
            "surface": argb_to_hex(MaterialDynamicColors.surface.get_hct(scheme).to_int()),
            "surfaceBright": argb_to_hex(MaterialDynamicColors.surfaceBright.get_hct(scheme).to_int()),
            "surfaceHigh": argb_to_hex(MaterialDynamicColors.surfaceBright.get_hct(scheme).to_int()),
            "surfaceContainerLow": argb_to_hex(MaterialDynamicColors.surfaceContainerLow.get_hct(scheme).to_int()),
            "surfaceContainer": argb_to_hex(MaterialDynamicColors.surfaceContainer.get_hct(scheme).to_int()),
            "surfaceContainerHigh": argb_to_hex(MaterialDynamicColors.surfaceContainerHigh.get_hct(scheme).to_int()),
            # ИЗМЕНЕНИЕ: Добавлены новые цвета для кнопок навигации
            "secondaryContainer": argb_to_hex(MaterialDynamicColors.secondaryContainer.get_hct(scheme).to_int()),
            "onSecondaryContainer": argb_to_hex(MaterialDynamicColors.onSecondaryContainer.get_hct(scheme).to_int()),
        }
        return colors
    except Exception as e:
        print(f"[generate_colors.py] Failed to generate colors from image: {e}", file=sys.stderr)
        return None

if __name__ == "__main__":
    config_data = get_config_data()
    wallpaper_path = get_wallpaper_path(config_data)
    
    if wallpaper_path:
        scheme_type = get_scheme_type_from_config(config_data)
        
        # ИСПРАВЛЕНО: Логика для режима 'auto'
        if scheme_type == "auto":
            print("[generate_colors.py] Scheme type is 'auto', defaulting to 'scheme-tonal-spot' for simplicity.")
            scheme_type = "scheme-tonal-spot"
        
        print(f"[generate_colors.py] Using wallpaper: {wallpaper_path}")
        print(f"[generate_colors.py] Using scheme: {scheme_type}")

        color_scheme = generate_colors(wallpaper_path, scheme_type)
        
        if color_scheme:
            config_dir = Path.home() / ".config/hyprland-settings"
            config_dir.mkdir(parents=True, exist_ok=True)
            theme_file_path = config_dir / "theme.json"
            try:
                with open(theme_file_path, "w") as f:
                    json.dump(color_scheme, f)
                print(f"[generate_colors.py] Theme successfully saved to {theme_file_path}")
            except IOError as e:
                print(f"[generate_colors.py] FATAL: Could not write theme file: {e}", file=sys.stderr)
                sys.exit(1)
        else:
            print("[generate_colors.py] FATAL: Color scheme generation failed.", file=sys.stderr)
            sys.exit(1)
    else:
        print("[generate_colors.py] Did not generate theme because no wallpaper was found in config.")