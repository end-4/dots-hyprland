#!/usr/bin/env python3

import argparse
import cv2
import json
import numpy as np
import sys

DEFAULT_IMAGE_PATH = '/tmp/quickshell/media/screenshot/image'

def iou(boxA, boxB):
    # Compute intersection over union for two boxes
    xA = max(boxA['x'], boxB['x'])
    yA = max(boxA['y'], boxB['y'])
    xB = min(boxA['x'] + boxA['width'], boxB['x'] + boxB['width'])
    yB = min(boxA['y'] + boxA['height'], boxB['y'] + boxB['height'])
    interW = max(0, xB - xA)
    interH = max(0, yB - yA)
    interArea = interW * interH
    boxAArea = boxA['width'] * boxA['height']
    boxBArea = boxB['width'] * boxB['height']
    iou = interArea / float(boxAArea + boxBArea - interArea) if (boxAArea + boxBArea - interArea) > 0 else 0
    return iou

def non_max_suppression(regions, iou_threshold=0.7):
    # Sort by area (largest first)
    regions = sorted(regions, key=lambda r: r['width'] * r['height'], reverse=True)
    keep = []
    while regions:
        current = regions.pop(0)
        keep.append(current)
        regions = [r for r in regions if iou(current, r) < iou_threshold]
    return keep

def find_regions(image_path, min_width, min_height, max_width=None, max_height=None, quality=False, k=150, min_size=20, sigma=0.8, resize_factor=1.0):
    image = cv2.imread(image_path)
    if image is None:
        print(f'Error: Could not load image {image_path}', file=sys.stderr)
        sys.exit(1)
    orig_h, orig_w = image.shape[:2]
    if resize_factor != 1.0:
        image = cv2.resize(image, (int(orig_w * resize_factor), int(orig_h * resize_factor)), interpolation=cv2.INTER_AREA)
    ss = cv2.ximgproc.segmentation.createSelectiveSearchSegmentation()
    ss.setBaseImage(image)
    if quality:
        ss.switchToSelectiveSearchQuality(k, min_size, sigma)
    else:
        ss.switchToSelectiveSearchFast(k, min_size, sigma)
    rects = ss.process()
    regions = []
    for (x, y, w, h) in rects:
        # Scale regions back to original image size if resized
        if resize_factor != 1.0:
            x = int(x / resize_factor)
            y = int(y / resize_factor)
            w = int(w / resize_factor)
            h = int(h / resize_factor)
        # Filter out region that is exactly the same size as the original image
        if w == orig_w and h == orig_h and x == 0 and y == 0:
            continue
        if w > min_width and h > min_height:
            if (max_width is None or w < max_width) and (max_height is None or h < max_height):
                regions.append({'x': int(x), 'y': int(y), 'width': int(w), 'height': int(h)})
    # Remove duplicates/overlaps
    regions = non_max_suppression(regions, iou_threshold=0.7)
    return regions, cv2.imread(image_path)  # Return original image for drawing

def draw_regions(image, regions, output_path):
    for region in regions:
        if 'x' in region:
            x, y, w, h = region['x'], region['y'], region['width'], region['height']
        elif 'at' in region and 'size' in region:
            x, y = region['at']
            w, h = region['size']
        else:
            continue
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 0, 255), 2)
    cv2.imwrite(output_path, image)

def main():
    parser = argparse.ArgumentParser(description='Find regions of interest in an image using selective search.')
    parser.add_argument('-i', '--image', default=DEFAULT_IMAGE_PATH, help='Path to input image')
    parser.add_argument('-do', '--debug-output', help='Path to save debug image with rectangles')
    parser.add_argument('--min-width', type=int, default=200, help='Minimum width of detected region')
    parser.add_argument('--min-height', type=int, default=100, help='Minimum height of detected region')
    parser.add_argument('--max-width', type=int, help='Maximum width of detected region')
    parser.add_argument('--max-height', type=int, help='Maximum height of detected region')
    parser.add_argument('--single', action='store_true', help='Only output the most likely (largest) region')
    parser.add_argument('--quality', action='store_true', help='Use quality mode for selective search (slower, less sensitive)')
    parser.add_argument('--k', type=int, default=3000, help='Segmentation parameter k (default: 150)')
    parser.add_argument('--min-size', type=int, default=50, help='Segmentation parameter min_size (default: 20)')
    parser.add_argument('--sigma', type=float, default=0.6, help='Segmentation parameter sigma (default: 0.8)')
    parser.add_argument('--resize-factor', type=float, default=0.1, help='Resize factor for input image before processing (default: 1.0, e.g. 0.5 for half size)')
    parser.add_argument('--hyprctl', action='store_true', help='Mimics hyprctl\'s window output, like {"at": [x, y], "size": [w, h]}')
    args = parser.parse_args()

    regions, image = find_regions(
        args.image,
        min_width=args.min_width,
        min_height=args.min_height,
        max_width=args.max_width,
        max_height=args.max_height,
        quality=args.quality,
        k=args.k,
        min_size=args.min_size,
        sigma=args.sigma,
        resize_factor=args.resize_factor
    )
    if args.single and regions:
        largest = max(regions, key=lambda r: r['width'] * r['height'])
        regions = [largest]
    if args.hyprctl:
        regions = [{"at": [r['x'], r['y']], "size": [r['width'], r['height']]} for r in regions]
    print(json.dumps(regions))
    if args.debug_output:
        draw_regions(image, regions, args.debug_output)

if __name__ == '__main__':
    main()

