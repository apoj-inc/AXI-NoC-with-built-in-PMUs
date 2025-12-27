"""
Pytest bootstrap to ensure temporary files go into a writable location.

Some environments lack a usable system TMP; direct pytest to a local cache dir.
"""
from pathlib import Path
import os


_tmpdir = Path(".cache/tmp").resolve()
_tmpdir.mkdir(parents=True, exist_ok=True)

for key in ("TMPDIR", "TMP", "TEMP"):
    os.environ[key] = str(_tmpdir)
