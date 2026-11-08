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

# 遍歷路徑並列出每個目錄下的直接子項目
foreach ($path in $pathList) {
    Write-Host "`n--- Checking Directory: $path ---" -ForegroundColor Cyan
    Get-ChildItem -Path $path -Depth 0 | Select-Object Name, @{Name="Type"; Expression={$_.PSIsContainer ? "Directory" : "File"}}
}