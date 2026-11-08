using module LogHelper
using module ConfirmImpactLevel
using module ProcessUtilityServices

Describe "ProcessUtilityServices Unit Tests" {
    
    BeforeAll {
        $mockLogHelper = [LogHelper]::new("$env:TEMP\test.log")
        
        # 關鍵：建立一個「可變動」的 Mock 物件
        $mockContextObj = New-Object -TypeName PSObject
        # 預設行為
        $mockContextObj | Add-Member -MemberType NoteProperty -Name "MockReturnValue" -Value $true
        # 定義方法呼叫內部屬性，這樣我們只要改屬性值，方法回傳就會變
        $mockContextObj | Add-Member -MemberType ScriptMethod -Name "ShouldProcess" -Value {
            param($t, $n) return $this.MockReturnValue
        }

        [PSContext]::Current = $mockContextObj
    }

    Context "Method: AllowPerformProcess" {
        It "Should return true when ImpactLevel is None" {
            $service = [ProcessUtilityServices]::new(
                [ConfirmImpactLevel]::None, 
                $mockLogHelper
            )
            
            $result = $service.AllowPerformProcess("Target", "Task")
            $result | Should -Be $true
        }

        It "Should return true when ImpactLevel is Low and ShouldProcess returns true" {
            $service = [ProcessUtilityServices]::new(
                [ConfirmImpactLevel]::Low, 
                $mockLogHelper
            )
            
            $result = $service.AllowPerformProcess("Target", "Task")
            $result | Should -Be $true
        }

        It "Should return false when ImpactLevel is High (Default)" {
            # 模擬使用者點選 "否" (ShouldProcess 回傳 $false)
            [PSContext]::Current.MockReturnValue = $false
            $service = [ProcessUtilityServices]::new(
                [ConfirmImpactLevel]::High, 
                $mockLogHelper
            )
            
            $result = $service.AllowPerformProcess("Target", "Task")
            $result | Should -Be $false
        }
    }

    Context "Method: TryToKillProcess" {
        BeforeEach {
            # 模擬 Get-Process 行為 (避免真的殺掉進程)
            Mock Get-Process { return [PSCustomObject]@{ Name = "TestProcess" } } -ModuleName ProcessUtilityServices
            Mock Stop-Process { return $null } -ModuleName ProcessUtilityServices
        }
        It "Should log success when process is killed successfully" {
            # 建立 Mock 實例
            $service = [ProcessUtilityServices]::new(
                [ConfirmImpactLevel]::None, 
                $mockLogHelper
            )

            $result = $service.TryToKillProcess("TestProcess")
            
            $result | Should -Be $true
        }

        It "Should log error and return false when `Get-Process` command does not find any existing processes" {
            Mock Get-Process { throw "Process not found" } -ModuleName ProcessUtilityServices
            $service = [ProcessUtilityServices]::new(
                [ConfirmImpactLevel]::None, 
                $mockLogHelper
            )

            $result = $service.TryToKillProcess("NonExistentProcess")
            
            $result | Should -Be $false
        }

        It "Should log error and return false when `Stop-Process` command failes to kill any existing processes" {
            $service = [ProcessUtilityServices]::new(
                [ConfirmImpactLevel]::None, 
                $mockLogHelper
            )

            Mock Get-Process { return [PSCustomObject]@{ Name = "TestProcess" } } -ModuleName ProcessUtilityServices
            # 模擬 Stop-Process 失敗
            Mock Stop-Process { throw "Access Denied" } -ModuleName ProcessUtilityServices           
    
            $result = $service.TryToKillProcess("TestProcess")
            
            $result | Should -Be $false
        }
    }
}