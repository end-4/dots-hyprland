from materialyoucolor.scheme.dynamic_scheme import DynamicSchemeOptions, DynamicScheme
from materialyoucolor.scheme.variant import Variant
from materialyoucolor.palettes.tonal_palette import TonalPalette


class SchemeMoreVibrant(DynamicScheme):
    hues = [0.0, 41.0, 61.0, 101.0, 131.0, 181.0, 251.0, 301.0, 360.0]
    secondary_rotations = [18.0, 15.0, 10.0, 12.0, 15.0, 18.0, 15.0, 12.0, 12.0]
    tertiary_rotations = [35.0, 30.0, 20.0, 25.0, 30.0, 35.0, 30.0, 25.0, 25.0]

    def __init__(self, source_color_hct, is_dark, contrast_level):
        super().__init__(
            DynamicSchemeOptions(
                source_color_argb=source_color_hct.to_int(),
                variant=Variant.VIBRANT,
                contrast_level=contrast_level,
                is_dark=is_dark,
                primary_palette=TonalPalette.from_hue_and_chroma(
                    source_color_hct.hue, 200.0
                ),
                secondary_palette=TonalPalette.from_hue_and_chroma(
                    DynamicScheme.get_rotated_hue(
                        source_color_hct,
                        SchemeMoreVibrant.hues,
                        SchemeMoreVibrant.secondary_rotations,
                    ),
                    32.0,
                ),
                tertiary_palette=TonalPalette.from_hue_and_chroma(
                    DynamicScheme.get_rotated_hue(
                        source_color_hct,
                        SchemeMoreVibrant.hues,
                        SchemeMoreVibrant.tertiary_rotations,
                    ),
                    32.0,
                ),
                neutral_palette=TonalPalette.from_hue_and_chroma(
                    source_color_hct.hue, 13.0
                ),
                neutral_variant_palette=TonalPalette.from_hue_and_chroma(
                    source_color_hct.hue, 15.0
                ),
            )
        )
