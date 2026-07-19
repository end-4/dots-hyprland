#!/usr/bin/env python3
# Disclaimer: This script was ai-generated and went through minimal revision.

import cv2
import numpy as np
import json
import sys

def to_hex(color):
    return "#{:02x}{:02x}{:02x}".format(int(color[0]), int(color[1]), int(color[2]))

def get_color_from_stdin():
    # Read raw bytes from stdin
    input_data = sys.stdin.buffer.read()
    if not input_data:
        return {"error": "No data received via stdin"}

    # Convert bytes to numpy array and decode to image
    nparr = np.frombuffer(input_data, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if img is None:
        return {"error": "Could not decode image data"}
    
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    h, w, _ = img_rgb.shape

    # 1. Sample corner pixels (The background anchors)
    corners = np.array([
        img_rgb[0, 0],
        img_rgb[0, w-1],
        img_rgb[h-1, 0],
        img_rgb[h-1, w-1]
    ])

    # 2. Determine single dominant background
    # Using median handles noise/gradients better than a simple average
    bg_color = np.median(corners, axis=0).astype(int)

    # 3. Find the Text Color
    pixels = img_rgb.reshape(-1, 3).astype(int)
    distances = np.linalg.norm(pixels - bg_color, axis=1)
    
    # Take the 95th percentile of pixels furthest from background
    threshold = np.percentile(distances, 95)
    text_pixels = pixels[distances >= threshold]
    
    if len(text_pixels) == 0:
        text_color = [255, 255, 255] # Fallback
    else:
        text_color = np.median(text_pixels, axis=0).astype(int)

    return {
        "background": to_hex(bg_color),
        "text": to_hex(text_color)
    }

if __name__ == "__main__":
    result = get_color_from_stdin()
    print(json.dumps(result))