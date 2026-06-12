param(
    [switch]$SkipDocker,
    [switch]$SkipTerraform
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Invoke-Pytest {
    python -m pytest -q
    if ($LASTEXITCODE -ne 0) {
        throw "Python tests failed with exit code $LASTEXITCODE."
    }
}

function Invoke-TerraformFmt {
    terraform -chdir=terraform fmt -check
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform formatting check failed with exit code $LASTEXITCODE."
    }
}

function Invoke-TerraformValidation {
    terraform -chdir=terraform init -backend=false
    $initExit = $LASTEXITCODE

    if ($initExit -eq 0) {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $windowsValidateOutput = terraform -chdir=terraform validate 2>&1
        $validateExit = $LASTEXITCODE
        $ErrorActionPreference = $previousErrorActionPreference

        if ($validateExit -eq 0) {
            $windowsValidateOutput
            return
        }
    }
    else {
        $validateExit = $initExit
    }

    Write-Host "Windows Terraform validation failed with exit code $validateExit; trying WSL Terraform..."

    $linuxRepo = ConvertTo-WslPath $repoRoot

    $command = "cd '$linuxRepo' && if [ -x `"`$HOME/.local/bin/terraform`" ]; then `"`$HOME/.local/bin/terraform`" -chdir=terraform init -backend=false && `"`$HOME/.local/bin/terraform`" -chdir=terraform validate; else terraform -chdir=terraform init -backend=false && terraform -chdir=terraform validate; fi"
    & wsl.exe bash -lc $command
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform validation failed in WSL."
    }
}

function ConvertTo-WslPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsPath
    )

    if ($WindowsPath -notmatch "^([A-Za-z]):\\(.*)$") {
        throw "Cannot convert path to WSL format: $WindowsPath"
    }

    $drive = $Matches[1].ToLowerInvariant()
    $path = $Matches[2] -replace "\\", "/"
    return "/mnt/$drive/$path"
}

function Invoke-DockerBuild {
    $dockerConfig = Join-Path $repoRoot ".docker-tmp"
    New-Item -ItemType Directory -Force $dockerConfig | Out-Null
    $env:DOCKER_CONFIG = $dockerConfig

    docker build -t medcare-dashboard:local .
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed with exit code $LASTEXITCODE. Make sure Docker Desktop is running and this shell can access the Docker engine."
    }
}

Write-Host "Running Python tests..."
Invoke-Pytest

if (-not $SkipTerraform) {
    Write-Host "Checking Terraform formatting..."
    Invoke-TerraformFmt

    Write-Host "Validating Terraform..."
    Invoke-TerraformValidation
}

if (-not $SkipDocker) {
    Write-Host "Building Docker image..."
    Invoke-DockerBuild
}

Write-Host "Local verification complete."
