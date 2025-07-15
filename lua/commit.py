#!/usr/bin/env python3
"""
Enhanced Git Diff Generator for AI Commit Messages
Generates structured diffs of staged changes optimized for AI consumption.
"""

import subprocess
import sys
import argparse
from pathlib import Path
from typing import List, Tuple, Optional, Set
import re


def is_binary_file(filepath: Path) -> bool:
    """
    Check if a file is binary by attempting to read it as text.
    Uses multiple heuristics for better detection.
    """
    try:
        with open(filepath, 'rb') as f:
            chunk = f.read(1024)
            if b'\0' in chunk:  # Null bytes indicate binary
                return True
            
        # Try to decode as UTF-8
        with open(filepath, 'r', encoding='utf-8') as f:
            f.read(1024)
        return False
    except (UnicodeDecodeError, FileNotFoundError, PermissionError):
        return True


def get_repo_root() -> Optional[Path]:
    """Get the root directory of the git repository."""
    try:
        output = subprocess.check_output(
            ['git', 'rev-parse', '--show-toplevel'],
            text=True,
            stderr=subprocess.DEVNULL
        ).strip()
        return Path(output)
    except subprocess.CalledProcessError:
        return None


def get_staged_changes() -> List[Tuple[str, str]]:
    """Get list of staged changes using git diff --cached --name-status."""
    try:
        # Get staged files with their status
        status_output = subprocess.check_output(
            ['git', 'diff', '--cached', '--name-status'],
            text=True,
            stderr=subprocess.DEVNULL
        ).splitlines()
    except subprocess.CalledProcessError as e:
        print(f"Error: Not in a git repository or git command failed: {e}", file=sys.stderr)
        return []
    
    changes = []
    for line in status_output:
        if not line.strip():
            continue
        
        parts = line.split('\t', 1)
        if len(parts) >= 2:
            status = parts[0]
            filepath = parts[1]
            changes.append((status, filepath))
    
    return changes


def get_file_diff(filepath: str, max_lines_per_file: int, context_lines: int = 3) -> List[str]:
    """Get git diff for a specific staged file with configurable context."""
    try:
        diff_output = subprocess.check_output(
            ['git', 'diff', '--cached', f'--unified={context_lines}', '--', filepath],
            text=True,
            stderr=subprocess.DEVNULL
        )
        
        diff_lines = diff_output.splitlines()
        
        if len(diff_lines) > max_lines_per_file:
            # Try to keep the header and some context
            header_lines = []
            content_lines = []
            
            for i, line in enumerate(diff_lines):
                if line.startswith('@@') or line.startswith('+++') or line.startswith('---'):
                    if len(header_lines) < 10:  # Keep reasonable header size
                        header_lines.append(line)
                    else:
                        content_lines.extend(diff_lines[i:])
                        break
                elif i < 10:
                    header_lines.append(line)
                else:
                    content_lines.append(line)
            
            # Calculate remaining space for content
            remaining_lines = max_lines_per_file - len(header_lines) - 1
            if remaining_lines > 0:
                content_lines = content_lines[:remaining_lines]
            
            diff_lines = header_lines + content_lines
            diff_lines.append(f"... (diff truncated at {max_lines_per_file} lines)")
            
        return diff_lines
    except subprocess.CalledProcessError:
        return []


def get_file_stats(filepath: str) -> str:
    """Get file statistics (additions/deletions) for a staged file."""
    try:
        stat_output = subprocess.check_output(
            ['git', 'diff', '--cached', '--numstat', '--', filepath],
            text=True,
            stderr=subprocess.DEVNULL
        ).strip()
        
        if stat_output:
            parts = stat_output.split('\t')
            if len(parts) >= 2:
                additions, deletions = parts[0], parts[1]
                if additions != '-' and deletions != '-':
                    return f"(+{additions}/-{deletions})"
        return ""
    except subprocess.CalledProcessError:
        return ""


def format_status(status: str) -> str:
    """Convert git status codes to readable format."""
    status_map = {
        'A': 'Added',
        'M': 'Modified',
        'D': 'Deleted',
        'R': 'Renamed',
        'C': 'Copied',
        'T': 'Type changed',
        'U': 'Unmerged'
    }
    
    # Handle rename/copy with similarity score (e.g., "R100")
    if status.startswith('R') or status.startswith('C'):
        base_status = status[0]
        return status_map.get(base_status, base_status)
    
    return status_map.get(status, status)


def should_include_file(filepath: str, include_patterns: List[str], exclude_patterns: List[str]) -> bool:
    """Check if file should be included based on patterns."""
    path = Path(filepath)
    
    # Check exclude patterns first
    for pattern in exclude_patterns:
        if path.match(pattern):
            return False
    
    # If include patterns specified, file must match at least one
    if include_patterns:
        return any(path.match(pattern) for pattern in include_patterns)
    
    return True


