$scriptRootPath = "D:\workspace\Scripts"

$logFile = Join-Path "$scriptRootPath" "file_sturcture.txt" 

Write-Host "logFile:$logFile"

if (![System.IO.File]::Exists("$logFile")) 
{
    New-Item -Path "$logFile" -ItemType "File"
	Write-Host "Success create the log file named $logFile"
}else{
	Clear-Content -Path "$logFile"
	Write-Host "Success clear the log file named $logFile"
}

# 1. 載入 DLL (需指向你編譯出的路徑)
$dllPath = "D:\workspace\MyCommonDll\IOOperationUtilityServices\IOOperationUtilityServices\IOOperationUtilityServices.dll"
$abstractionDll = "D:\workspace\MyCommonDll\IOOperationUtilityServices\IOOperationUtilityServices\System.IO.Abstractions.dll"
[Reflection.Assembly]::LoadFrom($abstractionDll)
[Reflection.Assembly]::LoadFrom($dllPath)

# 2. 手動實例化 (因無 DI 容器，需依序注入)
$fileSystem = [System.IO.Abstractions.FileSystem]::new()
$directoryService = [IOOperationUtilityServices.DirectoryUtilityService]::new($fileSystem, $null) # 暫時傳 null
$fileService = [IOOperationUtilityServices.FileUtilityService]::new($fileSystem, $directoryService)

# 修正 DirectoryService 的循環依賴 (如果有需要)
$directoryServiceField = $directoryService.GetType().GetField("_fileUtilityService", [System.Reflection.BindingFlags]::NonPublic | [System.Reflection.BindingFlags]::Instance)
$directoryServiceField.SetValue($directoryService, $fileService)

# 3. 執行邏輯
$scriptRootPath = "D:\workspace\Scripts"
$logFile = Join-Path "$scriptRootPath" "file_structure.txt"

# 使用你的 Service 建立或清空檔案[cite: 3, 4]
$fileService.CreateOrClearFile($logFile)

$writer = [System.IO.StreamWriter]::new($logFile, $false)

try {
    # 使用你的 Service 列舉子項[cite: 1, 2]
    $items = $directoryService.EnumerateChildren($scriptRootPath)

    foreach ($itemPath in $items) {
        if ($itemPath -eq $logFile) { continue }
        
        $writer.WriteLine("--- file: $itemPath ---")
        
        if ($directoryService.IsDirectory($itemPath)) {[cite: 1]
            $writer.WriteLine("It is a directory")
        } else {
            $content = [System.IO.File]::ReadAllText($itemPath)
            $writer.WriteLine($content)
        }
        $writer.WriteLine("`n")
    }
}
finally {
    $writer.Close()
    Write-Host "Done! Log saved to $logFile"
}