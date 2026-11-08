# 1. 取得 User 與 Machine 的所有變數名稱聯集
$envNames = [Environment]::GetEnvironmentVariables('User').Keys + [Environment]::GetEnvironmentVariables('Machine').Keys | Select-Object -Unique | Sort-Object

# 2. 進行迴圈處理並輸出
$envNames | ForEach-Object {
    $name = $_
    $val = [Environment]::GetEnvironmentVariable($name, 'User')
    if ([string]::IsNullOrEmpty($val)) {
        $val = [Environment]::GetEnvironmentVariable($name, 'Machine')
    }
    
    [PSCustomObject]@{
        Name  = $name
        Value = $val -replace ';', "`n"
    }
} | Format-Table -AutoSize -Wrap