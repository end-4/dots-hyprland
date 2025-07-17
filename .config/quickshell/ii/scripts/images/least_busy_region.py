#!/usr/bin/env python3
# Disclaimer: This script was ai-generated and went through minimal revision.

import os
os.environ["OPENCV_LOG_LEVEL"] = "SILENT"
import cv2
import numpy as np
import argparse
import json

def center_crop(img, target_w, target_h):
    h, w = img.shape[:2]
    if w == target_w and h == target_h:
        return img
    x1 = max(0, (w - target_w) // 2)
    y1 = max(0, (h - target_h) // 2)
    x2 = x1 + target_w
    y2 = y1 + target_h
    return img[y1:y2, x1:x2]

def find_least_busy_region(image_path, region_width=300, region_height=200, screen_width=None, screen_height=None, verbose=False, stride=2, screen_mode="fill", horizontal_padding=50, vertical_padding=50):
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
        img = center_crop(img, screen_width, screen_height)
        if verbose:
            print(f"Cropped image to {screen_width}x{screen_height}")
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
    x_start = horizontal_padding
    y_start = vertical_padding
    x_end = w - region_width - horizontal_padding + 1
    y_end = h - region_height - vertical_padding + 1
    for y in range(y_start, max(y_end, y_start+1), stride):
        for x in range(x_start, max(x_end, x_start+1), stride):
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

def find_largest_region(image_path, screen_width=None, screen_height=None, verbose=False, stride=2, screen_mode="fill", threshold=100.0, aspect_ratio=1.0, horizontal_padding=50, vertical_padding=50):
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
        img = center_crop(img, screen_width, screen_height)
        if verbose:
            print(f"Cropped image to {screen_width}x{screen_height}")
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
        x_start = horizontal_padding
        y_start = vertical_padding
        x_end = w - region_w - horizontal_padding + 1
        y_end = h - region_h - vertical_padding + 1
        for y in range(y_start, max(y_end, y_start+1), stride):
            for x in range(x_start, max(x_end, x_start+1), stride):
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
        img = center_crop(img, screen_width, screen_height)
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
        img = center_crop(img, screen_width, screen_height)
    cx, cy = center
    region_w, region_h = size
    x1 = cx - region_w // 2
    y1 = cy - region_h // 2
    x2 = cx + region_w // 2 - 1
    y2 = cy + region_h // 2 - 1
    cv2.rectangle(img, (x1, y1), (x2, y2), (255,0,0), 3)
    cv2.imwrite(output_path, img)
    print(f"Saved output image with largest region at {output_path}")

def get_dominant_color(image_path, x, y, w, h, screen_width=None, screen_height=None, screen_mode="fill"):
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
        img = center_crop(img, screen_width, screen_height)
    # Ensure region is within bounds
    x = max(0, x)
    y = max(0, y)
    w = max(1, min(w, img.shape[1] - x))
    h = max(1, min(h, img.shape[0] - y))
    region = img[y:y+h, x:x+w]
    if region.size == 0 or region.shape[0] == 0 or region.shape[1] == 0:
        return [0, 0, 0]
    region = region.reshape((-1, 3))
    # Filter out black pixels (optional, improves accuracy for some images)
    non_black = region[np.any(region > 10, axis=1)]
    if non_black.shape[0] == 0:
        non_black = region
    region = np.float32(non_black)
    if region.shape[0] < 3:
        return [int(x) for x in np.mean(region, axis=0)]
    # K-means to find dominant color
    criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 10, 1.0)
    K = min(3, region.shape[0])
    _, labels, centers = cv2.kmeans(region, K, None, criteria, 10, cv2.KMEANS_RANDOM_CENTERS)
    counts = np.bincount(labels.flatten())
    dominant = centers[np.argmax(counts)]
    return [int(x) for x in dominant]

def main():
    parser = argparse.ArgumentParser(description="Find least busy region in an image and output a JSON. Made for determining a suitable position for a wallpaper widget.")
    parser.add_argument("image_path", help="Path to the input image")
    parser.add_argument("--width", type=int, default=300, help="Region width")
    parser.add_argument("--height", type=int, default=200, help="Region height")
    parser.add_argument("-v", "--visual-output", action="store_true", help="Output image with rectangle")
    parser.add_argument("--screen-width", type=int, default=1920, help="Screen width for wallpaper scaling")
    parser.add_argument("--screen-height", type=int, default=1080, help="Screen height for wallpaper scaling")
    parser.add_argument("--stride", type=int, default=10, help="Step size for sliding window (higher is faster, less precise)")
    parser.add_argument("--screen-mode", choices=["fill", "fit"], default="fill", help="Wallpaper scaling mode: 'fill' (default) or 'fit'")
    parser.add_argument("--verbose", action="store_true", help="Print verbose output")
    parser.add_argument("-l", "--largest-region", action="store_true", help="Find the largest region under the variance threshold and output its center")
    parser.add_argument("-t", "--variance-threshold", type=float, default=1000.0, help="Variance threshold for largest region mode")
    parser.add_argument("--aspect-ratio", type=float, default=1.78, help="Aspect ratio (width/height) for largest region mode")
    parser.add_argument("--horizontal-padding", "-hp", type=int, default=50, help="Minimum horizontal distance from region to image edge")
    parser.add_argument("--vertical-padding", "-vp", type=int, default=50, help="Minimum vertical distance from region to image edge")
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
            aspect_ratio=args.aspect_ratio,
            horizontal_padding=args.horizontal_padding,
            vertical_padding=args.vertical_padding
        )
        if center:
            if args.visual_output:
                draw_largest_region(args.image_path, center, size, screen_width=args.screen_width, screen_height=args.screen_height, screen_mode=args.screen_mode)
            # Extract dominant color
            cx, cy = center
            region_w, region_h = size
            x1 = cx - region_w // 2
            y1 = cy - region_h // 2
            dominant_color = get_dominant_color(
                args.image_path, x1, y1, region_w, region_h,
                screen_width=args.screen_width, screen_height=args.screen_height, screen_mode=args.screen_mode
            )
            dominant_color_hex = '#{:02x}{:02x}{:02x}'.format(*dominant_color)
            print(json.dumps({
                "center_x": center[0],
                "center_y": center[1],
                "width": size[0],
                "height": size[1],
                "variance": var,
                "dominant_color": dominant_color_hex
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
        screen_mode=args.screen_mode,
        horizontal_padding=args.horizontal_padding,
        vertical_padding=args.vertical_padding
    )
    if args.visual_output:
        draw_region(args.image_path, coords, region_width=args.width, region_height=args.height, screen_width=args.screen_width, screen_height=args.screen_height, screen_mode=args.screen_mode)
    # Output JSON with center point
    center_x = coords[0] + args.width // 2
    center_y = coords[1] + args.height // 2
    dominant_color = get_dominant_color(
        args.image_path, coords[0], coords[1], args.width, args.height,
        screen_width=args.screen_width, screen_height=args.screen_height, screen_mode=args.screen_mode
    )
    dominant_color_hex = '#{:02x}{:02x}{:02x}'.format(*dominant_color)
    print(json.dumps({
        "center_x": center_x,
        "center_y": center_y,
        "width": args.width,
        "height": args.height,
        "variance": variance,
        "dominant_color": dominant_color_hex
    }))

if __name__ == "__main__":
    main()

