Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)

    $Content = Edit-FunctionBody -Content $Content `
        -FunctionName "Local<ObjectTemplate> Shell::CreateGlobalTemplate" `
        -Converter {
        param($Body)
        $Body = Add-BeforeReturn -Body $Body `
            -Insert @"
  global_template->Set(isolate, "loadBytecode",
                       FunctionTemplate::New(isolate, LoadBytecode));
"@
        return $Body
    }

    $disassemble = Join-Path $PSScriptRoot "disassemble.cc"
    $disassemble = Get-Content -Path $disassemble -Raw
    $Content = Add-LineBelow -Content $Content `
        -Patterns @('void Shell::Print\(', '^}$') `
        -Insert $disassemble

    return $Content
}
