try {
    # 移除具歧義的 -Output 參數
    # 如果要看詳細資料，大部分版本支援 -Verbose
    Invoke-Pester -Path ".\ProcessUtilityServices.Tests.ps1" -Verbose
} catch {
    Write-Host "偵測到錯誤：" -ForegroundColor Red
    $_ | Format-List -Force
} finally {
    # 解決亂碼問題：改用純英文或確保檔案儲存為 UTF-8 with BOM
    Read-Host "Press any key to exit..."
}