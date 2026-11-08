# 設定模組根目錄
$ModuleRoot = "D:\workspace\Scripts\Modules"

# 確保路徑存在才執行
if (Test-Path $ModuleRoot) {
    $SubDirs = Get-ChildItem -Path $ModuleRoot -Directory
    Write-Host "路徑有: $SubDirs" -ForegroundColor Cyan

    foreach ($dir in $SubDirs) {
        # 檢查該子目錄是否已經存在於 PSModulePath 中
        # 使用 [System.IO.Path]::Combine 或是字串插值
        $targetPath = $dir.FullName
        
        if ($env:PSModulePath -notlike "*$targetPath*") {
            # 將路徑加入環境變數（僅對當前 Session 有效）
            $env:PSModulePath = "$targetPath;$env:PSModulePath"
            Write-Host "已加入路徑: $targetPath" -ForegroundColor Cyan
        }
    }
} else {
    Write-Warning "找不到路徑: $ModuleRoot"
}