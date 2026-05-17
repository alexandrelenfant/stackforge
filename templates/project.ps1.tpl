$ErrorActionPreference = "Stop"

$InfraDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseEnvFile = Join-Path $InfraDir ".env"
$Command = if ($args.Count -gt 0) { $args[0] } else { "help" }

if (-not (Test-Path $BaseEnvFile)) {
  throw "Fichier .env introuvable : $BaseEnvFile"
}

function Show-Help {
  Write-Host "Available commands:"
  Write-Host "  .\project.ps1 certs  generate development certificates"
  Write-Host "  .\project.ps1 dev    start development environment"
  Write-Host "  .\project.ps1 test   start test environment"
  Write-Host "  .\project.ps1 prod   start production environment"
  Write-Host "  .\project.ps1 down   stop containers"
  Write-Host "  .\project.ps1 logs   show containers logs"
  Write-Host "  .\project.ps1 ps     show containers status"
  Write-Host "  .\project.ps1 help   show this help"
}

function Get-DotenvFiles {
  param([string] $EnvName)

  return @(
    (Join-Path $InfraDir ".env"),
    (Join-Path $InfraDir ".env.$EnvName"),
    (Join-Path $InfraDir ".env.local"),
    (Join-Path $InfraDir ".env.$EnvName.local")
  )
}

function Read-EnvFiles {
  param([string] $EnvName)

  $envValues = @{}

  Get-DotenvFiles $EnvName | ForEach-Object {
    $dotenvFile = $_

    if (-not (Test-Path $dotenvFile)) {
      return
    }

    Get-Content $dotenvFile | ForEach-Object {
      $line = $_.Trim()

      if ($line -eq "" -or $line.StartsWith("#")) {
        return
      }

      $parts = $line.Split("=", 2)

      if ($parts.Count -eq 2) {
        $envValues[$parts[0]] = $parts[1]
      }
    }
  }

  return $envValues
}

function Invoke-Compose {
  param(
    [string] $EnvName,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ComposeArgs
  )

  $envArgs = @()

  Get-DotenvFiles $EnvName | ForEach-Object {
    if (Test-Path $_) {
      $envArgs += @("--env-file", $_)
    }
  }

  docker compose @envArgs -f (Join-Path $InfraDir "compose.yml") @ComposeArgs
}

function Require-Domain {
  param(
    [string] $EnvName,
    [string] $EnvLabel
  )

  $envValues = Read-EnvFiles $EnvName

  if (-not $envValues.ContainsKey("DOMAIN") -or [string]::IsNullOrWhiteSpace($envValues["DOMAIN"])) {
    throw "DOMAIN n'est pas renseigné dans les fichiers dotenv de $EnvLabel. Renseigne un domaine dans .env, .env.local, .env.$EnvName ou .env.$EnvName.local."
  }
}

switch ($Command) {
  "certs" {
    $GitBash = Join-Path $env:ProgramFiles "Git\bin\bash.exe"
    $CertScript = Join-Path $InfraDir "scripts/generate-certs.sh"

    if (-not (Test-Path $GitBash)) {
      throw "Git Bash introuvable. Installe Git for Windows pour lancer la génération de certificats."
    }

    Write-Host "🔐 Generating development certificates..."
    Push-Location $InfraDir
    try {
      & $GitBash $CertScript
    }
    finally {
      Pop-Location
    }
  }
  "dev" {
    Write-Host "🚀 Starting DEV environment..."
    Invoke-Compose "dev" -f (Join-Path $InfraDir "compose.dev.yml") up --build -d
  }
  "test" {
    Write-Host "🚀 Starting TEST environment..."
    Invoke-Compose "test" -f (Join-Path $InfraDir "compose.test.yml") up --build -d
  }
  "prod" {
    Require-Domain "prod" "production"
    Write-Host "🚀 Starting PROD environment..."
    Invoke-Compose "prod" -f (Join-Path $InfraDir "compose.prod.yml") up --build -d
  }
  "down" {
    Write-Host "🛑 Stopping containers..."
    Invoke-Compose "dev" -f (Join-Path $InfraDir "compose.dev.yml") down
    Invoke-Compose "test" -f (Join-Path $InfraDir "compose.test.yml") down
    Invoke-Compose "prod" -f (Join-Path $InfraDir "compose.prod.yml") down
  }
  "logs" {
    Invoke-Compose "dev" logs -f
  }
  "ps" {
    Invoke-Compose "dev" ps
  }
  { $_ -in @("help", "-h", "--help") } {
    Show-Help
  }
  default {
    Write-Error "Unknown command: $Command"
    Show-Help
    exit 1
  }
}
