#!/usr/bin/env python3
from pathlib import Path

DIRS = [
    '.agent',
    '.agent/logs',
    '.agent/evidence',
    '.agent/research',
    '.agent/state',
    '.agent/reports',
    '.agent/knowledge',
]

FILES = {
    '.agent/reports/session-intake.md': '# Session Intake\n',
    '.agent/reports/understanding-proof.md': '# Understanding Proof\n',
    '.agent/reports/master-blueprint.md': '# Master Blueprint\n',
    '.agent/reports/path-index.md': '# Path Index\n',
    '.agent/reports/project-report.md': '# Project Report\n',
    '.agent/reports/research-report.md': '# Research Report\n',
    '.agent/reports/tasks.md': '# Tasks\n',
    '.agent/reports/runbook.md': '# Runbook\n',
    '.agent/reports/progress.md': '# Progress\n',
    '.agent/reports/log-manifest.md': '# Log Manifest\n',
    '.agent/state/router.md': '# Router State\n',
    '.agent/knowledge/knowledge-index.md': '# Knowledge Index\n',
    '.agent/knowledge/lessons-learned.md': '# Lessons Learned\n',
    '.agent/knowledge/workflow-preferences.md': '# Workflow Preferences\n',
    '.agent/knowledge/stack-decisions.md': '# Stack Decisions\n',
    '.agent/knowledge/solution-patterns.md': '# Solution Patterns\n',
}

def main():
    root = Path('.').resolve()
    for d in DIRS:
        (root / d).mkdir(parents=True, exist_ok=True)
    for rel, content in FILES.items():
        path = root / rel
        if not path.exists():
            path.write_text(content, encoding='utf-8')
            print(f'created {path}')
        else:
            print(f'exists  {path}')

if __name__ == '__main__':
    main()
