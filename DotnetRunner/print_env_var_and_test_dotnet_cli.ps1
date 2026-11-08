$env:COREHOST_TRACE=1

$script_root = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { "D:\workspace\Scripts\DotnetRunner\" } else { $PSScriptRoot }

# 建立 Log 檔名 (修正語法)
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$log_file_name = Join-Path $script_root "registry-key-helper-${timestamp}.log"

# 定義一個 Helper Function 來同時輸出螢幕與 Log
function Write-Log {
    param([string]$Message)
    Write-Host $Message >> "${log_file_name}" 2>&1
}

Write-Log "Start to run the PowerShell script."

Write-Log "Log檔的完整路徑:${log_file_name}"

Write-Log "環境變數 env:Path的值為:${env:Path}"

Write-Log "環境變數 env:DOTNET_ROOT的值為:${env:DOTNET_ROOT}"

Write-Log "環境變數 env:DOTNET_INSTALL_DIR的值為:${env:DOTNET_INSTALL_DIR}"

Write-Log "環境變數 env:DOTNET_ROOT的值為:${env:DOTNET_ROOT}"

Write-Log "dotnet --list-sdks 這個指令的執行結果如下:"
dotnet --list-sdks >> "${log_file_name}" 2>&1

Write-Log "dotnet --info 這個指令的執行結果如下:"
dotnet --info >> "${log_file_name}" 2>&1

Write-Log "dotnet locals http-cache --clear 這個指令的執行結果如下:"
dotnet locals http-cache --clear >> "${log_file_name}" 2>&1

Write-Log "Bye Bye"

$env:COREHOST_TRACE=0