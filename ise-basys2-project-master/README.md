# Basys 2 Xilinx ISE Project Template

This repository provides a clean, minimal template for creating
Xilinx ISE projects targeting the **Digilent Basys 2 (Spartan-3E) FPGA board**.

It is intended to be used as a **starting point** for new projects,
experiments, and educational work with Basys 2.

🇷🇺 Русская версия: [README.ru.md](README.ru.md)

---

## Overview

This repository contains:
- A ready-to-use Xilinx ISE project template
- A Python script to generate new projects from the template
- Proper default constraints for the Basys 2 board

The goal is to avoid repetitive manual setup in Xilinx ISE and
provide a known-good starting configuration.

---

## Requirements

- Digilent **Basys 2** FPGA board
- Xilinx **ISE WebPACK**
- Digilent **Adept**
- Python 3.x (for project generation script)

---

## Repository Structure

ise-basys2-project/
├── Basys2Project.xise # Template ISE project
├── Basys2Project.vhd # Template top-level HDL (can be replaced)
├── Basys2_100_250General.ucf # Basys 2 constraints file
├── create-new-project.py # Project generation script
├── .gitignore
├── README.md
└── README.ru.md

yaml
Копировать код

---

## Creating a New Project

1. Set your working directory to the repository root:

```bash
cd ise-basys2-project
Run the project creation script:

bash
Копировать код
python create-new-project.py "Project Name"
A new directory will be created:

text
Копировать код
Project_Name/
├── Project_Name.xise
├── Basys2_100_250General.ucf
└── VHD/
    └── Project_Name.vhd
Open the .xise file in Xilinx ISE and build the project.

HDL Language Support
Xilinx ISE does not enforce a single HDL per project.

A project may use:

VHDL (.vhd)

Verilog (.v)

or a mix of both

Only the top-level module/entity matters.

You are free to replace the template VHDL file with Verilog if desired.

Important ISE Setting: FPGA Start-Up Clock
When programming the FPGA directly via JTAG (Adept), the default
startup clock must be changed.

Required setting:

FPGA Start-Up Clock → JTAG Clock

Path in ISE:

mathematica
Копировать код
Generate Programming File
→ Process Properties
→ Startup Options
→ FPGA Start-Up Clock
This setting is required for reliable JTAG-based development.
The default CCLK is only appropriate when booting from Platform Flash.

Version Control Notes
Xilinx ISE generates many temporary and build artifacts.
A suitable .gitignore is included to keep repositories clean.

Only the following files are typically committed:

.xise

.ucf

.v / .vhd

README*

Attribution
This project is based on the original work by
Thomas Russell Murphy:

https://github.com/thomasrussellmurphy/ise-basys2-project

Basys 2™ is a trademark of Digilent Inc.