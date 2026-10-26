#!/usr/bin/env python3
"""Pripraví grafiku a zvuky pre hru zo zdrojových balíkov.

Použitie:
    python3 tools/prepare_assets.py <kenney_new_platformer_pack> <speech_therapy_game_v2> <kenney_extra>

- kenney_new_platformer_pack: rozbalený „New Platformer Pack“ od Kenney (CC0), https://kenney.nl
- speech_therapy_game_v2: klon https://github.com/JojDobre/Speech-Therapy-Game-v2 (baník, zvuky)
- kenney_extra: priečinok s rozbalenými balíkmi Kenney „music-jingles“, „impact-sounds“, „interface-sounds“ (CC0)

Hudba (assets/music/) sa do hry kopíruje ručne – pôvod je v CREDITS.md.

Výstup ide do assets/. Výsledné súbory sú v repozitári, skript treba spustiť iba pri zmene zdrojov.
"""
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
TILE = 64

# Baník: animácia -> (zdrojový názov, rozsah snímok)
MINER_ANIMATIONS = {
    "idle": ("idle", range(0, 20)),
    "run": ("run", range(0, 8)),
    "jump": ("jump", range(3, 8)),
    "fall": ("falling", range(0, 10)),
    "hurt": ("hurt", range(0, 5)),
    "die": ("die", range(0, 5)),
}
MINER_HEIGHT = 104  # výška snímky v pixeloch hry
# Spoločný výrez zo zdrojových snímok (1028×872) – obrys všetkých animácií zeleného baníka.
MINER_CROP = (83, 58, 855, 811)
# id obleku -> (priečinok, predpona súborov) v keyframes/
MINER_OUTFITS = {
    "green": ("green_miner", "__green_miner_"),
    "yellow": ("yellow_hat", "__yellow_hat_"),
    "red_shirt": ("red_shirt_miner", "__red_shirt_miner_"),
    "blue": ("red_head_miner", "__miner_"),
    "old": ("old_miner", "__old_miner_"),
}

# Poradie dielov terénu v atlase (stĺpec v riadku 0). Názvy podľa Kenney.
TERRAIN_TILES = [
    "block", "horizontal_left", "horizontal_middle", "horizontal_right",
    "vertical_top", "vertical_middle", "vertical_bottom",
    "block_top_left", "block_top", "block_top_right",
    "block_left", "block_center", "block_right",
    "block_bottom_left", "block_bottom", "block_bottom_right",
]
CLOUD_TILES = ["cloud_left", "cloud_middle", "cloud_right"]

TILE_SPRITES = {
    "items": ["coin_gold", "star", "gem_yellow", "gem_blue", "gem_green", "gem_red", "heart", "key_yellow",
              "spring", "spring_out", "flag_red_a", "flag_green_a", "flag_green_b", "door_open", "door_open_top"],
    "blocks": ["block_coin_active", "block_strong_coin_active", "block_exclamation_active", "block_empty",
               "block_strong_empty", "bricks_brown", "brick_brown", "lock_yellow", "block_blue",
               "switch_blue", "switch_blue_pressed", "block_planks", "bridge_logs"],
    "hazards": ["spikes", "lava", "lava_top"],
    "props": ["bush", "grass", "grass_purple", "mushroom_red", "mushroom_brown", "fence", "fence_broken",
              "sign", "sign_right", "sign_exit", "rock", "hill", "hill_top"],
    "ui": ["hud_heart", "hud_heart_empty", "hud_coin", "hud_key_yellow"],
}
ENEMY_SPRITES = ["slime_normal_walk_a", "slime_normal_walk_b", "slime_normal_flat",
                 "slime_spike_walk_a", "slime_spike_walk_b", "slime_spike_flat",
                 "snail_walk_a", "snail_walk_b", "snail_shell",
                 "mouse_walk_a", "mouse_walk_b", "mouse_rest",
                 "frog_idle", "frog_jump", "frog_rest",
                 "bee_a", "bee_b", "bee_rest", "fly_a", "fly_b", "fly_rest",
                 "block_idle", "block_fall", "block_rest", "saw_a", "saw_b"]
BACKGROUNDS = ["background_solid_sky", "background_color_hills", "background_clouds", "background_fade_trees"]
KENNEY_SOUNDS = ["sfx_jump", "sfx_jump-high", "sfx_coin", "sfx_gem", "sfx_hurt", "sfx_bump", "sfx_disappear", "sfx_magic"]
GAME_SOUNDS = {"effects/vyhra.mp3": "win.mp3", "effects/zlato.wav": "gold.wav"}
# Ďalšie Kenney zvuky: (balík, cesta v priečinku Audio) -> názov v hre
EXTRA_SOUNDS = {
    ("music-jingles", "8-Bit jingles/jingles_NES12.ogg"): "secret.ogg",
    ("music-jingles", "8-Bit jingles/jingles_NES09.ogg"): "powerup.ogg",
    ("music-jingles", "8-Bit jingles/jingles_NES03.ogg"): "key.ogg",
    ("impact-sounds", "impactPlank_medium_000.ogg"): "break.ogg",
    ("impact-sounds", "impactPunch_heavy_000.ogg"): "slam.ogg",
    ("impact-sounds", "impactGlass_light_001.ogg"): "shield_pop.ogg",
    ("interface-sounds", "switch_002.ogg"): "switch.ogg",
    ("interface-sounds", "question_001.ogg"): "alert.ogg",
}


