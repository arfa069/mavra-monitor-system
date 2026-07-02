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
        if ($LASTEXITCODE -ne 0) {
            throw "OpenAPI export failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

function Remove-DartPackageVolatileFiles {
    param([Parameter(Mandatory = $true)][string]$Destination)

    @(".dart_tool", "build") | ForEach-Object {
        $path = Join-Path $Destination $_
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath (Join-Path $Destination "pubspec.lock") -Force -ErrorAction SilentlyContinue
}

function Invoke-DartGenerator {
    param([Parameter(Mandatory = $true)][string]$Destination)

    npx $Wrapper `
        --openapitools $ToolsPath `
        generate `
        -g dart-dio `
        -i $OpenApiJson `
        -o $Destination `
        -c $ConfigPath `
        --global-property apiDocs=false,modelDocs=false,apiTests=false,modelTests=false
    if ($LASTEXITCODE -ne 0) {
        throw "Dart OpenAPI generation failed with exit code $LASTEXITCODE"
    }
}

function Normalize-DartPackagePubspec {
    param([Parameter(Mandatory = $true)][string]$Destination)

    $GeneratedPubspecPath = Join-Path $Destination "pubspec.yaml"
    if (!(Test-Path $GeneratedPubspecPath)) {
        throw "Generated Dart package pubspec is missing: $GeneratedPubspecPath"
    }
    $content = Get-Content $GeneratedPubspecPath -Raw
    $content = $content -replace "sdk: '>=2\.18\.0 <4\.0\.0'", "sdk: '>=3.12.0 <4.0.0'"
    $content = $content -replace "built_value_generator: '>=8\.4\.0 <9\.0\.0'", "built_value_generator: 8.12.5"
    $content = $content -replace "build_runner: any", "build_runner: 2.15.0"
    if ($content -notmatch "dependency_overrides:") {
        $content = $content.TrimEnd() + "`n`ndependency_overrides:`n  dart_style: 3.1.8`n"
    }
    Set-Content -LiteralPath $GeneratedPubspecPath -Value $content -NoNewline
}

function Normalize-DartGeneratedSources {
    param([Parameter(Mandatory = $true)][string]$Destination)

    Get-ChildItem -Path (Join-Path $Destination "lib") -Recurse -Filter "*.dart" | ForEach-Object {
        $path = $_.FullName
        $content = Get-Content $path -Raw
        $normalized = $content -replace "abstract class (\w+Mixin) = Object with (_\$\w+Mixin);", "abstract class `$1 implements `$2 {}"
        if ($normalized -ne $content) {
            Set-Content -LiteralPath $path -Value $normalized -NoNewline
        }
    }
}

function Normalize-DartGeneratedReadme {
    param([Parameter(Mandatory = $true)][string]$Destination)

    $ReadmePath = Join-Path $Destination "README.md"
    if (!(Test-Path $ReadmePath)) {
        return
    }

    $normalizedLines = @()
    foreach ($line in @(Get-Content $ReadmePath)) {
        $normalizedLines += $line.TrimEnd()
    }
    while (($normalizedLines.Count -gt 0) -and ($normalizedLines[$normalizedLines.Count - 1] -eq "")) {
        if ($normalizedLines.Count -eq 1) {
            $normalizedLines = @()
        } else {
            $normalizedLines = @($normalizedLines[0..($normalizedLines.Count - 2)])
        }
    }

    $content = ""
    if ($normalizedLines.Count -gt 0) {
        $content = [string]::Join("`n", $normalizedLines) + "`n"
    }
    Set-Content -LiteralPath $ReadmePath -Value $content -NoNewline
}

function Normalize-OpenApiGeneratorMetadata {
    param([Parameter(Mandatory = $true)][string]$Destination)

    $IgnorePath = Join-Path $Destination ".openapi-generator-ignore"
    $FilesPath = Join-Path $Destination ".openapi-generator/FILES"
    if ((Test-Path $IgnorePath) -and (Test-Path $FilesPath)) {
        $files = Get-Content $FilesPath
        if ($files -notcontains ".openapi-generator-ignore") {
            $files = @($files)
            if ($files.Count -gt 1) {
                $files = @($files[0]) + ".openapi-generator-ignore" + $files[1..($files.Count - 1)]
            } else {
                $files = @($files[0], ".openapi-generator-ignore")
            }
            Set-Content -LiteralPath $FilesPath -Value ([string]::Join("`n", $files) + "`n") -NoNewline
        }
    }
}

function Invoke-DartPackageBuild {
    param([Parameter(Mandatory = $true)][string]$Destination)

    Push-Location $Destination
    try {
        dart pub get
        if ($LASTEXITCODE -ne 0) {
            throw "dart pub get failed with exit code $LASTEXITCODE"
        }

        dart run build_runner build
        if ($LASTEXITCODE -ne 0) {
            throw "Dart build_runner failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }

    Remove-DartPackageVolatileFiles -Destination $Destination
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
        Normalize-DartPackagePubspec -Destination $TempRoot
        Normalize-DartGeneratedSources -Destination $TempRoot
        Normalize-DartGeneratedReadme -Destination $TempRoot
        Normalize-OpenApiGeneratorMetadata -Destination $TempRoot
        Invoke-DartPackageBuild -Destination $TempRoot
        Remove-DartPackageVolatileFiles -Destination $OutputPath
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
Normalize-DartPackagePubspec -Destination $OutputPath
Normalize-DartGeneratedSources -Destination $OutputPath
Normalize-DartGeneratedReadme -Destination $OutputPath
Normalize-OpenApiGeneratorMetadata -Destination $OutputPath
Invoke-DartPackageBuild -Destination $OutputPath
