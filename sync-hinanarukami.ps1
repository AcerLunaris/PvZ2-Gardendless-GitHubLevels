param(
    [string]$Source = 'C:\Users\admin\Downloads\PvZGE custom levels\My Levels',
    [string]$Destination = (Join-Path $PSScriptRoot 'hinanarukami')
)

$ErrorActionPreference = 'Stop'

$excludedDirectoryNames = @(
    'Custom LODs',
    'Pinata Party',
    'Random Universe',
    "Penny's Pursuit"
)

if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "Source directory not found: $Source"
}

if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

function Remove-Json5Comments {
    param([Parameter(Mandatory)][string]$Text)

    $builder = [System.Text.StringBuilder]::new($Text.Length)
    $quote = [char]0
    $inLineComment = $false
    $inBlockComment = $false

    for ($i = 0; $i -lt $Text.Length; $i++) {
        $ch = $Text[$i]
        $next = if ($i + 1 -lt $Text.Length) { $Text[$i + 1] } else { [char]0 }

        if ($inLineComment) {
            if ($ch -eq "`r" -or $ch -eq "`n") {
                $inLineComment = $false
                [void]$builder.Append($ch)
            } else {
                [void]$builder.Append(' ')
            }
            continue
        }

        if ($inBlockComment) {
            if ($ch -eq '*' -and $next -eq '/') {
                [void]$builder.Append('  ')
                $i++
                $inBlockComment = $false
            } else {
                [void]$builder.Append($(if ($ch -eq "`r" -or $ch -eq "`n") { $ch } else { ' ' }))
            }
            continue
        }

        if ($quote -ne [char]0) {
            [void]$builder.Append($ch)
            if ($ch -eq '\' -and $i + 1 -lt $Text.Length) {
                $i++
                [void]$builder.Append($Text[$i])
            } elseif ($ch -eq $quote) {
                $quote = [char]0
            }
            continue
        }

        if ($ch -eq '"' -or $ch -eq "'") {
            $quote = $ch
            [void]$builder.Append($ch)
        } elseif ($ch -eq '/' -and $next -eq '/') {
            [void]$builder.Append('  ')
            $i++
            $inLineComment = $true
        } elseif ($ch -eq '/' -and $next -eq '*') {
            [void]$builder.Append('  ')
            $i++
            $inBlockComment = $true
        } else {
            [void]$builder.Append($ch)
        }
    }

    if ($inBlockComment) {
        throw 'Unterminated block comment in JSON5 input.'
    }

    return $builder.ToString()
}

function Remove-JsonTrailingCommas {
    param([Parameter(Mandatory)][string]$Text)

    $builder = [System.Text.StringBuilder]::new($Text.Length)
    $quote = [char]0

    for ($i = 0; $i -lt $Text.Length; $i++) {
        $ch = $Text[$i]

        if ($quote -ne [char]0) {
            [void]$builder.Append($ch)
            if ($ch -eq '\' -and $i + 1 -lt $Text.Length) {
                $i++
                [void]$builder.Append($Text[$i])
            } elseif ($ch -eq $quote) {
                $quote = [char]0
            }
            continue
        }

        if ($ch -eq '"' -or $ch -eq "'") {
            $quote = $ch
            [void]$builder.Append($ch)
            continue
        }

        if ($ch -eq ',') {
            $lookahead = $i + 1
            while ($lookahead -lt $Text.Length -and [char]::IsWhiteSpace($Text[$lookahead])) {
                $lookahead++
            }
            if ($lookahead -lt $Text.Length -and ($Text[$lookahead] -eq '}' -or $Text[$lookahead] -eq ']')) {
                continue
            }
        }

        [void]$builder.Append($ch)
    }

    return $builder.ToString()
}

function Copy-LevelFiles {
    param(
        [Parameter(Mandatory)][string]$CurrentSource,
        [Parameter(Mandatory)][string]$CurrentDestination
    )

    $sourceFiles = @(Get-ChildItem -LiteralPath $CurrentSource -File -Force | Where-Object {
        $_.Extension -ieq '.json' -or $_.Extension -ieq '.json5'
    })
    $outputNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($file in $sourceFiles) {
        $outputName = if ($file.Extension -ieq '.json5') {
            [System.IO.Path]::ChangeExtension($file.Name, '.json')
        } else {
            $file.Name
        }
        if (-not $outputNames.Add($outputName)) {
            throw "Multiple source files map to '$outputName' in '$CurrentSource'. Resolve the .json/.json5 name collision before syncing."
        }
    }

    foreach ($file in $sourceFiles) {
        $extension = $file.Extension.ToLowerInvariant()
        $targetName = if ($extension -eq '.json5') {
            [System.IO.Path]::ChangeExtension($file.Name, '.json')
        } else {
            $file.Name
        }
        if (-not (Test-Path -LiteralPath $CurrentDestination -PathType Container)) {
            New-Item -ItemType Directory -Path $CurrentDestination -Force | Out-Null
        }
        $targetPath = Join-Path $CurrentDestination $targetName

        if ($extension -eq '.json') {
            Copy-Item -LiteralPath $file.FullName -Destination $targetPath -Force
        } else {
            $text = [System.IO.File]::ReadAllText($file.FullName)
            $json = Remove-Json5Comments -Text $text
            $json = Remove-JsonTrailingCommas -Text $json

            try {
                $null = ConvertFrom-Json -InputObject $json -ErrorAction Stop
            } catch {
                throw "Could not convert '$($file.FullName)' to strict JSON after removing comments and trailing commas: $($_.Exception.Message)"
            }

            [System.IO.File]::WriteAllText($targetPath, $json, [System.Text.UTF8Encoding]::new($false))
        }
    }

    foreach ($directory in Get-ChildItem -LiteralPath $CurrentSource -Directory -Force) {
        if ($excludedDirectoryNames -contains $directory.Name) {
            continue
        }

        $childDestination = Join-Path $CurrentDestination $directory.Name
        Copy-LevelFiles -CurrentSource $directory.FullName -CurrentDestination $childDestination
    }
}

Copy-LevelFiles -CurrentSource (Resolve-Path -LiteralPath $Source).Path -CurrentDestination (Resolve-Path -LiteralPath $Destination).Path
Write-Host "Sync complete: $Source -> $Destination"
