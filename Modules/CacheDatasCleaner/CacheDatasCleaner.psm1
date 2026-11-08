using namespace System.Collections.Generic;

using module LogHelper
using module ConfirmImpactLevel
using module ProcessUtilityServices
using module FileExtensionDecisionMaker

function CleanCachedDirectories(){
    [CmdletBinding()]
    param(
        [LogHelper] $logHelper,
        [System.Collections.Specialized.OrderedDictionary] $cachedDirectories
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

        $cachedDirectories.GetEnumerator().ForEach({
            $cachedDirectory = "$($_.Value)";
            $cachedDirectoryName = "$($_.Key)";
            $isSuccess = $processUtilityServices.AskForTryToRemoveDirectory($cachedDirectory);
            if($isSuccess -eq $false){
                throw [System.InvalidOperationException]::new("Remove '$cachedDirectoryName' failed")
            }
        });
        
        return $isSucess
    }
}