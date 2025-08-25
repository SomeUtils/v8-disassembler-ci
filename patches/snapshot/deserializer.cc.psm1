Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)
    
    $deserializerSignature = "Deserializer<IsolateT>::Deserializer"
    $Content = Add-LineBelow -Content $Content `
        -Patterns @($deserializerSignature, '#endif') `
        -Insert "  /*"
    $Content = Add-LineBelow -Content $Content `
        -Patterns @($deserializerSignature, 'CHECK_EQ') `
        -Insert "  */"

    return $Content
}
