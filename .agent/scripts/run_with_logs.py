#!/usr/bin/env python3
import os
import sys
import shlex
import subprocess
from datetime import datetime
from pathlib import Path

def main():
    if len(sys.argv) < 3:
        print('usage: run_with_logs.py <log_dir> <command...>', file=sys.stderr)
        return 2

    log_dir = Path(sys.argv[1]).resolve()
    command = sys.argv[2:]
    log_dir.mkdir(parents=True, exist_ok=True)

    stamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    base = f'{stamp}-{command[0].replace(os.sep, "_").replace(" ", "_")}'
    stdout_path = log_dir / f'{base}.stdout.log'
    stderr_path = log_dir / f'{base}.stderr.log'
    meta_path   = log_dir / f'{base}.meta.txt'

    with open(stdout_path, 'wb') as out, open(stderr_path, 'wb') as err:
        proc = subprocess.run(command, stdout=out, stderr=err)

    meta = [
        f'timestamp: {stamp}',
        f'cwd: {Path.cwd()}',
        f'command: {shlex.join(command)}',
        f'exit_status: {proc.returncode}',
        f'stdout: {stdout_path}',
        f'stderr: {stderr_path}',
    ]
    meta_path.write_text('\n'.join(meta) + '\n', encoding='utf-8')
    print(meta_path)
    return proc.returncode

if __name__ == '__main__':
    raise SystemExit(main())
