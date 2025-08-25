function Edit-FunctionBody {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$FunctionName,
        [Parameter(Mandatory)][ScriptBlock]$Converter
    )

    $methodPattern = "$FunctionName\s*\([^)]*\)\s*(const\s*)?{"

    $match = [regex]::Match($Content, $methodPattern)
    if (-not $match.Success) {
        Write-Warning "Editing function '$FunctionName' is not found."
        return $Content
    }

    $startIndex = $match.Index + $match.Length - 1
    $braceCount = 1
    $i = $startIndex + 1
    while ($i -lt $Content.Length -and $braceCount -gt 0) {
        if ($Content[$i] -eq '{') { $braceCount++ }
        elseif ($Content[$i] -eq '}') { $braceCount-- }
        $i++
    }
    $endIndex = $i

    $originalBody = $Content.Substring($startIndex + 1, $endIndex - $startIndex - 2).Trim()
    $newBody = & $Converter $originalBody
    $newContent = $Content.Substring(0, $startIndex + 1) + "`n$newBody`n" + $Content.Substring($endIndex - 1)
    return $newContent
}

function Add-BeforeReturn {
    param(
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][string]$Insert
    )

    $lines = $Body -split "`r?`n"
    $newLines = @()

    foreach ($line in $lines) {
        if ($line -match '^\s*return\s+.+;$') {
            $newLines += $Insert
        }
        $newLines += $line
    }

    return ($newLines -join "`n")
}

function Add-LineBelow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string[]]$Patterns,
        [Parameter(Mandatory)][string]$Insert
    )

    $eol = if ($Content -match "`r`n") { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"

    $searchStart = 0
    $lastMatchIndex = -1
    foreach ($pattern in $Patterns) {
        $found = $false
        for ($i = $searchStart; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match $pattern) {
                $lastMatchIndex = $i
                $searchStart = $i + 1
                $found = $true
                break
            }
        }
        if (-not $found) {
            return $Content
        }
    }

    $insertAt = $lastMatchIndex + 1
    $before = if ($lastMatchIndex -ge 0) { $lines[0..$lastMatchIndex] } else { @() }
    $after  = if ($insertAt -lt $lines.Count) { $lines[$insertAt..($lines.Count-1)] } else { @() }
    $insertLines = $Insert -split "`r?`n"

    $newLines = @()
    $newLines += $before
    $newLines += $insertLines
    $newLines += $after

    return ($newLines -join $eol)
}

function Add-LineBefore {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Insert
    )

    $lines = $Content -split "`r?`n"
    $inserted = $false
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        if (-not $inserted -and $line -match $Pattern) {
            $result.Add($Insert)
            $inserted = $true
        }
        $result.Add($line)
    }

    return ($result -join "`r`n")
}

function Set-CommentLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Pattern
    )

    $eol = if ($Content -match "`r`n") { "`r`n" } else { "`n" }
    $lines = $Content -split "`r?`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $Pattern) {
            $lines[$i] = $lines[$i] -replace '^( *)', '${1}// '
            break
        }
    }
    return ($lines -join $eol)
}
