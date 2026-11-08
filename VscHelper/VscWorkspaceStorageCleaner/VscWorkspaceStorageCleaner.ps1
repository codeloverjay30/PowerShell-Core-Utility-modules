using namespace System.Collections.Generic;

using module LogHelper
using module ConfirmImpactLevel
using module ProcessUtilityServices
using module FileExtensionDecisionMaker
using module TaskCleaner
using module WorkspaceCleaner
function CleanVscWorkspaceStorage(){
    [CmdletBinding()]
    param(
        [LogHelper] $logHelper,
        [System.Collections.Specialized.OrderedDictionary] $processNameMappingTable = [ordered]@{},
        [System.Collections.Specialized.OrderedDictionary] $workspaceStorageMappingTable = [ordered]@{}
    )
    process {
        if($processNameMappingTable.Count -eq 0)
        {
            $processNameMappingTable["VSC"] = "Code";
        }

        if($workspaceStorageMappingTable.Count -eq 0)
        {
            $workspaceStorageMappingTable["VSC Workspace Storage"] = "$env:APPDATA\Code\User\workspaceStorage";
        }
        Wait-Debugger

        $taskResult = & CleanTask -logHelper $logHelper -processNameMappingTable $processNameMappingTable
        Wait-Debugger
        $storageResult = & CleanWorkspaceStorage -logHelper $logHelper -workspaceStorageMappingTable $workspaceStorageMappingTable
        Wait-Debugger
        $isSuccess = $taskResult -and $storageResult
    }
}

$psScriptRoot = $PSScriptRoot
if(-not (Test-Path $psScriptRoot)){
    $psScriptRoot = "D:\workspace\Scripts\VscHelper\VscWorkspaceStorageCleaner"
}
if(-not (Test-Path $psScriptRoot)){
    New-Item "$psScriptRoot" -ItemType "Directory"
}
$fileExtensionDecisionMaker = [FileExtensionDecisionMaker]::new(
    "$psScriptRoot",
    "vsc-workspace-storage",
    [FileExtensionsOptions]::Log
);
$logFile = $fileExtensionDecisionMaker.DecideFileNameByTimeStamp();
$logHelper = [LogHelper]::new($logFile);

CleanVscWorkspaceStorage $logHelper