# GDinputlow

Script AutoHotkey v1 optimizado para entrada de baja latencia en Geometry Dash.

## Archivo principal
- `GDinputlow.ahk`

## Compilar a `.exe` (Windows)

### Opción 1: Python (recomendada)
1. Instala **AutoHotkey v1** con compilador (`Ahk2Exe`).
2. Ejecuta:

```bash
python tools/build_exe.py
```

Opciones útiles:

```bash
# Solo mostrar comando final (sin compilar)
python tools/build_exe.py --dry-run --verbose

# Ruta explícita de Ahk2Exe
python tools/build_exe.py --ahk2exe "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"

# Añadir icono y base binaria personalizada
python tools/build_exe.py --icon assets\gd.ico --base "C:\Program Files\AutoHotkey\AutoHotkeyU64.exe"
```

### Opción 2: PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_exe.ps1
```

Salida esperada:
- `dist/GDinputlow.exe`

## Hotkeys
- `sc11C`: click down / up (solo con GeometryDash activo).
- `F4`: salir.
- `F6`: resetear récord (`records_gd.txt`).
- `F7`: abrir `records_gd.txt`.
