# Encoder/Decoder Module

This module provides URL and Base64 encoding/decoding functionality in the left sidebar.

## Features

### URL Encoder/Decoder
- Encode plain text to URL-encoded format using `encodeURIComponent`
- Decode URL-encoded text back to plain text using `decodeURIComponent`
- Useful for encoding URLs, query parameters, and special characters

### Base64 Encoder/Decoder
- Encode plain text to Base64 format using Qt.btoa()
- Decode Base64 text back to plain text using Qt.atob()
- Useful for encoding binary data, API tokens, and more

## Usage

1. Open the left sidebar
2. Navigate to the "Encoder" tab (icon: data_object)
3. Switch between URL and Base64 tabs
4. Select "Encode" or "Decode" mode
5. Enter your text in the input field
6. The result will appear automatically in the output field
7. Use the copy button to copy the result to clipboard

## Files

- `EncoderDecoder.qml` - Main component with tab switching
- `UrlEncoder.qml` - URL encoding/decoding component
- `Base64Encoder.qml` - Base64 encoding/decoding component
- `EncodingCanvas.qml` - Reusable UI component for text input/output

## Configuration

The encoder/decoder is always enabled by default. No configuration is required.
