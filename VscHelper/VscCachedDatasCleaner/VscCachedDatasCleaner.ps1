using namespace System.Collections.Generic;

using module LogHelper
using module ConfirmImpactLevel
using module ProcessUtilityServices
using module FileExtensionDecisionMaker
using module TaskCleaner
using module WorkspaceCleaner
function CleanVscCachedDatas(){
    [CmdletBinding()]
    param(
        [LogHelper] $logHelper,
        [System.Collections.Specialized.OrderedDictionary] $processNameMappingTable = [ordered]@{},
        [System.Collections.Specialized.OrderedDictionary] $cachedDirectories = [ordered]@{}
    )
    process {
        if($processNameMappingTable.Count -eq 0)
        {
            $processNameMappingTable["VSC"] = "Code";
        }

        if($cachedDirectories.Count -eq 0)
        {
            $cachedDirectories["VSC CachedData"] = "$env:APPDATA\Code\Cache";
        }
        Wait-Debugger

        $taskResult = & CleanTask -logHelper $logHelper -processNameMappingTable $processNameMappingTable
        Wait-Debugger
        $storageResult = & CleanCachedDirectories -logHelper $logHelper -cachedDirectories $cachedDirectories
        Wait-Debugger
        $isSuccess = $taskResult -and $storageResult
    }
}

$psScriptRoot = $PSScriptRoot
if(-not (Test-Path $psScriptRoot)){
    $psScriptRoot = "D:\workspace\Scripts\VscHelper\VscCachedDatasCleaner"
}
if(-not (Test-Path $psScriptRoot)){
    New-Item "$psScriptRoot" -ItemType "Directory"
}
$fileExtensionDecisionMaker = [FileExtensionDecisionMaker]::new(
    "$psScriptRoot",
    "vsc-cached-data",
    [FileExtensionsOptions]::Log
);
$logFile = $fileExtensionDecisionMaker.DecideFileNameByTimeStamp();
$logHelper = [LogHelper]::new($logFile);

CleanVscCachedDatas $logHelper