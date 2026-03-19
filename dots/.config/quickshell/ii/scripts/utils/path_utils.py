"""
Path validation utilities to prevent path traversal attacks.
Used by Quickshell scripts that accept file paths from command-line arguments.
"""

import os
from pathlib import Path
from typing import Optional, List


def validate_path(
    path: str,
    allowed_dirs: Optional[List[str]] = None,
    must_exist: bool = False,
    allow_relative: bool = True
) -> str:
    """
    Validate and resolve a file path to prevent path traversal attacks.
    
    Args:
        path: The input path to validate
        allowed_dirs: Optional list of allowed parent directories. If provided,
                      the resolved path must be within one of these directories.
        must_exist: If True, raises ValueError if path doesn't exist
        allow_relative: If True, resolves relative paths; if False, requires absolute paths
    
    Returns:
        The resolved absolute path as a string
        
    Raises:
        ValueError: If the path fails validation
    """
    if not path:
        raise ValueError("Path cannot be empty")
    
    # Expand environment variables and user home directory
    expanded = os.path.expandvars(os.path.expanduser(path))
    
    # Resolve to absolute path (handles .. and symlinks)
    try:
        resolved = Path(expanded).resolve()
    except (OSError, RuntimeError) as e:
        raise ValueError(f"Invalid path: {e}")
    
    resolved_str = str(resolved)
    
    # Check for null bytes (common attack vector)
    if '\x00' in path or '\x00' in resolved_str:
        raise ValueError("Path contains null bytes")
    
    # Check existence if required
    if must_exist and not resolved.exists():
        raise ValueError(f"Path does not exist: {resolved_str}")
    
    # Validate against allowed directories if specified
    if allowed_dirs:
        allowed = False
        for allowed_dir in allowed_dirs:
            allowed_resolved = Path(os.path.expandvars(os.path.expanduser(allowed_dir))).resolve()
            try:
                resolved.relative_to(allowed_resolved)
                allowed = True
                break
            except ValueError:
                continue
        
        if not allowed:
            raise ValueError(
                f"Path {resolved_str} is not within allowed directories: {allowed_dirs}"
            )
    
    return resolved_str


def validate_file_path(
    path: str,
    allowed_extensions: Optional[List[str]] = None,
    must_exist: bool = False
) -> str:
    """
    Validate a file path with optional extension checking.
    
    Args:
        path: The input file path to validate
        allowed_extensions: Optional list of allowed file extensions (e.g., ['.json', '.png'])
        must_exist: If True, raises ValueError if file doesn't exist
    
    Returns:
        The resolved absolute path as a string
        
    Raises:
        ValueError: If the path fails validation
    """
    resolved = validate_path(path, must_exist=must_exist)
    
    if allowed_extensions:
        ext = Path(resolved).suffix.lower()
        allowed_lower = [e.lower() for e in allowed_extensions]
        if ext not in allowed_lower:
            raise ValueError(
                f"File extension '{ext}' not allowed. Allowed: {allowed_extensions}"
            )
    
    return resolved


def safe_join(base_dir: str, *parts: str) -> str:
    """
    Safely join path components, preventing directory traversal.
    
    Args:
        base_dir: The base directory
        *parts: Path components to join
    
    Returns:
        The resolved absolute path as a string
        
    Raises:
        ValueError: If the resulting path escapes base_dir
    """
    base = Path(os.path.expandvars(os.path.expanduser(base_dir))).resolve()
    
    # Join parts and resolve
    joined = base.joinpath(*parts).resolve()
    
    # Ensure result is within base directory
    try:
        joined.relative_to(base)
    except ValueError:
        raise ValueError(f"Path traversal detected: {joined} is outside {base}")
    
    return str(joined)
