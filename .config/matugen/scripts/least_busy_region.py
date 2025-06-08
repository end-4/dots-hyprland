#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
# Disclaimer: This script is vibe-coded.

import os
os.environ["OPENCV_LOG_LEVEL"] = "SILENT"
import cv2
import numpy as np
import argparse
import json

def find_least_busy_region(image_path, region_width=300, region_height=200, screen_width=None, screen_height=None, verbose=False, stride=2, screen_mode="fill"):
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise FileNotFoundError(f"Image not found: {image_path}")
    orig_h, orig_w = img.shape
    scale = 1.0
    if screen_width is not None and screen_height is not None:
        scale_w = screen_width / orig_w
        scale_h = screen_height / orig_h
        if screen_mode == "fill":
            scale = max(scale_w, scale_h)
        else:
            scale = min(scale_w, scale_h)
        new_w = int(orig_w * scale)
        new_h = int(orig_h * scale)
        if verbose:
            print(f"Scaling image from {orig_w}x{orig_h} to {new_w}x{new_h} (scale: {scale:.3f}, mode: {screen_mode})")
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
    else:
        if verbose:
            print(f"Using original image size: {orig_w}x{orig_h}")
    arr = img.astype(np.float64)
    h, w = arr.shape
    # Use OpenCV's integral for fast computation
    integral = cv2.integral(arr, sdepth=cv2.CV_64F)[1:,1:]
    integral_sq = cv2.integral(arr**2, sdepth=cv2.CV_64F)[1:,1:]
    def region_sum(ii, x1, y1, x2, y2):
        total = ii[y2, x2]
        if x1 > 0:
            total -= ii[y2, x1-1]
        if y1 > 0:
            total -= ii[y1-1, x2]
        if x1 > 0 and y1 > 0:
            total += ii[y1-1, x1-1]
        return total
    min_var = None
    min_coords = (0, 0)
    area = region_width * region_height
    for y in range(0, h - region_height + 1, stride):
        for x in range(0, w - region_width + 1, stride):
            x1, y1 = x, y
            x2, y2 = x + region_width - 1, y + region_height - 1
            s = region_sum(integral, x1, y1, x2, y2)
            s2 = region_sum(integral_sq, x1, y1, x2, y2)
            mean = s / area
            var = (s2 / area) - (mean ** 2)
            if (min_var is None) or (var < min_var):
                min_var = var
                min_coords = (x, y)
    return min_coords, min_var

def find_largest_region(image_path, screen_width=None, screen_height=None, verbose=False, stride=2, screen_mode="fill", threshold=100.0, aspect_ratio=1.0):
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise FileNotFoundError(f"Image not found: {image_path}")
    orig_h, orig_w = img.shape
    scale = 1.0
    if screen_width is not None and screen_height is not None:
        scale_w = screen_width / orig_w
        scale_h = screen_height / orig_h
        if screen_mode == "fill":
            scale = max(scale_w, scale_h)
        else:
            scale = min(scale_w, scale_h)
        new_w = int(orig_w * scale)
        new_h = int(orig_h * scale)
        if verbose:
            print(f"Scaling image from {orig_w}x{orig_h} to {new_w}x{new_h} (scale: {scale:.3f}, mode: {screen_mode})")
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
    else:
        if verbose:
            print(f"Using original image size: {orig_w}x{orig_h}")
    arr = img.astype(np.float64)
    h, w = arr.shape
    # Use OpenCV's integral for fast computation
    integral = cv2.integral(arr, sdepth=cv2.CV_64F)[1:,1:]
    integral_sq = cv2.integral(arr**2, sdepth=cv2.CV_64F)[1:,1:]
    def region_sum(ii, x1, y1, x2, y2):
        total = ii[y2, x2]
        if x1 > 0:
            total -= ii[y2, x1-1]
        if y1 > 0:
            total -= ii[y1-1, x2]
        if x1 > 0 and y1 > 0:
            total += ii[y1-1, x1-1]
        return total
    min_size = 10
    max_size = min(h, int(w / aspect_ratio)) if aspect_ratio >= 1.0 else min(int(h * aspect_ratio), w)
    best = None
    best_size = min_size
    while min_size <= max_size:
        mid = (min_size + max_size) // 2
        if aspect_ratio >= 1.0:
            region_h = mid
            region_w = int(mid * aspect_ratio)
        else:
            region_w = mid
            region_h = int(mid / aspect_ratio)
        if region_w > w or region_h > h:
            max_size = mid - 1
            continue
        found = False
        for y in range(0, h - region_h + 1, stride):
            for x in range(0, w - region_w + 1, stride):
                x1, y1 = x, y
                x2, y2 = x + region_w - 1, y + region_h - 1
                s = region_sum(integral, x1, y1, x2, y2)
                s2 = region_sum(integral_sq, x1, y1, x2, y2)
                area = region_w * region_h
                mean = s / area
                var = (s2 / area) - (mean ** 2)
                if var <= threshold:
                    found = True
                    best = (x, y, region_w, region_h, var)
                    break
            if found:
                break
        if found:
            best_size = mid
            min_size = mid + 1
        else:
            max_size = mid - 1
    if best:
        x, y, region_w, region_h, var = best
        center_x = x + region_w // 2
        center_y = y + region_h // 2
        return (center_x, center_y), (region_w, region_h), var
    else:
        return None, (0, 0), None

