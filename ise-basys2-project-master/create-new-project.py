#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Simplified Basys2 ISE project creator (Python 2.6 compatible).

- Template files are read from the script directory:
    Basys2Project.xise
    Basys2Project.vhd
    Basys2_100_250General.ucf

- New projects are created in the parent directory of the script folder.
- NO VHD/ folder: the generated .vhd is placed in the project root.
"""

import os
import re
import shutil
import sys

TEMPLATE = "Basys2Project"
UCF_FILE = "Basys2_100_250General.ucf"

# Optional additional template files (copied into every new project)
TB_TEMPLATE = "Basys2Project_tb.vhd"
README_TEMPLATE = "README_TEMPLATE.md"

def sanitize_name(name):
    """
    Make a filesystem- and VHDL-friendly project identifier:
    - trim
    - spaces -> underscores
    - non [A-Za-z0-9_] -> underscore
    - if starts with digit, prefix underscore
    """
    name = name.strip()
    name = name.replace(" ", "_")
    name = re.sub(r'[^A-Za-z0-9_]', '_', name)
    if not name:
        return None
    if name[0].isdigit():
        name = "_" + name
    return name

def main(argv):
    if len(argv) != 1:
        sys.stderr.write('Usage: create-new-project.py "project name"\n')
        sys.stderr.flush()
        return 1

    raw_name = argv[0]
    project_id = sanitize_name(raw_name)
    if not project_id:
        sys.stderr.write("Invalid project name.\n")
        return 1

    # Template lives next to this script
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # New projects are created one level above (e.g. .../projects)
    projects_dir = os.path.dirname(script_dir)

    # Template file paths
    src_ucf  = os.path.join(script_dir, UCF_FILE)
    src_xise = os.path.join(script_dir, TEMPLATE + ".xise")
    src_vhd  = os.path.join(script_dir, TEMPLATE + ".vhd")
    src_tb   = os.path.join(script_dir, TB_TEMPLATE)
    src_md   = os.path.join(script_dir, README_TEMPLATE)

    for p in [src_ucf, src_xise, src_vhd, src_tb, src_md]:
        if not os.path.exists(p):
            sys.stderr.write("Missing template file: " + p + "\n")
            return 1

    # Target project directory
    target = os.path.join(projects_dir, project_id)

    if os.path.exists(target):
        sys.stderr.write(target + " already exists. Exiting.\n")
        return 1

    try:
        os.mkdir(target)
    except OSError:
        sys.stderr.write("Failed to create project directory: " + target + "\n")
        return 1

    print "Working in " + target

    # Copy UCF unchanged
    shutil.copyfile(src_ucf, os.path.join(target, UCF_FILE))

    # Load template strings
    xise = open(src_xise, 'r').read()
    vhd  = open(src_vhd, 'r').read()
    tb   = open(src_tb, 'r').read()
    md   = open(src_md, 'r').read()

    # Replace template identifier with safe project identifier
    xise = xise.replace(TEMPLATE, project_id)
    vhd  = vhd.replace(TEMPLATE, project_id)
    tb   = tb.replace(TEMPLATE, project_id)
    md   = md.replace(TEMPLATE, project_id)

    # Write new files in project root (no VHD/ folder)
    out_xise = os.path.join(target, project_id + ".xise")
    out_vhd  = os.path.join(target, project_id + ".vhd")
    out_tb   = os.path.join(target, project_id + "_tb.vhd")
    out_md   = os.path.join(target, "README.md")

    try:
        fx = open(out_xise, 'w')
        fv = open(out_vhd, 'w')
        ft = open(out_tb, 'w')
        fm = open(out_md, 'w')
        fx.write(xise)
        fv.write(vhd)
        ft.write(tb)
        fm.write(md)
        fx.close()
        fv.close()
        ft.close()
        fm.close()
    except Exception:
        sys.stderr.write("Failed to write project files.\n")
        return 1

    print "Done."
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
