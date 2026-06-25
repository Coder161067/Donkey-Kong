param(
    [switch]$Clean
)

$dasmUrl  = "https://github.com/dasm-assembler/dasm/releases/download/v2.20.17/dasm-v2.20.17-windows.zip"
$dasmZip  = "$env:TEMP\dasm.zip"
$dasmDir  = "$env:TEMP\dasm"
$dasmExe  = "$dasmDir\dasm.exe"

# Install DASM if not present
if (!(Test-Path $dasmExe)) {
    Write-Host "Downloading DASM..."
    Invoke-WebRequest -Uri $dasmUrl -OutFile $dasmZip
    Expand-Archive -Path $dasmZip -DestinationPath $dasmDir -Force
    Remove-Item $dasmZip
}

# Clean
if ($Clean -and (Test-Path "dk2600.bin")) {
    Remove-Item "dk2600.bin", "dk2600.lst", "dk2600.sym" -ErrorAction SilentlyContinue
}

if ($Clean) { return }

# Build
Write-Host "Assembling dk2600.asm..."
& $dasmExe dk2600.asm -f3 -o"dk2600.bin" -l"dk2600.lst" -s"dk2600.sym"
if ($LASTEXITCODE -eq 0) {
    $len = (Get-Item dk2600.bin).Length
    Write-Host "Done! ROM: dk2600.bin ($len bytes)"
    Copy-Item dk2600.bin dk2600.a26 -Force
} else {
    Write-Host "Assembly failed!" -ForegroundColor Red
}
