using module "..\CommonUtilityServices\LogHelper\LogHelper.psd1"
using module ".\ConfirmImpactLevel.psm1"
using module ".\ProcessUtilityServices.psd1"

Describe "ProcessUtilityServices - TryToRemoveDirectory" {
    BeforeAll {
        # 建立 Mock 的 PSContext 與相關物件
        $script:mockContext = [PSCustomObject]@{
            ShouldProcess = { return $true }
        }
        [PSContext]::Current = $script:mockContext
        [PSContext]::ConfirmPreference = [System.Management.Automation.ConfirmImpact]::High
        
        $script:testDir = Join-Path $PSScriptRoot "TestTempDir"
    }

    BeforeEach {
        # 每次測試前重置 Mock 狀態
        Mock Test-Path { return $true }
        Mock Remove-Item { return $null }
        $script:logHelper = [LogHelper]::new("$env:TEMP\test.log")
        [PSContext]::Current = $script:mockContext
        $script:service = [ProcessUtilityServices]::new([ConfirmImpactLevel]::High, $script:logHelper)
    }

    AfterAll {
        # 清理靜態變數，避免影響其他測試
        [PSContext]::Current = $null
    }

    Context "當目錄存在時" {
        It "應該成功刪除目錄並記錄成功訊息" {
            # Arrange
            Mock Test-Path { return $true } -ModuleName ProcessUtilityServices
            Mock Remove-Item { return $null } -ModuleName ProcessUtilityServices

            # Act
            $result = $script:service.TryToRemoveDirectory($script:testDir)

            # Assert
            $result | Should -Be $true
        }

        It "如果 Remove-Item 發生例外，應該回傳 $false 並記錄錯誤" {
            # Arrange
            Mock Test-Path { return $true } -ModuleName ProcessUtilityServices
            Mock Remove-Item { throw "Permission Denied" } -ModuleName ProcessUtilityServices

            # Act
            $result = $script:service.TryToRemoveDirectory($script:testDir)

            # Assert
            $result | Should -Be $false
        }
    }

    Context "當目錄不存在時" {
        It "不應該執行刪除動作，並記錄錯誤訊息" {
            # Arrange
            Mock Test-Path { return $false } -ModuleName ProcessUtilityServices

            # Act
            $result = $script:service.TryToRemoveDirectory($script:testDir)

            # Assert
            $result | Should -Be $false
        }
    }
}