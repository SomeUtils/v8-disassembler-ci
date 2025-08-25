Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)

    $Content = Add-LineBelow -Content $Content `
        -Patterns @('class Shell .+', '.*public:\s*$') `
        -Insert @"
  static void LoadBytecode(const v8::FunctionCallbackInfo<v8::Value>& info);
"@

    return $Content
}