def draw_region(image_path, coords, region_width=300, region_height=200, output_path='output.png', screen_width=None, screen_height=None, screen_mode="fill"):
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Image not found: {image_path}")
    orig_h, orig_w = img.shape[:2]
    if screen_width is not None and screen_height is not None:
        scale_w = screen_width / orig_w
        scale_h = screen_height / orig_h
        if screen_mode == "fill":
            scale = max(scale_w, scale_h)
        else:
            scale = min(scale_w, scale_h)
        new_w = int(orig_w * scale)
        new_h = int(orig_h * scale)
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
    x, y = coords
    cv2.rectangle(img, (x, y), (x+region_width-1, y+region_height-1), (0,0,255), 3)
    cv2.imwrite(output_path, img)
    print(f"Saved output image with rectangle at {output_path}")

def draw_largest_region(image_path, center, size, output_path='output.png', screen_width=None, screen_height=None, screen_mode="fill"):
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Image not found: {image_path}")
    orig_h, orig_w = img.shape[:2]
    if screen_width is not None and screen_height is not None:
        scale_w = screen_width / orig_w
        scale_h = screen_height / orig_h
        if screen_mode == "fill":
            scale = max(scale_w, scale_h)
        else:
            scale = min(scale_w, scale_h)
        new_w = int(orig_w * scale)
        new_h = int(orig_h * scale)
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
    cx, cy = center
    region_w, region_h = size
    x1 = cx - region_w // 2
    y1 = cy - region_h // 2
    x2 = cx + region_w // 2 - 1
    y2 = cy + region_h // 2 - 1
    cv2.rectangle(img, (x1, y1), (x2, y2), (255,0,0), 3)
    cv2.imwrite(output_path, img)
    print(f"Saved output image with largest region at {output_path}")

def main():
    parser = argparse.ArgumentParser(description="Find least busy region in an image and output a JSON. Made for determining a suitable position for a wallpaper widget.")
    parser.add_argument("image_path", help="Path to the input image")
    parser.add_argument("--width", type=int, default=500, help="Region width")
    parser.add_argument("--height", type=int, default=250, help="Region height")
    parser.add_argument("-v", "--visual-output", action="store_true", help="Output image with rectangle")
    parser.add_argument("--screen-width", type=int, default=1920, help="Screen width for wallpaper scaling")
    parser.add_argument("--screen-height", type=int, default=1080, help="Screen height for wallpaper scaling")
    parser.add_argument("--stride", type=int, default=4, help="Step size for sliding window (higher is faster, less precise)")
    parser.add_argument("--screen-mode", choices=["fill", "fit"], default="fill", help="Wallpaper scaling mode: 'fill' (default) or 'fit'")
    parser.add_argument("--verbose", action="store_true", help="Print verbose output")
    parser.add_argument("-l", "--largest-region", action="store_true", help="Find the largest region under the variance threshold and output its center")
    parser.add_argument("-t", "--variance-threshold", type=float, default=1000.0, help="Variance threshold for largest region mode")
    parser.add_argument("--aspect-ratio", type=float, default=1.0, help="Aspect ratio (width/height) for largest region mode")
    args = parser.parse_args()

    if args.largest_region:
        center, size, var = find_largest_region(
            args.image_path,
            screen_width=args.screen_width,
            screen_height=args.screen_height,
            verbose=args.verbose,
            stride=args.stride,
            screen_mode=args.screen_mode,
            threshold=args.variance_threshold,
            aspect_ratio=args.aspect_ratio
        )
        if center:
            if args.visual_output:
                draw_largest_region(args.image_path, center, size, screen_width=args.screen_width, screen_height=args.screen_height, screen_mode=args.screen_mode)
            # Output JSON
            print(json.dumps({
                "center_x": center[0],
                "center_y": center[1],
                "width": size[0],
                "height": size[1],
                "variance": var
            }))
        else:
            print(json.dumps({"error": "No region found under the threshold."}))
        return

    coords, variance = find_least_busy_region(
        args.image_path,
        region_width=args.width,
        region_height=args.height,
        screen_width=args.screen_width,
        screen_height=args.screen_height,
        verbose=args.verbose,
        stride=args.stride,
        screen_mode=args.screen_mode
    )
    if args.visual_output:
        draw_region(args.image_path, coords, region_width=args.width, region_height=args.height, screen_width=args.screen_width, screen_height=args.screen_height, screen_mode=args.screen_mode)
    # Output JSON with center point
    center_x = coords[0] + args.width // 2
    center_y = coords[1] + args.height // 2
    print(json.dumps({
        "center_x": center_x,
        "center_y": center_y,
        "width": args.width,
        "height": args.height,
        "variance": variance
    }))

if __name__ == "__main__":
    main()

