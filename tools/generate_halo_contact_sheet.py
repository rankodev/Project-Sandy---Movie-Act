"""Generate the documentation contact sheet showing every available boss halo.

Reads the shipped halo spritesheets (768x512, 8x4 grid of 96x128 frames), takes one
representative frame from each, and lays them out on a dark background with the
db_symbol to pass as `boss_halo`. Output is docs/images/halo_types.png, referenced
by README.md and LISEZMOI.md.

Run from anywhere: python tools/generate_halo_contact_sheet.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

FRAME_W, FRAME_H = 96, 128
COLS, ROWS = 8, 4
# Mid-animation frame, where the aura is at its widest.
PREVIEW_FRAME = 12

GRID_COLS = 6
PADDING = 12
LABEL_H = 22
BACKGROUND = (31, 36, 48, 255)
TILE_BACKGROUND = (16, 19, 26, 255)
LABEL_COLOR = (226, 232, 240, 255)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
HALO_DIR = os.path.join(BASE_DIR, "..", "graphics", "interface", "battle", "boss")
OUTPUT_PATH = os.path.join(BASE_DIR, "..", "docs", "images", "halo_types.png")


def load_font():
    """Return a readable label font, falling back to PIL's bitmap font."""
    for candidate in (r"C:\Windows\Fonts\arialbd.ttf", r"C:\Windows\Fonts\arial.ttf"):
        if os.path.exists(candidate):
            return ImageFont.truetype(candidate, 14)
    return ImageFont.load_default()


def halo_names():
    """Return the db_symbol of every shipped halo, alphabetically."""
    names = []
    for filename in sorted(os.listdir(HALO_DIR)):
        if filename.startswith("halo_") and filename.endswith(".png"):
            names.append(filename[len("halo_"):-len(".png")])
    return names


def extract_frame(name):
    """Return the preview frame of one halo spritesheet, composited on a dark tile."""
    sheet = Image.open(os.path.join(HALO_DIR, f"halo_{name}.png")).convert("RGBA")
    col, row = PREVIEW_FRAME % COLS, PREVIEW_FRAME // COLS
    box = (col * FRAME_W, row * FRAME_H, (col + 1) * FRAME_W, (row + 1) * FRAME_H)
    tile = Image.new("RGBA", (FRAME_W, FRAME_H), TILE_BACKGROUND)
    tile.alpha_composite(sheet.crop(box))
    return tile


def build_sheet(names, font):
    """Lay the halo previews out on a labelled grid."""
    rows = (len(names) + GRID_COLS - 1) // GRID_COLS
    cell_w, cell_h = FRAME_W + PADDING, FRAME_H + LABEL_H + PADDING
    sheet = Image.new("RGBA", (cell_w * GRID_COLS + PADDING, cell_h * rows + PADDING), BACKGROUND)
    draw = ImageDraw.Draw(sheet)

    for index, name in enumerate(names):
        x = PADDING + (index % GRID_COLS) * cell_w
        y = PADDING + (index // GRID_COLS) * cell_h
        sheet.alpha_composite(extract_frame(name), (x, y))
        label = f":{name}"
        width = draw.textbbox((0, 0), label, font=font)[2]
        draw.text((x + (FRAME_W - width) // 2, y + FRAME_H + 4), label, font=font, fill=LABEL_COLOR)

    return sheet


def main():
    names = halo_names()
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    build_sheet(names, load_font()).save(OUTPUT_PATH)
    print(f"{len(names)} halos written to {os.path.normpath(OUTPUT_PATH)}")


if __name__ == "__main__":
    main()