def get_staged_diff(
    max_lines_per_file: int = 100,
    context_lines: int = 3,
    include_stats: bool = True,
    include_patterns: Optional[List[str]] = None,
    exclude_patterns: Optional[List[str]] = None,
    group_by_type: bool = False
) -> str:
    """Generate enhanced git diff for staged changes."""
    
    # Set defaults
    include_patterns = include_patterns or []
    exclude_patterns = exclude_patterns or ['*.pyc', '*.pyo', '__pycache__/*', '.git/*', '*.so', '*.dylib', '*.dll']
    
    # Check if we're in a git repo
    repo_root = get_repo_root()
    if not repo_root:
        return "Error: Not in a git repository."
    
    output = ["=== Staged Changes Summary ==="]
    
    staged_changes = get_staged_changes()
    if not staged_changes:
        output.append("No staged changes found.")
        return "\n".join(output)
    
    # Filter files based on patterns
    filtered_changes = [
        (status, filepath) for status, filepath in staged_changes
        if should_include_file(filepath, include_patterns, exclude_patterns)
    ]
    
    if not filtered_changes:
        output.append("No files match the specified patterns.")
        return "\n".join(output)
    
    # Group by file type if requested
    if group_by_type:
        by_type = {}
        for status, filepath in filtered_changes:
            ext = Path(filepath).suffix.lower() or 'no_extension'
            if ext not in by_type:
                by_type[ext] = []
            by_type[ext].append((status, filepath))
        
        output.append(f"\nFile types: {', '.join(sorted(by_type.keys()))}")
    
    output.append(f"\nTotal files: {len(filtered_changes)}")
    output.append("=" * 50)
    
    processed_files: Set[str] = set()
    
    for status, filepath in filtered_changes:
        if filepath in processed_files:
            continue
        processed_files.add(filepath)
        
        # Get path relative to repo root
        path = Path(filepath)
        absolute_path = repo_root / filepath
        
        # Use absolute path relative to repo root
        absolute_path = repo_root / filepath
        print(absolute_path)
        
        if not absolute_path.exists() and 'D' not in status:
            output.append(f"\nFile not found: {filepath} ({format_status(status)})")
            continue
        
        if absolute_path.exists() and absolute_path.is_dir():
            output.append(f"\nDirectory {format_status(status)}: {filepath}")
            continue
        
        # Handle binary files
        if absolute_path.exists() and is_binary_file(absolute_path):
            stats = get_file_stats(filepath) if include_stats else ""
            output.append(f"\nBinary file {format_status(status)}: {filepath} {stats}")
            continue
        
        # Handle text files
        stats = get_file_stats(absolute_path.as_posix()) if include_stats else ""
        file_header = f"\n{absolute_path.as_posix()} ({format_status(status)}) {stats}"
        output.append(file_header)
        output.append("-" * min(len(file_header), 80))
        
        diff_lines = get_file_diff(absolute_path.as_posix(), max_lines_per_file, context_lines)
        if diff_lines:
            output.extend(diff_lines)
        else:
            output.append("No diff available.")
        
        output.append("")  # Empty line between files
    
    return "\n".join(output)


def main():
    """Main entry point with argument parsing."""
    parser = argparse.ArgumentParser(
        description="Generate structured git diff of staged changes for AI consumption",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Basic usage
  %(prog)s -l 200                   # Increase line limit
  %(prog)s -c 5                     # More context lines
  %(prog)s --include "*.py" "*.js"  # Only Python and JavaScript files
  %(prog)s --exclude "*.md"         # Exclude markdown files
  %(prog)s --group-by-type          # Group files by extension
        """
    )
    
    parser.add_argument(
        '-l', '--max-lines',
        type=int,
        default=100,
        help='Maximum lines per file (default: 100)'
    )
    
    parser.add_argument(
        '-c', '--context',
        type=int,
        default=3,
        help='Number of context lines in diff (default: 3)'
    )
    
    parser.add_argument(
        '--no-stats',
        action='store_true',
        help='Disable file statistics (+lines/-lines)'
    )
    
    parser.add_argument(
        '--include',
        nargs='+',
        help='Include only files matching these patterns'
    )
    
    parser.add_argument(
        '--exclude',
        nargs='+',
        help='Exclude files matching these patterns'
    )
    
    parser.add_argument(
        '--group-by-type',
        action='store_true',
        help='Group files by file type'
    )
    
    args = parser.parse_args()
    
    try:
        result = get_staged_diff(
            max_lines_per_file=args.max_lines,
            context_lines=args.context,
            include_stats=not args.no_stats,
            include_patterns=args.include,
            exclude_patterns=args.exclude,
            group_by_type=args.group_by_type
        )
        print(result)
    except KeyboardInterrupt:
        print("\nOperation cancelled.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
