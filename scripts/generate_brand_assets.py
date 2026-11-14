import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

assets_dir = "WaveMix/Resources/Assets.xcassets"

# Brand Palette
MIDNIGHT_BLACK = (11, 11, 18)       # #0B0B12
DEEP_PURPLE = (108, 66, 217)        # #6C42D9
ELECTRIC_BLUE = (49, 139, 255)      # #318BFF
NEON_CYAN = (66, 232, 216)          # #42E8D8
ACCENT_PINK = (214, 109, 255)       # #D66DFF

def lerp_color(c1, c2, t):
    return (
        int(c1[0] + (c2[0] - c1[0]) * t),
        int(c1[1] + (c2[1] - c1[1]) * t),
        int(c1[2] + (c2[2] - c1[2]) * t)
    )

def get_gradient_color(t):
    # Gradient: DEEP_PURPLE -> ELECTRIC_BLUE -> NEON_CYAN -> ACCENT_PINK
    if t < 0.33:
        return lerp_color(DEEP_PURPLE, ELECTRIC_BLUE, t / 0.33)
    elif t < 0.66:
        return lerp_color(ELECTRIC_BLUE, NEON_CYAN, (t - 0.33) / 0.33)
    else:
        return lerp_color(NEON_CYAN, ACCENT_PINK, (t - 0.66) / 0.34)

def draw_wavemix_w(draw, center_x, center_y, width, height, glow=False):
    """
    Draws the stylized 'W' composed of soundwave equalizer pillars with rounded caps.
    W shape has 5 main vertices / bars:
    Left high -> mid-left valley -> center peak -> mid-right valley -> right high.
    Plus equalizer wave bands spanning across.
    """
    half_w = width / 2
    half_h = height / 2

    # Coordinates for the 5 vertical/curved soundwave columns forming 'W'
    # Col 0: x = -0.45 * width, top = -0.45 * height, bot = 0.40 * height
    # Col 1: x = -0.22 * width, top = -0.10 * height, bot = 0.45 * height
    # Col 2: x =  0.00 * width, top = -0.38 * height, bot = 0.20 * height
    # Col 3: x =  0.22 * width, top = -0.10 * height, bot = 0.45 * height
    # Col 4: x =  0.45 * width, top = -0.45 * height, bot = 0.40 * height

    # 7 bars for high fidelity soundwave W
    bar_configs = [
        (-0.45, -0.42, 0.30, 0.0),   # Far left
        (-0.30, -0.25, 0.45, 0.18),  # Left descent
        (-0.15, -0.05, 0.48, 0.35),  # Left valley
        ( 0.00, -0.45, 0.25, 0.50),  # Center crest
        ( 0.15, -0.05, 0.48, 0.65),  # Right valley
        ( 0.30, -0.25, 0.45, 0.82),  # Right ascent
        ( 0.45, -0.42, 0.30, 1.0)    # Far right
    ]

    bar_w = width * 0.09
    radius = bar_w / 2

    for (rel_x, top_y, bot_y, t) in bar_configs:
        x = center_x + rel_x * width
        y1 = center_y + top_y * height
        y2 = center_y + bot_y * height
        col = get_gradient_color(t)

        # Draw rounded bar
        draw.rounded_rectangle(
            [x - radius, y1, x + radius, y2],
            radius=radius,
            fill=col
        )

