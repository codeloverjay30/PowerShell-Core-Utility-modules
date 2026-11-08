# 載入所有子模組
$moduleBasePath = $PSScriptRoot
if(-not (Test-Path $moduleBasePath)){
    $moduleBasePath = "D:\workspace\Scripts\Modules\CommonUtilityServices"
    Write-Host "moduleBasePath is set to:$moduleBasePath"
}
Write-Host "moduleBasePath:$moduleBasePath"

$importedModulePath = Join-Path $moduleBasePath "FileExtensionDecisionMaker\FileExtensionDecisionMaker.psd1"
Write-Host "importedModulePath:$importedModulePath"

Import-Module $importedModulePath

$importedModulePath = Join-Path $moduleBasePath "LogHelper\LogHelper.psd1"
Write-Host "importedModulePath:$importedModulePath"

Import-Module $importedModulePath