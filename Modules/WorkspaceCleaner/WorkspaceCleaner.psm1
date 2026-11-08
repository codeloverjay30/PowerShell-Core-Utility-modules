using namespace System.Collections.Generic;

using module LogHelper
using module ConfirmImpactLevel
using module ProcessUtilityServices
using module FileExtensionDecisionMaker

function CleanWorkspaceStorage(){
    [CmdletBinding()]
    param(
        [LogHelper] $logHelper,
        [System.Collections.Specialized.OrderedDictionary] $workspaceStorageMappingTable
    )
    process {
        # 初始化(自定義)PSContext 靜態屬性
        [PSContext]::Current = $PSCmdlet
        if ($null -eq [PSContext]::Current) {
            [PSContext]::Current = New-Object -TypeName PSObject -Property @{
                ShouldProcess = { param($target, $action) return $true } # 預設回傳 true
            }
        }
        $processUtilityServices = [ProcessUtilityServices]::new(
            [ConfirmImpactLevel]::High, 
            $logHelper
        );

        $isSuccess = $processUtilityServices.AskForTryToRemoveDirectory($workspaceStorageMappingTable.Values[0]);
        if($isSuccess -eq $false){
            throw [System.InvalidOperationException]::new("Remove '$workspaceStorageMappingTable.Keys[0]' failed")
        }
        return $isSucess
    }
}