#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import json
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

NET_RE = re.compile(r'^\s*NET\s+"([^"]+)"', re.IGNORECASE)
LOC_RE = re.compile(r'\bLOC\s*=\s*"?(?P<loc>[A-Z0-9]+)"?', re.IGNORECASE)

CONFIG_FILE = os.path.join(os.path.dirname(__file__), "ucf_gui_config.json")


def is_comment_line(line: str) -> bool:
    s = line.lstrip()
    return s.startswith("#") or s.startswith("//")


def read_text_keep_endings(path: str):
    """Read file in binary to preserve original line endings; return (lines:list[str], has_crlf:bool)."""
    with open(path, "rb") as f:
        data = f.read()
    has_crlf = b"\r\n" in data
    text = data.decode("utf-8", errors="replace")
    lines = text.splitlines(True)  # keep line endings
    # Ensure file ends with a newline in list form (optional, but safe)
    if lines and not (lines[-1].endswith("\n") or lines[-1].endswith("\r")):
        lines[-1] += "\r\n" if has_crlf else "\n"
    return lines, has_crlf


def write_text_keep_endings(path: str, lines):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        out = "".join(lines).encode("utf-8", errors="replace")
        f.write(out)


class ScrollFrame(ttk.Frame):
    def __init__(self, master):
        super().__init__(master)
        self.canvas = tk.Canvas(self, highlightthickness=0)
        self.vsb = ttk.Scrollbar(self, orient="vertical", command=self.canvas.yview)
        self.inner = ttk.Frame(self.canvas)

        self.inner.bind("<Configure>", lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")))
        self.canvas.create_window((0, 0), window=self.inner, anchor="nw")
        self.canvas.configure(yscrollcommand=self.vsb.set)

        self.canvas.pack(side="left", fill="both", expand=True)
        self.vsb.pack(side="right", fill="y")

        # Mouse wheel
        self.canvas.bind_all("<MouseWheel>", self._on_mousewheel)  # Windows
        self.canvas.bind_all("<Button-4>", self._on_mousewheel_linux)
        self.canvas.bind_all("<Button-5>", self._on_mousewheel_linux)

    def _on_mousewheel(self, event):
        self.canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")

    def _on_mousewheel_linux(self, event):
        if event.num == 4:
            self.canvas.yview_scroll(-3, "units")
        elif event.num == 5:
            self.canvas.yview_scroll(3, "units")


class UcfGui(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("UCF Editor (Python 3.7) — чекбоксы для NET")
        self.geometry("1040x760")

        # Data
        self.ucf_path = ""
        self.lines = []
        self.net_to_indices = {}      # net -> list[int]
        self.net_to_loc = {}          # net -> "B8"
        self.net_to_section = {}      # net -> section title
        self.section_order = []
        self.section_to_nets = {}     # section -> list[net]
        self.net_vars = {}            # net -> BooleanVar
        self.all_nets = []

        self._build_ui()
        self._load_config()

    def _build_ui(self):
        # Top controls
        top = ttk.Frame(self, padding=10)
        top.pack(fill="x")

        ttk.Button(top, text="Открыть .ucf", command=self.open_ucf).pack(side="left")
        self.lbl_file = ttk.Label(top, text="Файл не выбран")
        self.lbl_file.pack(side="left", padx=10)

        ttk.Label(top, text="Поиск:").pack(side="left", padx=(20, 6))
        self.search_var = tk.StringVar(value="")
        ent = ttk.Entry(top, textvariable=self.search_var, width=30)
        ent.pack(side="left")
        ent.bind("<KeyRelease>", lambda e: self.render_list())

        # Presets
        presets = ttk.Frame(self, padding=(10, 0, 10, 10))
        presets.pack(fill="x")

        ttk.Button(presets, text="Preset: только SW+LED", command=self.preset_sw_led).pack(side="left")
        ttk.Button(presets, text="Preset: SW+LED+BTN", command=self.preset_sw_led_btn).pack(side="left", padx=8)
        ttk.Button(presets, text="Preset: выбрать всё", command=self.select_all).pack(side="left")
        ttk.Button(presets, text="Снять всё", command=self.select_none).pack(side="left", padx=8)
        ttk.Button(presets, text="Инвертировать", command=self.select_invert).pack(side="left")

        # Save box
        save_box = ttk.LabelFrame(self, text="Сохранение", padding=10)
        save_box.pack(fill="x", padx=10, pady=(0, 10))

        row1 = ttk.Frame(save_box)
        row1.pack(fill="x")
        ttk.Label(row1, text="Папка проекта:").pack(side="left")

        self.project_dir_var = tk.StringVar(value="")
        ttk.Entry(row1, textvariable=self.project_dir_var).pack(side="left", fill="x", expand=True, padx=8)
        ttk.Button(row1, text="Выбрать...", command=self.pick_project_dir).pack(side="left")

        row2 = ttk.Frame(save_box)
        row2.pack(fill="x", pady=(8, 0))
        ttk.Label(row2, text="Имя проекта (по умолчанию = имя папки проекта):").pack(side="left")

        self.project_name_var = tk.StringVar(value="")
        ttk.Entry(row2, textvariable=self.project_name_var, width=30).pack(side="left", padx=8)

        self.mode_var = tk.StringVar(value="named")  # named/overwrite/custom
        ttk.Radiobutton(save_box, text="Создать файл <ProjectName>.ucf в папке проекта",
                        variable=self.mode_var, value="named").pack(anchor="w")
        ttk.Radiobutton(save_box, text="Перезаписать исходный .ucf (тот, что открыт)",
                        variable=self.mode_var, value="overwrite").pack(anchor="w")
        ttk.Radiobutton(save_box, text="Сохранить как... (выбрать путь вручную)",
                        variable=self.mode_var, value="custom").pack(anchor="w")

        bottom = ttk.Frame(self, padding=(10, 0, 10, 10))
        bottom.pack(fill="x")
        self.status_lbl = ttk.Label(bottom, text="")
        self.status_lbl.pack(side="left")
        ttk.Button(bottom, text="Сохранить", command=self.save_ucf).pack(side="right")

        # List area
        self.scroll = ScrollFrame(self)
        self.scroll.pack(fill="both", expand=True, padx=10, pady=(0, 10))

        hint = (
            "Совет: для проектов типа P01/P02 обычно достаточно оставить SW<0..7>, LED<0..7> "
            "(и опционально BTN<0..3>). Отключение VGA/PIO/EppDB/PS2 убирает предупреждения ISE."
        )
        ttk.Label(self, text=hint, foreground="#666", wraplength=1000).pack(fill="x", padx=10, pady=(0, 10))

    def set_status(self, text: str):
        self.status_lbl.configure(text=text)

    # ---------- Config ----------
    def _load_config(self):
        try:
            if os.path.isfile(CONFIG_FILE):
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    cfg = json.load(f)
                last_dir = cfg.get("last_dir", "")
                if last_dir and os.path.isdir(last_dir):
                    self.project_dir_var.set(last_dir)
        except Exception:
            pass

    def _save_config(self):
        try:
            cfg = {"last_dir": self.project_dir_var.get().strip()}
            with open(CONFIG_FILE, "w", encoding="utf-8") as f:
                json.dump(cfg, f, ensure_ascii=False, indent=2)
        except Exception:
            pass

    # ---------- UCF parsing ----------
    def open_ucf(self):
        # Try to start in a likely folder (you can change)
        initial = self.project_dir_var.get().strip()
        if not initial or not os.path.isdir(initial):
            # fallback: typical shared folder name
            initial = os.path.join(os.path.expanduser("~"), "Xilinx", "projects")

        path = filedialog.askopenfilename(
            title="Открыть UCF",
            initialdir=initial if os.path.isdir(initial) else None,
            filetypes=[("UCF files", "*.ucf"), ("All files", "*.*")]
        )
        if not path:
            return

        self.ucf_path = path
        self.lbl_file.configure(text=os.path.basename(path))

        # auto-set project dir to folder containing this ucf
        proj_dir = os.path.dirname(path)
        self.project_dir_var.set(proj_dir)

        # auto project name = folder name
        folder_name = os.path.basename(proj_dir.rstrip("\\/"))
        if not self.project_name_var.get().strip():
            self.project_name_var.set(folder_name)

        self._parse_ucf(path)
        self.render_list()
        self._save_config()

    def _parse_ucf(self, path: str):
        self.lines, _ = read_text_keep_endings(path)

        self.net_to_indices.clear()
        self.net_to_loc.clear()
        self.net_to_section.clear()
        self.section_order.clear()
        self.section_to_nets.clear()
        self.net_vars.clear()
        self.all_nets.clear()

        current_section = "Без секции"
        self.section_order.append(current_section)
        self.section_to_nets[current_section] = []

        for idx, line in enumerate(self.lines):
            # any comment line can be considered a "section" title
            if is_comment_line(line):
                t = line.strip().lstrip("#/").strip()
                if t:
                    current_section = t
                    if current_section not in self.section_to_nets:
                        self.section_to_nets[current_section] = []
                        self.section_order.append(current_section)

            m = NET_RE.match(line)
            if not m:
                continue

            net = m.group(1).strip()

            if net not in self.net_to_indices:
                self.net_to_indices[net] = []
                self.net_to_section[net] = current_section
                self.section_to_nets[current_section].append(net)
                self.all_nets.append(net)

            self.net_to_indices[net].append(idx)

            if net not in self.net_to_loc:
                locm = LOC_RE.search(line)
                if locm:
                    self.net_to_loc[net] = locm.group("loc")

        for net in self.all_nets:
            self.net_vars[net] = tk.BooleanVar(value=True)

        self.set_status(f"NET-сигналов найдено: {len(self.all_nets)}")

    # ---------- Rendering ----------
    def _clear_list(self):
        for w in self.scroll.inner.winfo_children():
            w.destroy()

    def render_list(self):
        if not self.ucf_path:
            return

        q = self.search_var.get().strip().lower()

        self._clear_list()

        shown = 0
        for sec in self.section_order:
            nets = self.section_to_nets.get(sec, [])
            if not nets:
                continue

            # filter nets by search query
            filtered = []
            for net in nets:
                if not q:
                    filtered.append(net)
                else:
                    loc = self.net_to_loc.get(net, "")
                    hay = (net + " " + loc + " " + sec).lower()
                    if q in hay:
                        filtered.append(net)

            if not filtered:
                continue

            lab = ttk.Label(self.scroll.inner, text=sec, font=("Segoe UI", 11, "bold"))
            lab.pack(anchor="w", pady=(10, 4))

            for net in filtered:
                loc = self.net_to_loc.get(net, "")
                suffix = f"  (LOC={loc})" if loc else ""
                cb = ttk.Checkbutton(
                    self.scroll.inner,
                    text=f"{net}{suffix}",
                    variable=self.net_vars[net]
                )
                cb.pack(anchor="w", padx=12)
                shown += 1

        self.set_status(f"NET-сигналов: {len(self.all_nets)} | показано: {shown}")

    # ---------- Presets / selection ----------
    def select_all(self):
        for v in self.net_vars.values():
            v.set(True)

    def select_none(self):
        for v in self.net_vars.values():
            v.set(False)

    def select_invert(self):
        for v in self.net_vars.values():
            v.set(not v.get())

    def preset_sw_led(self):
        keep_prefix = ("SW<", "LED<")
        for net, var in self.net_vars.items():
            var.set(net.startswith(keep_prefix))

    def preset_sw_led_btn(self):
        keep_prefix = ("SW<", "LED<", "BTN<")
        for net, var in self.net_vars.items():
            var.set(net.startswith(keep_prefix))

    # ---------- Save ----------
    def pick_project_dir(self):
        d = filedialog.askdirectory(title="Выберите папку проекта (куда сохранять UCF)")
        if d:
            self.project_dir_var.set(d)
            # default project name = folder name
            folder_name = os.path.basename(d.rstrip("\\/"))
            if not self.project_name_var.get().strip():
                self.project_name_var.set(folder_name)
            self._save_config()

    def _build_output_path(self):
        mode = self.mode_var.get()

        if mode == "custom":
            return filedialog.asksaveasfilename(
                title="Сохранить UCF как...",
                defaultextension=".ucf",
                filetypes=[("UCF files", "*.ucf"), ("All files", "*.*")]
            ) or ""

        if mode == "overwrite":
            return self.ucf_path

        # named
        project_dir = self.project_dir_var.get().strip()
        if not project_dir or not os.path.isdir(project_dir):
            messagebox.showerror("Ошибка", "Укажите корректную папку проекта.")
            return ""

        pname = self.project_name_var.get().strip()
        if not pname:
            pname = os.path.basename(project_dir.rstrip("\\/")) or "project"

        return os.path.join(project_dir, f"{pname}.ucf")

    def save_ucf(self):
        if not self.ucf_path:
            messagebox.showwarning("Нет файла", "Сначала откройте .ucf")
            return

        out_path = self._build_output_path()
        if not out_path:
            return

        enabled = {net for net, var in self.net_vars.items() if var.get()}

        out_lines = list(self.lines)
        for net, indices in self.net_to_indices.items():
            if net in enabled:
                continue
            for idx in indices:
                line = out_lines[idx]
                if is_comment_line(line):
                    continue
                out_lines[idx] = "# " + line

        try:
            write_text_keep_endings(out_path, out_lines)
            messagebox.showinfo("Готово", f"UCF сохранён:\n{out_path}")
            self.set_status(f"Сохранено: {out_path}")
            self._save_config()
        except Exception as e:
            messagebox.showerror("Ошибка сохранения", str(e))


def main():
    app = UcfGui()
    app.mainloop()


if __name__ == "__main__":
    main()