def generate_app_icon():
    size = 1024
    img = Image.new("RGBA", (size, size), MIDNIGHT_BLACK + (255,))
    
    # 1. Subtle radial background aura
    glow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)
    for r in range(400, 50, -10):
        alpha = int(45 * (1 - r / 400))
        t = r / 400
        col = lerp_color(DEEP_PURPLE, ELECTRIC_BLUE, t) + (alpha,)
        glow_draw.ellipse([512 - r, 512 - r, 512 + r, 512 + r], fill=col)
    glow_img = glow_img.filter(ImageFilter.GaussianBlur(30))
    img.paste(glow_img, (0, 0), glow_img)

    # 2. Outer soundwave rings
    ring_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ring_draw = ImageDraw.Draw(ring_img)
    for r_outer in [460, 480]:
        ring_draw.ellipse(
            [512 - r_outer, 512 - r_outer, 512 + r_outer, 512 + r_outer],
            outline=DEEP_PURPLE + (60,),
            width=2
        )
    img.paste(ring_img, (0, 0), ring_img)

    # 3. Stylized 'W' with glow
    w_glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_w_glow = ImageDraw.Draw(w_glow)
    draw_wavemix_w(draw_w_glow, 512, 512, 600, 500)
    w_glow_blurred = w_glow.filter(ImageFilter.GaussianBlur(25))
    img.paste(w_glow_blurred, (0, 0), w_glow_blurred)

    # Sharp Foreground W
    w_sharp = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_w_sharp = ImageDraw.Draw(w_sharp)
    draw_wavemix_w(draw_w_sharp, 512, 512, 600, 500)
    img.paste(w_sharp, (0, 0), w_sharp)

    # Convert to RGB (No alpha for App Store requirement)
    final_icon = Image.new("RGB", (size, size), MIDNIGHT_BLACK)
    final_icon.paste(img, (0, 0), img)

    out_dir = os.path.join(assets_dir, "AppIcon.appiconset")
    os.makedirs(out_dir, exist_ok=True)
    icon_path = os.path.join(out_dir, "AppIcon_1024.png")
    final_icon.save(icon_path, "PNG")

    # Update Contents.json for AppIcon
    contents_json = {
        "images": [
            {
                "filename": "AppIcon_1024.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            }
        ],
        "info": {"author": "xcode", "version": 1}
    }
    import json
    with open(os.path.join(out_dir, "Contents.json"), "w") as f:
        json.dump(contents_json, f, indent=2)

    print(f"Generated AppIcon: {icon_path}")

def generate_image_asset(name, size, draw_func):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_func(img, draw, size[0], size[1])

    asset_dir = os.path.join(assets_dir, f"{name}.imageset")
    os.makedirs(asset_dir, exist_ok=True)
    file_path = os.path.join(asset_dir, f"{name}.png")
    img.save(file_path, "PNG")

    import json
    contents_json = {
        "images": [
            {
                "filename": f"{name}.png",
                "idiom": "universal",
                "scale": "1x"
            }
        ],
        "info": {"author": "xcode", "version": 1}
    }
    with open(os.path.join(asset_dir, "Contents.json"), "w") as f:
        json.dump(contents_json, f, indent=2)
    print(f"Generated Asset {name}: {file_path}")

def draw_symbol(img, draw, w, h):
    # W symbol with gentle neon aura
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d_glow = ImageDraw.Draw(glow)
    draw_wavemix_w(d_glow, w/2, h/2, w*0.75, h*0.65)
    glow = glow.filter(ImageFilter.GaussianBlur(15))
    img.paste(glow, (0, 0), glow)

    draw_wavemix_w(draw, w/2, h/2, w*0.75, h*0.65)

def draw_splash(img, draw, w, h):
    # Centered glowing splash icon
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d_glow = ImageDraw.Draw(glow)
    draw_wavemix_w(d_glow, w/2, h*0.45, w*0.6, h*0.4)
    glow = glow.filter(ImageFilter.GaussianBlur(25))
    img.paste(glow, (0, 0), glow)

    draw_wavemix_w(draw, w/2, h*0.45, w*0.6, h*0.4)

def draw_logo_dark(img, draw, w, h):
    # Symbol on left, WAVEMIX text on right for dark backgrounds
    symbol_w = h * 0.8
    draw_wavemix_w(draw, h * 0.5, h * 0.5, symbol_w, h * 0.7)

    # Fallback draw stylized wordmark text if font not loaded
    # Modern sans font or manual drawing of WAVEMIX
    try:
        font = ImageFont.truetype("arial.ttf", int(h * 0.45))
        draw.text((h * 1.1, h * 0.25), "WAVEMIX", fill=(255, 255, 255, 245), font=font)
    except:
        draw.text((h * 1.1, h * 0.25), "WAVEMIX", fill=(255, 255, 255, 245))

def draw_logo_light(img, draw, w, h):
    # Symbol on left, WAVEMIX text on right for light backgrounds
    symbol_w = h * 0.8
    draw_wavemix_w(draw, h * 0.5, h * 0.5, symbol_w, h * 0.7)
    try:
        font = ImageFont.truetype("arial.ttf", int(h * 0.45))
        draw.text((h * 1.1, h * 0.25), "WAVEMIX", fill=(11, 11, 18, 245), font=font)
    except:
        draw.text((h * 1.1, h * 0.25), "WAVEMIX", fill=(11, 11, 18, 245))

def draw_wordmark(img, draw, w, h):
    try:
        font = ImageFont.truetype("arial.ttf", int(h * 0.6))
        draw.text((20, h * 0.15), "WAVEMIX", fill=(255, 255, 255, 255), font=font)
    except:
        draw.text((20, h * 0.15), "WAVEMIX", fill=(255, 255, 255, 255))

if __name__ == "__main__":
    generate_app_icon()
    generate_image_asset("WaveMix_Symbol", (512, 512), draw_symbol)
    generate_image_asset("WaveMix_Splash_Logo", (600, 600), draw_splash)
    generate_image_asset("WaveMix_Logo_Dark", (800, 240), draw_logo_dark)
    generate_image_asset("WaveMix_Logo_Light", (800, 240), draw_logo_light)
    generate_image_asset("WaveMix_Wordmark", (600, 160), draw_wordmark)
    print("All Brand Identity Assets generated successfully.")
