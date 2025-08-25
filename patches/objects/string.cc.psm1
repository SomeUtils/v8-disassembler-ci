Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)

    $Content = Edit-FunctionBody -Content $Content `
        -FunctionName "void String::StringShortPrint" `
        -Converter {
        param($Body)
        $ifCondition = "len > kMaxShortPrintLength"
        $Body = Set-CommentLine -Content $Body `
            -Pattern $ifCondition
        $Body = Add-LineBelow -Content $Body `
            -Patterns @($ifCondition) `
            -Insert "  /*"
        $Body = Add-LineBelow -Content $Body `
            -Patterns @($ifCondition, '}') `
            -Insert "  */"
        return $Body
    }

    return $Content
}
