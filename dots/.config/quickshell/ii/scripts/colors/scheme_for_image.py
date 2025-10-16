#!/usr/bin/env python3
import sys
import cv2
import numpy as np

# Allowed scheme types
SCHEMES = [
    "scheme-content",
    "scheme-expressive",
    "scheme-fidelity",
    "scheme-fruit-salad",
    "scheme-monochrome",
    "scheme-neutral",
    "scheme-rainbow",
    "scheme-tonal-spot"
]

def image_colorfulness(image):
    # Based on Hasler and Süsstrunk's colorfulness metric
    (B, G, R) = cv2.split(image.astype("float"))
    rg = np.absolute(R - G)
    yb = np.absolute(0.5 * (R + G) - B)
    std_rg = np.std(rg)
    std_yb = np.std(yb)
    mean_rg = np.mean(rg)
    mean_yb = np.mean(yb)
    colorfulness = np.sqrt(std_rg ** 2 + std_yb ** 2) + (0.3 * np.sqrt(mean_rg ** 2 + mean_yb ** 2))
    return colorfulness

# scheme-content respects the image's colors very well, but it might
# look too saturated, so we only use it for not very colorful images to be safe
def pick_scheme(colorfulness):
    if colorfulness < 10:
        # return "scheme-monochrome"
        return "scheme-content"
    elif colorfulness < 20:
        return "scheme-content"
    elif colorfulness < 50:
        return "scheme-neutral"
    else:
        return "scheme-tonal-spot"

def main():
    colorfulness_mode = False
    args = sys.argv[1:]
    if '--colorfulness' in args:
        colorfulness_mode = True
        args.remove('--colorfulness')
    if len(args) < 1:
        print("scheme-tonal-spot")
        sys.exit(1)
    img_path = args[0]
    img = cv2.imread(img_path)
    if img is None:
        print("scheme-tonal-spot")
        sys.exit(1)
    colorfulness = image_colorfulness(img)
    if colorfulness_mode:
        print(f"{colorfulness}")
    else:
        scheme = pick_scheme(colorfulness)
        print(scheme)

if __name__ == "__main__":
    main()
