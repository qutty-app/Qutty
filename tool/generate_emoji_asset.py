#!/usr/bin/env python3
"""Regenerate assets/emoji.json from the official Unicode emoji data.

The picker needs the full RGI emoji set, not a hand-picked list, so the data is
generated from the Unicode Consortium's own file rather than typed out.

    python3 tool/generate_emoji_asset.py            # regenerate the asset
    python3 tool/generate_emoji_asset.py --check    # fail if the source moved on

unicode.org publishes emoji-test.txt only under `latest/`; there is no
per-version URL for it, so the version cannot be pinned in the path. The content
is pinned instead: the asset records the version, the file's date and its
SHA-256, and `--check` re-downloads the source and exits non-zero if the hash no
longer matches what is committed. Bumping to a new Unicode release is therefore
deliberate -- run without `--check`, review the diff, and commit the new hash.

Only `fully-qualified` rows are emitted. `minimally-qualified` and `unqualified`
rows are the same emoji in a degraded encoding, and `component` rows are the
bare skin-tone and hair modifiers, which are only meaningful as a suffix.

Skin tone handling: a two-codepoint row whose second codepoint is a Fitzpatrick
modifier is exactly "base + tone" -- that is the only shape Unicode allows a
modifier to appear in, so multi-codepoint rows that merely *end* in a modifier
(the two-tone handshakes such as U+1FAF1 U+1F3FB U+200D U+1FAF2 U+1F3FF) are
correctly left alone. Every toneable base in the dataset has all five tones, and
`base + tone` reproduces the dataset's own glyph byte for byte, so the toned
variants are not stored: they are derived at runtime by appending the modifier.
The toned rows of bases that have *no* untoned form of their own are the
exception and are kept, otherwise those 45 emoji would be unreachable.
"""

import hashlib
import json
import os
import re
import sys
import urllib.request

EMOJI_TEST_URL = "https://unicode.org/Public/emoji/latest/emoji-test.txt"

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_PATH = os.path.join(HERE, os.pardir, "assets", "emoji.json")

# Fitzpatrick modifiers, light to dark. This order is the order the tone strip
# presents them in.
TONES = [0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF]

ROW = re.compile(
    r"^([0-9A-F ]+);\s*fully-qualified\s*#\s+(\S+)\s+E[\d.]+\s+(\S.*)$"
)
GROUP = re.compile(r"^# group: (.+)$")
SUBGROUP = re.compile(r"^# subgroup: (.+)$")


def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def fetch(url):
    with urllib.request.urlopen(url, timeout=120) as response:
        return response.read()


def parse(text):
    """Returns the browsable groups, in file order, with their subgroups."""
    groups = {}
    order = []
    group = subgroup = None

    for line in text.splitlines():
        group_match = GROUP.match(line)
        if group_match:
            group = group_match.group(1)
            if group not in groups:
                groups[group] = {"id": slug(group), "name": group, "subgroups": []}
                order.append(group)
            subgroup = None
            continue

        subgroup_match = SUBGROUP.match(line)
        if subgroup_match:
            subgroup = subgroup_match.group(1)
            continue

        row = ROW.match(line)
        if not row:
            continue

        codepoints = [int(c, 16) for c in row.group(1).split()]
        glyph = row.group(2)
        if subgroup is None:
            # A group whose rows all predate subgroups; make sure they land
            # somewhere rather than being dropped.
            subgroup = "ungrouped"

        subgroups = groups[group]["subgroups"]
        if not subgroups or subgroups[-1]["id"] != slug(subgroup):
            subgroups.append({"id": slug(subgroup), "name": subgroup, "emoji": []})
        subgroups[-1]["emoji"].append(glyph)

    return [groups[g] for g in order]


