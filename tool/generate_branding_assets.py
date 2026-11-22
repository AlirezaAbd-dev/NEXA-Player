import math
from PIL import Image, ImageDraw, ImageFilter

def create_branding_assets():
    size = 1024
    center = size / 2

    # 1. Master Icon (with obsidian background)
    img = Image.new("RGBA", (size, size), (10, 13, 20, 255))
    draw = ImageDraw.Draw(img)

    # Ambient back-glow
    glow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)

    # Cyan radial glow (left)
    for r in range(380, 0, -10):
        alpha = int(45 * (1 - r / 380))
        glow_draw.ellipse(
            (center - 180 - r, center - r, center - 180 + r, center + r),
            fill=(0, 229, 255, alpha)
        )

    # Magenta/Orchid radial glow (right)
    for r in range(380, 0, -10):
        alpha = int(50 * (1 - r / 380))
        glow_draw.ellipse(
            (center + 180 - r, center - r, center + 180 + r, center + r),
            fill=(217, 70, 239, alpha)
        )

    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(30))
    img.alpha_composite(glow_layer)

    # Circular obsidian vinyl card disc
    disc_radius = 450
    disc_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    disc_draw = ImageDraw.Draw(disc_layer)

    # Multi-stop dark gradient disc
    for r in range(disc_radius, 0, -2):
        t = r / disc_radius
        # Radial gradient from dark navy/slate (#161b26) at rim to amoled black (#0c0f17) at center
        r_col = int(22 * t + 12 * (1 - t))
        g_col = int(27 * t + 15 * (1 - t))
        b_col = int(38 * t + 23 * (1 - t))
        disc_draw.ellipse(
            (center - r, center - r, center + r, center + r),
            fill=(r_col, g_col, b_col, 255)
        )

    # Specular rim
    for i in range(4):
        alpha = int(140 - i * 30)
        disc_draw.ellipse(
            (center - disc_radius + i, center - disc_radius + i,
             center + disc_radius - i, center + disc_radius - i),
            outline=(0, 229, 255, alpha),
            width=2
        )

    # Inner groove ring
    inner_groove = 320
    disc_draw.ellipse(
        (center - inner_groove, center - inner_groove,
         center + inner_groove, center + inner_groove),
        outline=(255, 255, 255, 18),
        width=2
    )

    img.alpha_composite(disc_layer)

    # Center Logo Motif (Foreground)
    def render_foreground(canvas_size=1024, padding_ratio=0.55):
        fg = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        fg_glow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        fg_draw = ImageDraw.Draw(fg)
        glow_draw = ImageDraw.Draw(fg_glow)

        scale = canvas_size / 1024.0 * padding_ratio
        cx = canvas_size / 2
        cy = canvas_size / 2

        # NEXA "N" + Play Glyph points
        # Left stem: (cx - 160*scale, cy - 240*scale) to (cx - 160*scale, cy + 240*scale)
        # Play apex: (cx + 180*scale, cy)
        # Right stem: (cx + 160*scale, cy - 240*scale) to (cx + 160*scale, cy + 240*scale)

        # Draw intense neon glow first
        left_x = cx - 150 * scale
        right_x = cx + 150 * scale
        top_y = cy - 220 * scale
        bot_y = cy + 220 * scale
        stem_w = int(58 * scale)

        # 1. Left stem glow (Cyan)
        glow_draw.rounded_rectangle(
            (left_x - stem_w/2, top_y, left_x + stem_w/2, bot_y),
            radius=stem_w/2,
            fill=(0, 229, 255, 120)
        )

        # 2. Diagonal / Play chevron glow (Cyan -> Orchid gradient)
        glow_draw.line(
            [(left_x, top_y + 40*scale), (cx + 90*scale, cy), (right_x, bot_y - 40*scale)],
            fill=(140, 120, 255, 140),
            width=int(64 * scale),
            joint="round"
        )

        # 3. Right stem glow (Orchid)
        glow_draw.rounded_rectangle(
            (right_x - stem_w/2, top_y, right_x + stem_w/2, bot_y),
            radius=stem_w/2,
            fill=(217, 70, 239, 120)
        )

        # 4. Play button triangle in center
        play_poly = [
            (cx - 30 * scale, cy - 80 * scale),
            (cx + 85 * scale, cy),
            (cx - 30 * scale, cy + 80 * scale)
        ]
        glow_draw.polygon(play_poly, fill=(255, 255, 255, 150))

        fg_glow = fg_glow.filter(ImageFilter.GaussianBlur(int(24 * scale)))
        fg.alpha_composite(fg_glow)

        # Now draw sharp crisp foreground vectors
        # Left Stem (Cyan Gradient)
        steps = int(bot_y - top_y)
        for i in range(steps):
            y = top_y + i
            t = i / steps
            r = int(0 * (1 - t) + 0 * t)
            g = int(229 * (1 - t) + 176 * t)
            b = int(255)
            w = stem_w / 2
            # Handle pill rounded caps
            if i < w:
                dx = math.sqrt(w*w - (w - i)*(w - i))
            elif i > steps - w:
                dy = i - (steps - w)
                dx = math.sqrt(w*w - dy*dy)
            else:
                dx = w
            fg_draw.line([(left_x - dx, y), (left_x + dx, y)], fill=(r, g, b, 255), width=2)

        # Right Stem (Electric Orchid Gradient)
        for i in range(steps):
            y = top_y + i
            t = i / steps
            r = int(217 * (1 - t) + 255 * t)
            g = int(70 * (1 - t) + 64 * t)
            b = int(239 * (1 - t) + 129 * t)
            w = stem_w / 2
            if i < w:
                dx = math.sqrt(w*w - (w - i)*(w - i))
            elif i > steps - w:
                dy = i - (steps - w)
                dx = math.sqrt(w*w - dy*dy)
            else:
                dx = w
            fg_draw.line([(right_x - dx, y), (right_x + dx, y)], fill=(r, g, b, 255), width=2)

        # Sharp Dynamic Diagonal
        fg_draw.line(
            [(left_x, top_y + 35*scale), (cx + 80*scale, cy), (right_x, bot_y - 35*scale)],
            fill=(180, 140, 255, 255),
            width=int(46 * scale),
            joint="round"
        )

        # Crisp Play Glyph
        fg_draw.polygon(play_poly, fill=(255, 255, 255, 245))

        # Specular glint on play triangle
        fg_draw.line(
            [(cx - 26 * scale, cy - 70 * scale), (cx + 70 * scale, cy)],
            fill=(255, 255, 255, 200),
            width=int(6 * scale)
        )

        return fg

    # Composite sharp foreground onto master icon
    fg_master = render_foreground(1024, padding_ratio=1.0)
    img.alpha_composite(fg_master)

    # Save 1: Master Icon
    img.save("assets/branding/app_icon.png", format="PNG")
    print("Saved assets/branding/app_icon.png (1024x1024)")

    # Save 2: Adaptive Foreground (70% padding for circle/squircle masks)
    adaptive_fg = render_foreground(1024, padding_ratio=0.68)
    adaptive_fg.save("assets/branding/app_icon_foreground.png", format="PNG")
    print("Saved assets/branding/app_icon_foreground.png (1024x1024)")

    # Save 3: Splash Logo (Clean centered emblem)
    splash = render_foreground(512, padding_ratio=0.85)
    splash.save("assets/branding/splash_logo.png", format="PNG")
    print("Saved assets/branding/splash_logo.png (512x512)")

if __name__ == "__main__":
    create_branding_assets()
