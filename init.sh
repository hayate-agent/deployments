#!/bin/sh
# Create only missing local configuration; never replace an identity or secret.
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
umask 077
command -v python3 >/dev/null 2>&1 || { echo 'python3 is required for local setup' >&2; exit 1; }
python3 - <<'PY'
from pathlib import Path
import os, secrets
root = Path('.')
for source, target in [('config/hayate-agent.example.yaml', 'config/hayate-agent.yaml'),
                       ('config/models.example.json', 'config/models.json'),
                       ('config/SOUL.example.md', 'config/SOUL.md'), ('.env.example', '.env')]:
    data = (root / source).read_text()
    if target == '.env':
        data = data.replace('API_SERVER_KEY=\n', 'API_SERVER_KEY=' + secrets.token_hex(32) + '\n')
    try:
        fd = os.open(root / target, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    except FileExistsError:
        print('Kept existing ' + target)
        continue
    with os.fdopen(fd, 'w') as file:
        file.write(data)
    print('Created ' + target)
workspace = root / 'workspace'
workspace.mkdir(mode=0o700, exist_ok=True)
if workspace.is_symlink() or not workspace.is_dir():
    raise SystemExit('workspace must be a real directory')
PY
printf '\nSet MODEL_API_KEY in .env, review config/, then run: docker compose up --build -d\n'
