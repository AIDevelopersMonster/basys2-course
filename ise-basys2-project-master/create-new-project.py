#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Script for creating new project from the Basys2Project project
import os
import shutil
import sys
import re

basys2 = "Basys2Project"

def sanitize_name(name):
    name = name.strip()
    name = name.replace(" ", "_")
    name = re.sub(r'[^A-Za-z0-9_]', '_', name)
    if not name:
        return None
    if name[0].isdigit():
        name = "_" + name
    return name

def main(argv):
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    here = script_dir
    projects_dir = os.path.dirname(script_dir)

    if len(argv) != 1:
        sys.stderr.write('Usage: create-new-project.py "project name"\n')
        sys.stderr.flush()
        return 1

    raw_name = argv[0]
    desired_name = sanitize_name(raw_name)
    if not desired_name:
        sys.stderr.write("Invalid project name.\n")
        return 1

    target = os.path.abspath(os.path.join(projects_dir, desired_name))

    try:
        os.mkdir(target)
        os.mkdir(os.path.join(target, 'VHD'))
    except OSError:
        sys.stderr.write(target + " already exists. Exiting.\n")
        return 1

    print "Working in " + target

    # Files that need no modification:
    shutil.copyfile(
        os.path.join(here, 'Basys2_100_250General.ucf'),
        os.path.join(target, 'Basys2_100_250General.ucf'))

    # Files that need modification: .xise, .vhd
    xise = open(os.path.join(here, basys2 + ".xise"), 'r').read()
    vhd  = open(os.path.join(here, basys2 + ".vhd"), 'r').read()

    # IMPORTANT: replace with desired_name (safe identifier), not raw_name
    xise = xise.replace(basys2, desired_name)
    vhd  = vhd.replace(basys2, desired_name)

    xiseF = open(os.path.join(target, desired_name + ".xise"), 'w')
    vhdF  = open(os.path.join(target, "VHD", desired_name + ".vhd"), 'w')

    xiseF.write(xise)
    vhdF.write(vhd)

    xiseF.close()
    vhdF.close()

    print "Done."
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
