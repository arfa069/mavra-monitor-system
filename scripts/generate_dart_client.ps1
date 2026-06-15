[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Current = (Resolve-Path ".").Path
if ($Current -ne $RepoRoot) {
    throw "Run scripts/generate_dart_client.ps1 from the repository root: $RepoRoot"
}

$FrontendRoot = Join-Path $RepoRoot "frontend"
$BackendRoot = Join-Path $RepoRoot "backend"
$OpenApiJson = Join-Path $FrontendRoot "openapi.json"
$ConfigPath = Join-Path $FrontendRoot "openapi-generator-config.yaml"
$ToolsPath = Join-Path $FrontendRoot "openapitools.json"
$PubspecPath = Join-Path $FrontendRoot "pubspec.yaml"
$OutputPath = Join-Path $FrontendRoot "lib/core/api/generated"
$Wrapper = "@openapitools/openapi-generator-cli@2.38.0"
$GeneratorVersion = "7.23.0"

function Assert-DartGeneratorPins {
    if (!(Test-Path $ConfigPath)) {
        throw "Missing Dart OpenAPI generator config: $ConfigPath"
    }
    if (!(Test-Path $ToolsPath)) {
        throw "Missing OpenAPI generator CLI pin file: $ToolsPath"
    }
    $tools = Get-Content $ToolsPath -Raw | ConvertFrom-Json
    $actualVersion = $tools.'generator-cli'.version
    if ($actualVersion -ne $GeneratorVersion) {
        throw "Expected generator jar $GeneratorVersion, found $actualVersion"
    }
}

function Export-OpenApi {
    Push-Location $BackendRoot
    try {
        uv run --extra dev python ../scripts/export_openapi.py
    }
    finally {
        Pop-Location
    }
}

function Invoke-DartGenerator {
    param([Parameter(Mandatory = $true)][string]$Destination)

    npx $Wrapper generate `
        -g dart-dio `
        -i $OpenApiJson `
        -o $Destination `
        -c $ConfigPath
}

Assert-DartGeneratorPins
Export-OpenApi

if (!(Test-Path $PubspecPath)) {
    if ($Check) {
        Write-Host "frontend/pubspec.yaml not found; Dart generation check is deferred until Task 7 Flutter scaffold."
        exit 0
    }
    throw "frontend/pubspec.yaml not found. Create the Flutter scaffold before generating the Dart client."
}

if ($Check) {
    if (!(Test-Path $OutputPath)) {
        throw "Committed Dart client output is missing: $OutputPath"
    }
    $TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("mavra-dart-client-" + [System.Guid]::NewGuid())
    New-Item -ItemType Directory -Path $TempRoot | Out-Null
    try {
        Invoke-DartGenerator -Destination $TempRoot
        git diff --no-index --exit-code -- $OutputPath $TempRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Dart generated client is out of date."
        }
    }
    finally {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    exit 0
}

if ($Clean -and (Test-Path $OutputPath)) {
    Remove-Item -LiteralPath $OutputPath -Recurse -Force
}

Invoke-DartGenerator -Destination $OutputPath
