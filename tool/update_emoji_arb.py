#!/usr/bin/env python3
"""Replace the ad-hoc emoji category keys with the Unicode group keys.

Surgical text edit rather than a JSON round-trip so the `@key` metadata blocks
and the rest of each file stay byte-identical.
"""

import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ARB_DIR = os.path.join(HERE, os.pardir, "lib", "l10n")

OLD_KEYS = [
    "mediaPickerCategorySmileys",
    "mediaPickerCategoryGestures",
    "mediaPickerCategoryAnimals",
    "mediaPickerCategoryFood",
    "mediaPickerCategoryActivities",
    "mediaPickerCategoryTravel",
    "mediaPickerCategoryObjects",
    "mediaPickerCategoryHearts",
]

TRANSLATIONS = {
    "en": [
        "Smileys & Emotion",
        "People & Body",
        "Animals & Nature",
        "Food & Drink",
        "Travel & Places",
        "Activities",
        "Objects",
        "Symbols",
        "Flags",
        "Skin tone",
        "Default",
        "Light",
        "Medium-light",
        "Medium",
        "Medium-dark",
        "Dark",
    ],
    "es": [
        "Emoticonos y sentimientos",
        "Personas y cuerpos",
        "Animales y naturaleza",
        "Comida y bebida",
        "Viajes y lugares",
        "Actividades",
        "Objetos",
        "Símbolos",
        "Banderas",
        "Tono de piel",
        "Predeterminado",
        "Claro",
        "Medio claro",
        "Medio",
        "Medio oscuro",
        "Oscuro",
    ],
    "de": [
        "Smileys & Emotionen",
        "Menschen & Körper",
        "Tiere & Natur",
        "Essen & Trinken",
        "Reisen & Orte",
        "Aktivitäten",
        "Objekte",
        "Symbole",
        "Flaggen",
        "Hautton",
        "Standard",
        "Hell",
        "Mittelhell",
        "Mittel",
        "Mitteldunkel",
        "Dunkel",
    ],
    "fr": [
        "Émoticônes",
        "Personnes et corps",
        "Animaux et nature",
        "Nourriture et boissons",
        "Voyages et lieux",
        "Activités",
        "Objets",
        "Symboles",
        "Drapeaux",
        "Teinte de peau",
        "Par défaut",
        "Clair",
        "Moyennement clair",
        "Moyen",
        "Moyennement foncé",
        "Foncé",
    ],
    "ru": [
        "Смайлы и эмоции",
        "Люди и части тела",
        "Животные и природа",
        "Еда и напитки",
        "Путешествия и места",
        "Активности",
        "Объекты",
        "Символы",
        "Флаги",
        "Тон кожи",
        "По умолчанию",
        "Светлый",
        "Умеренно светлый",
        "Средний",
        "Умеренно тёмный",
        "Тёмный",
    ],
    "uk": [
        "Смайли та емоції",
        "Люди й частини тіла",
        "Тварини й природа",
        "Їжа та напиї",
        "Подорожі й місця",
        "Активності",
        "Об'єкти",
        "Символи",
        "Прапори",
        "Відтінок шкіри",
        "Типово",
        "Світлий",
        "Помірно світлий",
        "Середній",
        "Помірно темний",
        "Темний",
    ],
}

NEW_KEYS = [
    "mediaPickerGroupSmileysEmotion",
    "mediaPickerGroupPeopleBody",
    "mediaPickerGroupAnimalsNature",
    "mediaPickerGroupFoodDrink",
    "mediaPickerGroupTravelPlaces",
    "mediaPickerGroupActivities",
    "mediaPickerGroupObjects",
    "mediaPickerGroupSymbols",
    "mediaPickerGroupFlags",
    "mediaPickerSkinTone",
    "mediaPickerSkinToneDefault",
    "mediaPickerSkinToneLight",
    "mediaPickerSkinToneMediumLight",
    "mediaPickerSkinToneMedium",
    "mediaPickerSkinToneMediumDark",
    "mediaPickerSkinToneDark",
]


def escape(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def main():
    if sorted(NEW_KEYS) != sorted(NEW_KEYS) or len(NEW_KEYS) != 16:
        print("key list is malformed", file=sys.stderr)
        return 1

    for locale, values in TRANSLATIONS.items():
        if len(values) != len(NEW_KEYS):
            print(f"{locale}: {len(values)} values for {len(NEW_KEYS)} keys", file=sys.stderr)
            return 1

        path = os.path.join(ARB_DIR, f"app_{locale}.arb")
        with io.open(path, encoding="utf-8") as handle:
            lines = handle.read().split("\n")

        first = next(
            (i for i, line in enumerate(lines) if f'"{OLD_KEYS[0]}"' in line), None
        )
        last = next(
            (i for i, line in enumerate(lines) if f'"{OLD_KEYS[-1]}"' in line), None
        )
        if first is None or last is None or last < first:
            print(f"{locale}: could not locate the old category keys", file=sys.stderr)
            return 1

        block = "\n".join(lines[first : last + 1])
        for key in OLD_KEYS:
            if f'"{key}"' not in block:
                print(f"{locale}: old keys are not contiguous at {key}", file=sys.stderr)
                return 1

        replacement = [
            f'  "{key}": "{escape(value)}",'
            for key, value in zip(NEW_KEYS, values)
        ]
        lines[first : last + 1] = replacement

        with io.open(path, "w", encoding="utf-8") as handle:
            handle.write("\n".join(lines))

        print(f"{locale}: replaced {len(OLD_KEYS)} category keys with {len(NEW_KEYS)}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