def prepare_miner(source: Path) -> None:
    """Všetky obleky baníka orezané rovnakým výrezom – snímky majú rovnakú veľkosť aj polohu postavy."""
    keyframes = source / "images/superjozino/assets/player/keyframes"
    width = round((MINER_CROP[2] - MINER_CROP[0]) * MINER_HEIGHT / (MINER_CROP[3] - MINER_CROP[1]))
    for outfit, (folder, prefix) in MINER_OUTFITS.items():
        out_dir = ASSETS / "player" / outfit
        out_dir.mkdir(parents=True, exist_ok=True)
        for anim, (name, frames) in MINER_ANIMATIONS.items():
            strip = Image.new("RGBA", (width * len(frames), MINER_HEIGHT))
            for i, frame_index in enumerate(frames):
                im = Image.open(keyframes / folder / f"{prefix}{name}_{frame_index:03d}.png").convert("RGBA")
                frame = im.crop(MINER_CROP).resize((width, MINER_HEIGHT), Image.LANCZOS)
                strip.alpha_composite(frame, (i * width, 0))
            strip.save(out_dir / f"jozino_{anim}.png", optimize=True)
    print(f"baník: {len(MINER_OUTFITS)} oblekov, snímka {width}x{MINER_HEIGHT}")


def prepare_kenney(kenney: Path) -> None:
    tiles = kenney / "Sprites/Tiles/Default"
    atlas = Image.new("RGBA", (TILE * len(TERRAIN_TILES), TILE * 2))
    for i, name in enumerate(TERRAIN_TILES):
        atlas.alpha_composite(Image.open(tiles / f"terrain_grass_{name}.png").convert("RGBA"), (i * TILE, 0))
    for i, name in enumerate(CLOUD_TILES):
        atlas.alpha_composite(Image.open(tiles / f"terrain_grass_{name}.png").convert("RGBA"), (i * TILE, TILE))
    (ASSETS / "tilesets").mkdir(parents=True, exist_ok=True)
    atlas.save(ASSETS / "tilesets/terrain_grass.png", optimize=True)

    for folder, names in TILE_SPRITES.items():
        (ASSETS / folder).mkdir(parents=True, exist_ok=True)
        for name in names:
            shutil.copy(tiles / f"{name}.png", ASSETS / folder / f"{name}.png")
    (ASSETS / "enemies").mkdir(parents=True, exist_ok=True)
    for name in ENEMY_SPRITES:
        shutil.copy(kenney / f"Sprites/Enemies/Default/{name}.png", ASSETS / "enemies" / f"{name}.png")
    (ASSETS / "backgrounds").mkdir(parents=True, exist_ok=True)
    for name in BACKGROUNDS:
        shutil.copy(kenney / f"Sprites/Backgrounds/Default/{name}.png", ASSETS / "backgrounds" / f"{name}.png")
    make_parallax_layers()
    (ASSETS / "audio").mkdir(parents=True, exist_ok=True)
    for name in KENNEY_SOUNDS:
        shutil.copy(kenney / f"Sounds/{name}.ogg", ASSETS / "audio" / f"{name.replace('-', '_')}.ogg")
    shutil.copy(kenney / "License.txt", ASSETS / "LICENSE_kenney.txt")


def _key_out(image: Image.Image, color: tuple, tolerance: int = 6) -> Image.Image:
    """Farbu pozadia nahradí priehľadnosťou (Kenney pozadia sú nepriehľadné dlaždice)."""
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, _ = pixels[x, y]
            if abs(r - color[0]) <= tolerance and abs(g - color[1]) <= tolerance and abs(b - color[2]) <= tolerance:
                pixels[x, y] = (r, g, b, 0)
    return image


def _tile_horizontally(image: Image.Image, times: int) -> Image.Image:
    """Parallax2D opakuje vrstvu plynulo iba vtedy, keď je širšia ako obrazovka."""
    wide = Image.new("RGBA", (image.width * times, image.height))
    for i in range(times):
        wide.alpha_composite(image, (i * image.width, 0))
    return wide


def _extend_down(image: Image.Image, extra: int) -> Image.Image:
    """Predĺži vrstvu farbou spodného riadku – pri vysokej kamere a na tabletoch nevznikne medzera."""
    taller = Image.new("RGBA", (image.width, image.height + extra))
    taller.paste(image.getpixel((0, image.height - 1)), (0, image.height, image.width, image.height + extra))
    taller.alpha_composite(image, (0, 0))
    return taller


def make_parallax_layers() -> None:
    bg = ASSETS / "backgrounds"
    white, sky = (255, 255, 255), (195, 227, 255)
    layers = {
        "layer_trees": ("background_fade_trees", white),
        "layer_hills": ("background_color_hills", white),
        "layer_clouds": ("background_clouds", sky),
    }
    for out, (src, key) in layers.items():
        layer = _tile_horizontally(_key_out(Image.open(bg / f"{src}.png"), key), 4)
        if out == "layer_hills":
            layer = _extend_down(layer, 256)
        layer.save(bg / f"{out}.png", optimize=True)
    for name in BACKGROUNDS:
        (bg / f"{name}.png").unlink()


def prepare_game_sounds(source: Path) -> None:
    for src, dst in GAME_SOUNDS.items():
        shutil.copy(source / "zvuky" / src, ASSETS / "audio" / dst)


def prepare_extra_sounds(extra: Path) -> None:
    for (pack, path), dst in EXTRA_SOUNDS.items():
        shutil.copy(extra / pack / "Audio" / path, ASSETS / "audio" / dst)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    prepare_kenney(Path(sys.argv[1]))
    prepare_miner(Path(sys.argv[2]))
    prepare_game_sounds(Path(sys.argv[2]))
    prepare_extra_sounds(Path(sys.argv[3]))
