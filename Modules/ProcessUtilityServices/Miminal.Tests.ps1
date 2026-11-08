using module "..\CommonUtilityServices\LogHelper\LogHelper.psd1"
using module ".\ConfirmImpactLevel.psm1"
using module ".\ProcessUtilityServices.psd1"

Describe "Debugging ProcessUtilityServices" {
    
    # 這裡就是第二步：Mock 注入的程式碼放置處
    BeforeAll {
        # 準備 Mock 物件[cite: 4]
        $mockContextObj = New-Object -TypeName PSObject
        $mockContextObj | Add-Member -MemberType ScriptMethod -Name "ShouldProcess" -Value { 
            param($t, $n) return $true 
        }
        
        # 嘗試對靜態成員賦值，這最容易噴錯[cite: 3, 4]
        [PSContext]::Current = $mockContextObj
        
        # 準備 LogHelper[cite: 4]
        $mockLogHelper = [LogHelper]::new("$env:TEMP\test.log")
    }

    It "Should create the object and run AllowPerformProcess" {
        # 建立實例[cite: 3, 4]
        $service = [ProcessUtilityServices]::new(
            $null, # 這裡先傳 $null 測試是否是因為類型轉換導致崩潰
            [ConfirmImpactLevel]::None, 
            $mockLogHelper
        )
        
        $result = $service.AllowPerformProcess("Target", "Task")
        $result | Should -Be $true
    }

    It "Should create the object and run AllowPerformProcess 2" {
        # 建立實例[cite: 3, 4]
        $service = [ProcessUtilityServices]::new(
            $mockContextObj, # 測試看看傳入這個會不會讓它消失
            [ConfirmImpactLevel]::None, 
            $mockLogHelper
        )
        
        $service | Should -Not -BeNullOrEmpty
    }
}