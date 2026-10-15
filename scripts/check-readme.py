#!/usr/bin/env python3
"""Compile and run every MoonBit README snippet against the working core."""
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
blocks = re.findall(r"```moonbit\n(.*?)\n```", (root / "README.md").read_text(), re.S)
if not blocks:
    raise SystemExit("No MoonBit README examples found")

with tempfile.TemporaryDirectory(prefix="moonbit-sql-readme-") as directory:
    project = Path(directory)
    (project / "moon.mod").write_text('name = "ash1day/sql"\n\nsource = "src"\n')
    for package in ("ast", "builder"):
        shutil.copytree(root / "src" / package, project / "src" / package)
    examples = project / "src" / "readme"
    examples.mkdir()
    (examples / "moon.pkg").write_text(
        'import {\n  "ash1day/sql/ast",\n  "ash1day/sql/builder",\n}\n'
    )
    source = "\n\n".join(
        f'test "README example {i}" {{\n{block}\n  ()\n}}'
        for i, block in enumerate(blocks, 1)
    )
    (examples / "readme_test.mbt").write_text(source)
    subprocess.run(["moon", "test", "src/readme", "--target", "js"], cwd=project, check=True)
print(f"README: {len(blocks)} MoonBit examples passed")
