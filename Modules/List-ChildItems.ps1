$moduleRootPath = $PSScriptRoot

if (![System.IO.Directory]::Exists("$moduleRootPath")) 
{
    $moduleRootPath =  "D:\workspace\Scripts\Modules"
}

Write-Host "moduleRootPath:$moduleRootPath"

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

# 使用 .NET StreamWriter 提高寫入效率
$writer = [System.IO.StreamWriter]::new($logFile, $false) # $false 表示覆蓋檔案

try {
    # 預先抓取所有項目，減少管線切換
	$items = Get-ChildItem -Path "$moduleRootPath" -Recurse | Where-Object { $_.FullName -ne $logFile }

    foreach ($item in $items) {
        $writer.WriteLine("--- file: $($item.FullName) ---")
        
        if (-not $item.PSIsContainer) {
            # 注意：這裡讀取檔案內容依然可能很慢，建議限制讀取大小或過濾副檔名
            $content = [System.IO.File]::ReadAllText($item.FullName)
            $writer.WriteLine($content)
        } else {
            $writer.WriteLine("It is a directory")
        }
        $writer.WriteLine("`n")
    }
}
finally {
    $writer.Close()
    $writer.Dispose()
    Write-Host "Done! Log saved to $logFile"
}