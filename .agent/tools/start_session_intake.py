#!/usr/bin/env python3
from pathlib import Path

FILES = {
    '.agent/reports/session-intake.md': '# Session Intake\n',
    '.agent/reports/understanding-proof.md': '# Understanding Proof\n',
    '.agent/reports/master-blueprint.md': '# Master Blueprint\n',
}

def main():
    root = Path('.').resolve()
    for rel, content in FILES.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.write_text(content, encoding='utf-8')
            print(f'created {path}')
        else:
            print(f'exists  {path}')

if __name__ == '__main__':
    main()
