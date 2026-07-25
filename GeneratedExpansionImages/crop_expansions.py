from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path("/Users/zotchik/Documents/Марс Logbook/MarsConquest/GeneratedExpansionImages")
WORKING = ROOT / "working"
FINAL = ROOT / "final"

SOURCES = {
    "hellas-elysium": Path(
        "/Users/zotchik/Documents/Всякое для Марса/"
        "3F8C9DBE-D0FC-4F4D-AC10-9914E12E13E0.jpeg"
    ),
    "colonies": Path(
        "/Users/zotchik/Documents/Всякое для Марса/"
        "8CD2E378-2B4E-49F4-A786-3FB8B1370A1B.jpeg"
    ),
    "base-game": Path(
        "/Users/zotchik/Documents/Всякое для Марса/"
        "8D8DD3B3-71D3-417B-AD57-ADD2D9079F64.jpeg"
    ),
    "turmoil-prelude": Path(
        "/Users/zotchik/Documents/Всякое для Марса/"
        "35C5F252-D108-4086-B0C1-688FB2748EBE.jpeg"
    ),
    "venus": Path(
        "/Users/zotchik/Documents/Всякое для Марса/"
        "547DE26F-500A-4A25-9F00-93FEA81E647C.jpeg"
    ),
}

# Coordinates are measured on the EXIF-normalized scans. Every crop is 2:1.
CROPS = {
    "base-game": ("base-game", (520, 1110, 4434, 3067)),
    "hellas-elysium": ("hellas-elysium", (550, 3400, 3350, 4800)),
    "colonies": ("colonies", (650, 1630, 4370, 3490)),
    "turmoil": ("turmoil-prelude", (165, 555, 3579, 2262)),
    "prelude": ("turmoil-prelude", (4450, 1240, 6250, 2140)),
    "venus-next": ("venus", (700, 1405, 4404, 3257)),
}

LABELS = {
    "base-game": "Базовая игра",
    "hellas-elysium": "Эллада и Элизий",
    "colonies": "Колонии",
    "turmoil": "Кризис",
    "prelude": "Пролог",
    "venus-next": "Проект «Венера»",
}


def normalize_sources() -> None:
    WORKING.mkdir(parents=True, exist_ok=True)
    for name, source in SOURCES.items():
        with Image.open(source) as raw:
            image = ImageOps.exif_transpose(raw).convert("RGB")
            image.save(WORKING / f"{name}-normalized.jpg", quality=95)
            preview = image.copy()
            preview.thumbnail((1800, 1800), Image.Resampling.LANCZOS)
            preview.save(WORKING / f"{name}-preview.jpg", quality=90)


def crop_tiles() -> None:
    FINAL.mkdir(parents=True, exist_ok=True)
    for output_name, (source_name, box) in CROPS.items():
        source = WORKING / f"{source_name}-normalized.jpg"
        with Image.open(source) as image:
            tile = image.crop(box)
            tile = tile.resize((1200, 600), Image.Resampling.LANCZOS)
            tile.save(FINAL / f"{output_name}.png", optimize=True)


def build_contact_sheet() -> None:
    from PIL import ImageDraw, ImageFont

    canvas = Image.new("RGB", (1280, 1200), "#11161c")
    draw = ImageDraw.Draw(canvas)
    font_path = Path(
        "/Users/zotchik/Documents/Марс Logbook/MarsConquest/"
        "MarsConquest/Resources/Fonts/Play-Bold.ttf"
    )
    font = ImageFont.truetype(font_path, 34)

    for index, output_name in enumerate(CROPS):
        row, column = divmod(index, 2)
        x = 30 + column * 625
        y = 30 + row * 390
        with Image.open(FINAL / f"{output_name}.png") as tile:
            preview = tile.resize((600, 300), Image.Resampling.LANCZOS)
            canvas.paste(preview, (x, y))
        draw.text((x, y + 318), LABELS[output_name], fill="#f0f2f5", font=font)

    canvas.save(ROOT / "preview-six-expansions.jpg", quality=92)


if __name__ == "__main__":
    normalize_sources()
    crop_tiles()
    build_contact_sheet()
