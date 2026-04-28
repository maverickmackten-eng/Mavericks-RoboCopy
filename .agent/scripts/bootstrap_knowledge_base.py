#!/usr/bin/env python3
from pathlib import Path

FILES = {
    '.agent/knowledge/knowledge-index.md': '# Knowledge Index\n',
    '.agent/knowledge/lessons-learned.md': '# Lessons Learned\n',
    '.agent/knowledge/workflow-preferences.md': '# Workflow Preferences\n',
    '.agent/knowledge/stack-decisions.md': '# Stack Decisions\n',
    '.agent/knowledge/solution-patterns.md': '# Solution Patterns\n',
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
