$startPath = "D:\workspace\LearningNotes\CSharp\Examples\Ex1\Ex1-1"
$endPath = "D:\workspace\LearningNotes\CSharp"

# 確保路徑格式一致
$current = Get-Item $startPath
$root = Get-Item $endPath

$pathList = New-Object System.Collections.Generic.List[string]

# 向上追溯直到到達目標父目錄
while ($current.FullName -ne $root.Parent.FullName) {
    $pathList.Add($current.FullName)
    if ($current.FullName -eq $root.FullName) { break }
    $current = $current.Parent
}

# 遍歷路徑並列出每個目錄下的直接子項目及其內容
foreach ($path in $pathList) {
    Write-Host "`n==========================================" -ForegroundColor Yellow
    Write-Host "Checking Directory: $path" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Yellow
    
    $items = Get-ChildItem -Path $path -Depth 0
    
    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            Write-Host " [Directory] : $($item.Name)" -ForegroundColor Green
        } else {
            Write-Host " [File]      : $($item.Name)" -ForegroundColor White
            Write-Host " --- Content Start ---" -ForegroundColor Gray
            # 讀取檔案內容並加上縮排以便閱讀
            Get-Content -Path $item.FullName -ErrorAction SilentlyContinue | ForEach-Object { "   $_" }
            Write-Host " --- Content End ---" -ForegroundColor Gray
        }
    }
}