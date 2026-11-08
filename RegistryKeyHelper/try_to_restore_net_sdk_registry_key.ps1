Write-Host "Start to run the PowerShell script."

$env:COREHOST_TRACE=1

$script_root= $PSScriptRoot

if([string]::IsNullOrWhiteSpace($script_root)){
    Write-Host "無法正確地存取腳本位置，或者並非以腳本的狀態執行。"
    $default_script_directory = "D:\workspace\Scripts\RegistryKeyHelper\"
    $script_root = "${default_script_directory}"
    Write-Host "script_root被設定為預設位置: ${script_root}"
}

$dateTime_now = [DateTime]::Now

$log_file_name = [System.IO.Path]::Combine($script_root,"registry-key-helper-$($dateTime_now.ToString('yyyyMMddHHmmss')).log")
Write-Host "Log檔的完整路徑:${log_file_name}" >> "${log_file_name}" 2>&1 

Write-Host "Let's go!" >> "${log_file_name}" 2>&1 

# 1. 建立 64 位元 .NET 的核心註冊表項 (這是我之前刪掉的那一個)
$registryPath = "HKLM:\SOFTWARE\dotnet\Setup\InstalledVersions\x64"
if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
    Write-Host "新增完一個有關 x64 .NET Core的Registry Key(這是我之前刪掉的那一個): ${registryPath}" >> "${log_file_name}" 2>&1 
}
Set-ItemProperty -Path $registryPath -Name "InstallLocation" -Value "D:\DevTools\dotnet\"

Write-Host "已經將一個有關 x64 .NET Core的Registry Key(這是我之前刪掉的那一個)取名為InstallLocation且將其直設為: D:\DevTools\dotnet\" >> "${log_file_name}" 2>&1 

# 2. 針對 .NET 10 預覽版，手動指定 SDK 搜尋基底
$sdkRegPath = "HKLM:\SOFTWARE\Microsoft\NET\Sdk\10.0.103"
if (!(Test-Path $sdkRegPath)) {
    New-Item -Path $sdkRegPath -Force
    Write-Host "新增完一個有關 .NET SDK的Registry Key: ${sdkRegPath}" >> "${log_file_name}" 2>&1 
}
Set-ItemProperty -Path $sdkRegPath -Name "InstallLocation" -Value "D:\DevTools\dotnet\sdk\10.0.103\"

Write-Host "已經將一個有關 .NET SDK的Registry Key取名為InstallLocation且將其直設為: D:\DevTools\dotnet\sdk\10.0.103\" >> "${log_file_name}" 2>&1 

# 3. 確保 MSBuild 能找到 D 槽的 SDK (這對 WASM 很重要)
$msBuildReg = "HKLM:\SOFTWARE\Microsoft\MSBuild\Sdks"
if (!(Test-Path $msBuildReg)) {
    New-Item -Path $msBuildReg -Force
    Write-Host "新增完一個有關 MSBuild的Registry Key: ${msBuildReg}" >> "${log_file_name}" 2>&1
}

Write-Host "已經確保MSBuild能找到D槽的SDK(這對 WASM 很重要)其值為${msBuildReg}" >> "${log_file_name}" 2>&1 

Write-Host "Bye Bye" >> "${log_file_name}" 2>&1 

$env:COREHOST_TRACE=0