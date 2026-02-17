param(
  [string]$Source = "GDinputlow.ahk",
  [string]$Output = "dist/GDinputlow.exe"
)

$ErrorActionPreference = "Stop"

$ahk2exeCandidates = @(
  "$Env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe",
  "$Env:ProgramFiles(x86)\AutoHotkey\Compiler\Ahk2Exe.exe"
)

$ahk2exe = $ahk2exeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ahk2exe) {
  throw "No se encontró Ahk2Exe. Instala AutoHotkey v1 con el compilador."
}

New-Item -ItemType Directory -Path (Split-Path -Parent $Output) -Force | Out-Null

& $ahk2exe /in $Source /out $Output
if (-not (Test-Path $Output)) {
  throw "La compilación no generó el archivo esperado: $Output"
}

Write-Host "OK -> $Output"
