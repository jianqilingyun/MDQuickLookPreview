#!/usr/bin/env python3

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent.parent
APPICONSET = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"


def draw_icon(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)

    inset = size * 0.06
    radius = int(size * 0.22)
    shadow_draw.rounded_rectangle(
        [inset, inset + size * 0.018, size - inset, size - inset + size * 0.018],
        radius=radius,
        fill=(24, 18, 12, 46),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(2, size // 48)))
    image.alpha_composite(shadow)

    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    for y in range(size):
        progress = y / max(1, size - 1)
        top = (243, 231, 217)
        bottom = (218, 195, 171)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * progress) for i in range(3)) + (255,)
        bg_draw.line([(0, y), (size, y)], fill=color)

    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([inset, inset, size - inset, size - inset], radius=radius, fill=255)
    image.paste(bg, (0, 0), mask)

    draw = ImageDraw.Draw(image)

    doc_left = size * 0.20
    doc_top = size * 0.15
    doc_right = size * 0.68
    doc_bottom = size * 0.80
    doc_radius = int(size * 0.09)

    draw.rounded_rectangle(
        [doc_left, doc_top, doc_right, doc_bottom],
        radius=doc_radius,
        fill=(255, 252, 247, 255),
        outline=(188, 167, 145, 255),
        width=max(1, int(size * 0.012)),
    )

    fold = size * 0.12
    draw.polygon(
        [
            (doc_right - fold, doc_top),
            (doc_right, doc_top),
            (doc_right, doc_top + fold),
        ],
        fill=(233, 223, 212, 255),
    )
    draw.line(
        [(doc_right - fold, doc_top), (doc_right - fold, doc_top + fold)],
        fill=(188, 167, 145, 255),
        width=max(1, int(size * 0.01)),
    )
    draw.line(
        [(doc_right - fold, doc_top + fold), (doc_right, doc_top + fold)],
        fill=(188, 167, 145, 255),
        width=max(1, int(size * 0.01)),
    )

    hash_color = (43, 39, 35, 255)
    stem_w = size * 0.045
    bar_h = size * 0.034
    hash_x = doc_left + size * 0.10
    hash_y = doc_top + size * 0.18
    hash_h = size * 0.23
    gap = size * 0.065
    rounding = int(size * 0.018)

    for offset in [0, gap]:
        draw.rounded_rectangle(
            [hash_x + offset, hash_y, hash_x + offset + stem_w, hash_y + hash_h],
            radius=rounding,
            fill=hash_color,
        )
    for offset in [size * 0.055, size * 0.135]:
        draw.rounded_rectangle(
            [hash_x - size * 0.018, hash_y + offset, hash_x + gap + stem_w + size * 0.018, hash_y + offset + bar_h],
            radius=rounding,
            fill=hash_color,
        )

    line_color = (130, 118, 107, 255)
    line_left = doc_left + size * 0.10
    for idx, width_factor in enumerate([0.22, 0.18, 0.20]):
        y = doc_top + size * (0.49 + idx * 0.08)
        draw.rounded_rectangle(
            [line_left, y, line_left + size * width_factor, y + bar_h * 0.8],
            radius=rounding,
            fill=line_color,
        )

    lens_center = (size * 0.70, size * 0.71)
    lens_radius = size * 0.14
    lens_fill = (239, 251, 248, 235)
    lens_stroke = (23, 121, 116, 255)
    handle_color = (20, 86, 84, 255)
    handle_w = max(2, int(size * 0.028))

    draw.ellipse(
        [
            lens_center[0] - lens_radius,
            lens_center[1] - lens_radius,
            lens_center[0] + lens_radius,
            lens_center[1] + lens_radius,
        ],
        fill=lens_fill,
        outline=lens_stroke,
        width=max(2, int(size * 0.018)),
    )
    draw.line(
        [
            (lens_center[0] + lens_radius * 0.62, lens_center[1] + lens_radius * 0.62),
            (lens_center[0] + lens_radius * 1.30, lens_center[1] + lens_radius * 1.30),
        ],
        fill=handle_color,
        width=handle_w,
    )

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.ellipse(
        [
            inset,
            inset,
            size - inset,
            size * 0.54,
        ],
        fill=(255, 255, 255, 34),
    )
    highlight = highlight.filter(ImageFilter.GaussianBlur(radius=max(2, size // 32)))
    image.alpha_composite(highlight)
    return image


def main() -> None:
    APPICONSET.mkdir(parents=True, exist_ok=True)
    for file in APPICONSET.glob("*.png"):
        file.unlink()

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    for size, filename in sizes:
        icon = draw_icon(size)
        icon.save(APPICONSET / filename)


if __name__ == "__main__":
    main()
