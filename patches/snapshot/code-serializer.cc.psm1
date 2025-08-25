Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)

    $Content = Edit-FunctionBody -Content $Content `
        -FunctionName "SerializedCodeSanityCheckResult SerializedCodeData::SanityCheck" `
        -Converter {
        param($Body)
        return "    return SerializedCodeSanityCheckResult::kSuccess;"
    }

    $Content = Edit-FunctionBody -Content $Content `
        -FunctionName "SerializedCodeSanityCheckResult SerializedCodeData::SanityCheckWithoutSource" `
        -Converter {
        param($Body)
        return "    return SerializedCodeSanityCheckResult::kSuccess;"
    }

    $Content = Edit-FunctionBody -Content $Content `
        -FunctionName ".+<SharedFunctionInfo> CodeSerializer::Deserialize" `
        -Converter {
        param($Body)
        $Body = Add-LineBelow -Content $Body `
            -Patterns @('\[Deserializing failed\]', '\s*}$') `
            -Insert @"
  std::cout << "\nStart SharedFunctionInfo\n";
  result->SharedFunctionInfoPrint(std::cout);
  std::cout << "\nEnd SharedFunctionInfo\n";
  std::cout << std::flush;
"@
        return $Body
    }

    return $Content
}
