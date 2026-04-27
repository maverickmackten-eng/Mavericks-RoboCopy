#!/usr/bin/env python3
import sys
from datetime import datetime
from pathlib import Path

def main():
    if len(sys.argv) < 4:
        print('usage: update_knowledge_entry.py <file_path> <title> <body>', file=sys.stderr)
        return 2
    file_path = Path(sys.argv[1])
    title = sys.argv[2]
    body = sys.argv[3]
    file_path.parent.mkdir(parents=True, exist_ok=True)
    if not file_path.exists():
        file_path.write_text('', encoding='utf-8')
    with file_path.open('a', encoding='utf-8') as f:
        f.write(f'\n## {title}\n')
        f.write(f'- Timestamp: {datetime.now().isoformat()}\n')
        for line in body.split('\\n'):
            f.write(f'- {line}\n')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
