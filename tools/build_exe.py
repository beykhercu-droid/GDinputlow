#!/usr/bin/env python3
"""Compila un script AutoHotkey v1 a .exe usando Ahk2Exe (Windows)."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


def _is_windows() -> bool:
    return os.name == "nt"


def find_ahk2exe(explicit: str | None) -> str | None:
    """Busca Ahk2Exe en ruta explícita, rutas típicas y PATH."""
    if explicit:
        path = Path(explicit)
        return str(path) if path.exists() else None

    candidates: list[Path] = []
    pf = os.environ.get("ProgramFiles")
    pfx86 = os.environ.get("ProgramFiles(x86)")
    local = os.environ.get("LOCALAPPDATA")

    if pf:
        candidates.append(Path(pf) / "AutoHotkey" / "Compiler" / "Ahk2Exe.exe")
    if pfx86:
        candidates.append(Path(pfx86) / "AutoHotkey" / "Compiler" / "Ahk2Exe.exe")
    if local:
        candidates.append(Path(local) / "Programs" / "AutoHotkey" / "Compiler" / "Ahk2Exe.exe")

    which = shutil.which("Ahk2Exe.exe") or shutil.which("Ahk2Exe")
    if which:
        candidates.append(Path(which))

    for path in candidates:
        if path.exists() and path.is_file():
            return str(path)

    return None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compila GDinputlow.ahk a EXE con Ahk2Exe",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--source", default="GDinputlow.ahk", help="Ruta al archivo .ahk")
    parser.add_argument("--output", default="dist/GDinputlow.exe", help="Ruta de salida .exe")
    parser.add_argument("--ahk2exe", default=None, help="Ruta explícita a Ahk2Exe.exe")
    parser.add_argument("--icon", default=None, help="Ruta a icono .ico opcional")
    parser.add_argument("--base", default=None, help="Ruta a base binaria de AutoHotkey (opcional)")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Solo imprime el comando final sin ejecutar compilación",
    )
    parser.add_argument("--verbose", action="store_true", help="Muestra información adicional")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    source = Path(args.source)
    output = Path(args.output)
    icon = Path(args.icon) if args.icon else None
    base = Path(args.base) if args.base else None

    if not source.exists() or not source.is_file():
        print(f"ERROR: no existe el source: {source}", file=sys.stderr)
        return 1

    if icon and (not icon.exists() or not icon.is_file()):
        print(f"ERROR: no existe el icono: {icon}", file=sys.stderr)
        return 1

    if base and (not base.exists() or not base.is_file()):
        print(f"ERROR: no existe la base binaria: {base}", file=sys.stderr)
        return 1

    ahk2exe = find_ahk2exe(args.ahk2exe)
    if not ahk2exe:
        print(
            "ERROR: no se encontró Ahk2Exe. Instala AutoHotkey v1 (Compiler) o pasa --ahk2exe.",
            file=sys.stderr,
        )
        return 2

    if args.verbose:
        print(f"Sistema: {'Windows' if _is_windows() else 'No Windows'}")
        print(f"Ahk2Exe: {ahk2exe}")

    output.parent.mkdir(parents=True, exist_ok=True)

    cmd = [ahk2exe, "/in", str(source), "/out", str(output)]
    if icon:
        cmd.extend(["/icon", str(icon)])
    if base:
        cmd.extend(["/bin", str(base)])

    print("Comando:", " ".join(cmd))

    if args.dry_run:
        print("Dry-run: no se ejecutó la compilación.")
        return 0

    try:
        completed = subprocess.run(cmd, check=False)
    except OSError as exc:
        print(f"ERROR: no se pudo ejecutar Ahk2Exe: {exc}", file=sys.stderr)
        return 3

    if completed.returncode != 0:
        print(f"ERROR: Ahk2Exe devolvió código {completed.returncode}", file=sys.stderr)
        return completed.returncode

    if not output.exists():
        print(f"ERROR: no se generó el output esperado: {output}", file=sys.stderr)
        return 4

    size_kb = output.stat().st_size / 1024
    print(f"OK -> {output} ({size_kb:.1f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
