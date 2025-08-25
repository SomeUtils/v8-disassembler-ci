param (
    [switch]$Restore
)

$patchesRoot = Join-Path $PSScriptRoot "patches"
$sourceRoot = Join-Path $PSScriptRoot "v8\src"

Get-ChildItem -Path $patchesRoot -Recurse -Filter "*.psm1" |
Where-Object { $_.DirectoryName -ne $patchesRoot } |
ForEach-Object {
    $modulePath = $_.FullName
    $sourcePathRelative = $_.FullName.Substring($patchesRoot.Length + 1)
    $sourcePathRelative = [System.IO.Path]::ChangeExtension($sourcePathRelative, $null)
    $sourcePathRelative = $sourcePathRelative.Substring(0, $sourcePathRelative.Length - 1)
    $sourcePath = Join-Path $sourceRoot $sourcePathRelative

    $backupPath = "$sourcePath.bak"
    if ($Restore)
    {
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $sourcePath -Force
            Remove-Item -Path $backupPath -Force
            Write-Host "Restored '$sourcePathRelative'."
        } else {
            Write-Warning "Backup file '$backupPath' does not exist for source '$sourcePath'."
        }
    }
    else
    {
        if (Test-Path $backupPath)
        {
            Write-Warning "Source file '$sourcePath' has already patched."
        }
        elseif (Test-Path $sourcePath)
        {
            Copy-Item -Path $sourcePath -Destination $backupPath -Force

            Import-Module $modulePath -Force
            $content = Get-Content $sourcePath -Raw
            $content = Patch $content
            Set-Content -Path $sourcePath -Value $content

            Write-Host "Patched '$sourcePathRelative'."
        }
        else
        {
            Write-Warning "Source file '$sourcePath' does not exist for patch '$modulePath'."
        }
    }
}
