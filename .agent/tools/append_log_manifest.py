#!/usr/bin/env python3
import sys
from datetime import datetime
from pathlib import Path

def main():
    if len(sys.argv) != 8:
        print('usage: append_log_manifest.py <manifest> <command> <purpose> <cwd> <exit_code> <stdout_path> <stderr_path>', file=sys.stderr)
        return 2
    manifest, command, purpose, cwd, exit_code, stdout_path, stderr_path = sys.argv[1:]
    path = Path(manifest)
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text('# Log Manifest\n\n', encoding='utf-8')
    entry = '\n'.join([
        '## Entry',
        f'- Timestamp: {datetime.now().isoformat()}',
        f'- Command: {command}',
        f'- Purpose: {purpose}',
        f'- Working directory: {cwd}',
        f'- Exit status: {exit_code}',
        f'- Stdout log: {stdout_path}',
        f'- Stderr log: {stderr_path}',
        ''
    ])
    with path.open('a', encoding='utf-8') as f:
        f.write(entry)
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
