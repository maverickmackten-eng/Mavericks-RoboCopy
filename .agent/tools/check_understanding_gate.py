#!/usr/bin/env python3
import sys
from pathlib import Path

REQUIRED_FILES = [
    '.agent/reports/session-intake.md',
    '.agent/reports/understanding-proof.md',
    '.agent/reports/master-blueprint.md',
    '.agent/reports/path-index.md',
]

REQUIRED_MARKERS = {
    '.agent/reports/understanding-proof.md': [
        '## Files Read',
        '## End-to-End Understanding',
        '## Next Phase Justification',
    ],
    '.agent/reports/session-intake.md': [
        '## Startup Checklist',
        '## Required Reading Evidence',
    ],
    '.agent/reports/master-blueprint.md': [
        '## Mission',
        '## Architecture',
        '## Delivery Plan',
    ],
}

def main():
    root = Path('.').resolve()
    missing = []
    for rel in REQUIRED_FILES:
        path = root / rel
        if not path.exists():
            missing.append(f'missing file: {rel}')
            continue
        text = path.read_text(encoding='utf-8', errors='ignore')
        for marker in REQUIRED_MARKERS.get(rel, []):
            if marker not in text:
                missing.append(f'missing marker "{marker}" in {rel}')
    if missing:
        print('UNDERSTANDING_GATE_FAILED')
        for item in missing:
            print(item)
        return 1
    print('UNDERSTANDING_GATE_PASSED')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
