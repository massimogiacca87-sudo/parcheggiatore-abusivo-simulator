# Lancia una foto (o una prova) di tools/ sul PC del capo, con la finestra.
#   powershell -ExecutionPolicy Bypass -File tools\win\foto.ps1 foto_hud_misure 240
# Come tools/sh/foto.sh: copia project.godot, infila l'autoload, lancia
# Godot 4.3, e rimette TUTTO a posto anche se va storto. L'uscita va in
# _claude_tmp\grafica\out_<nome>.txt, le foto dove dice la prova (OUT).
param(
    [Parameter(Mandatory = $true)][string]$Nome,
    [int]$Secondi = 240
)
$ErrorActionPreference = "Stop"
$progetto = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$radice = Split-Path -Parent (Split-Path -Parent $progetto)
$godot = "C:\Users\Max\AppData\Local\Temp\godot43\Godot_v4.3-stable_win64_console.exe"
$tmp = Join-Path $radice "_claude_tmp\grafica"
New-Item -ItemType Directory -Force $tmp | Out-Null
$pg = Join-Path $progetto "project.godot"
$bak = Join-Path $tmp "project.godot.bak"
$script = Join-Path $progetto "scripts\_$Nome.gd"
$uscita = Join-Path $tmp "out_$Nome.txt"
Copy-Item $pg $bak -Force
Copy-Item (Join-Path $progetto "tools\$Nome.gd") $script -Force
try {
    $testo = [IO.File]::ReadAllText($pg)
    $vecchio = 'SoundManager="*res://scripts/autoload/sound_manager.gd"'
    $nuovo = $vecchio + "`nFoto=`"*res://scripts/_$Nome.gd`""
    [IO.File]::WriteAllText($pg, $testo.Replace($vecchio, $nuovo))
    if (-not $env:OUT) { $env:OUT = $tmp }
    $env:DEBUG_SIM = "1"
    $p = Start-Process -FilePath $godot -ArgumentList @("--path", "`"$progetto`"", "--resolution", "1280x720") `
        -RedirectStandardOutput $uscita -RedirectStandardError "$uscita.err" -PassThru -NoNewWindow
    if (-not $p.WaitForExit($Secondi * 1000)) {
        $p.Kill()
        Add-Content $uscita "=== TIMEOUT ==="
    }
}
finally {
    Copy-Item $bak $pg -Force
    Remove-Item $script -Force -ErrorAction SilentlyContinue
    Remove-Item "$script.uid" -Force -ErrorAction SilentlyContinue
}
Get-Content $uscita | Select-String -Pattern 'SCRIPT ERROR|Parse Error|STORTA|storte|foto:|riga|giocatore|schermo|TIMEOUT|dopo' |
    ForEach-Object { $_.Line }