def main():
    check_only = "--check" in sys.argv[1:]

    raw = fetch(EMOJI_TEST_URL)
    text = raw.decode("utf-8")
    digest = hashlib.sha256(raw).hexdigest()

    if check_only:
        committed = json.load(open(OUT_PATH, encoding="utf-8"))
        if committed.get("sourceSha256") != digest:
            print(
                "emoji-test.txt has changed upstream "
                f"({committed.get('version')} -> {text.splitlines()[6].split()[-1]}).\n"
                "Run without --check to regenerate assets/emoji.json, then review "
                "and commit the result."
            )
            return 1
        print(
            f"assets/emoji.json matches the source "
            f"(Unicode Emoji {committed.get('version')}, {digest[:16]}...)"
        )
        return 0

    date = ""
    for line in text.splitlines():
        if line.startswith("# Date:"):
            date = line.split(":", 1)[1].strip().rstrip(" GMT")
            break

    groups = parse(text)
    by_codepoint = {}
    for group in groups:
        for subgroup in group["subgroups"]:
            for glyph in subgroup["emoji"]:
                by_codepoint.setdefault(glyph, 0)
                by_codepoint[glyph] += 1

    browsable = {
        glyph
        for group in groups
        for subgroup in group["subgroups"]
        for glyph in subgroup["emoji"]
    }

    # A "base + tone" row is exactly two scalars with a Fitzpatrick modifier
    # last. The length test is on code points, not UTF-16 units -- Python
    # strings are code points, so a ZWJ sequence such as the two-tone handshake
    # U+1FAF1 U+1F3FB U+200D U+1FAF2 U+1F3FF is longer than two and must be
    # left alone, even though it ends in a modifier.
    toned_glyphs = {
        glyph
        for glyph in browsable
        if len(glyph) == 2 and ord(glyph[-1]) in TONES
    }
    base_of = {glyph: glyph[:-1] for glyph in toned_glyphs}

    # A toned row is redundant when the app can offer a tone strip for it, which
    # needs the untoned base to be browsable. The handful of bases that exist
    # only in toned form keep their rows, or they would be unreachable.
    droppable = {
        toned for toned, base in base_of.items() if base in browsable
    }
    kept_toned = toned_glyphs - droppable
    toneable_glyphs = sorted({base_of[toned] for toned in droppable})

    # `Component` is the bare skin-tone and hair modifiers, which are not
    # browsable content on their own, and `ungrouped` catches anything the
    # source file left outside a subgroup. Drop both rather than shipping empty
    # sections the picker would have to render.
    for group in groups:
        group["subgroups"] = [s for s in group["subgroups"] if s["id"] != "ungrouped"]
    groups = [g for g in groups if g["subgroups"]]

    total_kept = 0
    for group in groups:
        for subgroup in group["subgroups"]:
            subgroup["emoji"] = [
                glyph for glyph in subgroup["emoji"] if glyph not in droppable
            ]
            total_kept += len(subgroup["emoji"])

    version = ""
    for line in text.splitlines():
        if line.startswith("# Version:"):
            version = line.split(":", 1)[1].strip().rstrip(".0").rstrip(".")
            break

    asset = {
        "version": version,
        "date": date,
        "source": EMOJI_TEST_URL,
        "sourceSha256": digest,
        "tones": [chr(t) for t in TONES],
        "toneable": toneable_glyphs,
        "groups": groups,
    }

    with open(OUT_PATH, "w", encoding="utf-8") as handle:
        json.dump(asset, handle, ensure_ascii=False, separators=(",", ":"))
        handle.write("\n")

    size = os.path.getsize(OUT_PATH)
    print(f"wrote {OUT_PATH} ({size / 1024:.1f} KiB)")
    print(f"  unicode emoji version : {asset['version']} ({date})")
    print(f"  source sha256         : {asset['sourceSha256'][:16]}...")
    print(f"  groups                : {len(groups)}")
    print(
        f"  subgroups             : "
        f"{sum(len(g['subgroups']) for g in groups)}"
    )
    print(f"  emoji stored          : {total_kept}")
    print(f"  toneable bases        : {len(toneable_glyphs)}")
    print(
        f"  toned kept in grid    : {len(kept_toned)} "
        f"(bases with no untoned form)"
    )
    print(
        f"  toned generated       : "
        f"{len(toneable_glyphs) * len(TONES)} (base + tone at runtime)"
    )
    print(f"  total reachable       : {total_kept + len(toneable_glyphs) * len(TONES)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
