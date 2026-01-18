#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Create a new Xilinx ISE project folder from the Basys2Project template.

Usage:
  python create-new-project.py "project name"
"""

from pathlib import Path
import shutil
import sys
import re

TEMPLATE = "Basys2Project"
UCF_FILE = "Basys2_100_250General.ucf"

def sanitize_project_name(name: str) -> str:
    # spaces -> underscore, remove unsafe chars
    s = name.strip().replace(" ", "_")
    s = re.sub(r"[^A-Za-z0-9_]", "_", s)
    # VHDL identifiers cannot start with a digit
    if s and s[0].isdigit():
        s = "_" + s
    # avoid empty
    if not s:
        raise ValueError("Empty project name after sanitization.")
    return s

def main(argv):
    here = Path.cwd()

    # (optional) keep the original restriction, but make it clearer
    if here.name != "ise-basys2-project" or len(argv) != 1:
        sys.stderr.write('Usage: create-new-project.py "project name"\n')
        return 1

    raw_name = argv[0]
    project_id = sanitize_project_name(raw_name)

    target = here / project_id
    vhd_dir = target / "VHD"

    if target.exists():
        sys.stderr.write(f"{target} already exists. Exiting.\n")
        return 1

    target.mkdir()
    vhd_dir.mkdir()

    print(f"Working in {target}")

    # Copy UCF unchanged
    src_ucf = here / UCF_FILE
    if not src_ucf.exists():
        sys.stderr.write(f"Missing template file: {src_ucf}\n")
        return 1
    shutil.copyfile(src_ucf, target / UCF_FILE)

    # Load template files
    src_xise = here / f"{TEMPLATE}.xise"
    src_vhd  = here / f"{TEMPLATE}.vhd"

    if not src_xise.exists():
        sys.stderr.write(f"Missing template file: {src_xise}\n")
        return 1
    if not src_vhd.exists():
        sys.stderr.write(f"Missing template file: {src_vhd}\n")
        return 1

    xise = src_xise.read_text(encoding="utf-8", errors="replace")
    vhd  = src_vhd.read_text(encoding="utf-8", errors="replace")

    # Replace TEMPLATE name with a safe identifier (project_id)
    xise = xise.replace(TEMPLATE, project_id)
    vhd  = vhd.replace(TEMPLATE, project_id)

    # Write new files
    (target / f"{project_id}.xise").write_text(xise, encoding="utf-8")
    (vhd_dir / f"{project_id}.vhd").write_text(vhd, encoding="utf-8")

    print("Done.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
