# 指定你電腦上實際存在的 VS 2026 路徑
$msBuildPath = "D:\Program Files\Microsoft Visual Studio\2026\Community\MSBuild\Current\Bin\MSBuild.exe"
$projectPath = "D:\workspace\developing project (git)\CGSS8-pull-test\CGSSProject\CGSS.Common\CGSS.Common.csproj"
# 驗證執行檔是否存在
if (Test-Path $msBuildPath) {
    Write-Host "成功找到 MSBuild: $msBuildPath" -ForegroundColor Green
    
    # 1. 還原套件 (針對舊版 csproj 必須使用 nuget.exe)
    Write-Host "正在還原 NuGet 套件..." -ForegroundColor Yellow
    nuget restore $projectPath 

    # 2. 執行編譯 (目標 4.7.2)
    Write-Host "正在啟動編譯..." -ForegroundColor Yellow
    & $msBuildPath $projectPath  /t:Build /p:Configuration=Debug /p:Platform="AnyCPU"
} else {
    Write-Error "找不到 MSBuild.exe，請檢查路徑是否正確。"
}