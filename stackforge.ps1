$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$StackforgeSh = Join-Path $ScriptDir "stackforge.sh"
$Command = if ($args.Count -gt 0) { $args[0] } else { "help" }
$RemainingArgs = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }
$GitBash = Join-Path $env:ProgramFiles "Git\bin\bash.exe"

if (-not (Test-Path $GitBash)) {
  throw "Git Bash introuvable. Installe Git for Windows, puis relance .\stackforge.ps1 $Command"
}

& $GitBash $StackforgeSh $Command @RemainingArgs
