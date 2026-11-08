# AppiumManager.ps1

class AppiumBootstrapper {
    # 屬性：定義預設路徑與插件
    [string]$AndroidHome = "$env:LOCALAPPDATA\Android\Sdk"
    [string[]]$DefaultPlugins = @("images", "wait-2", "execute-driver")
    [string]$AppiumConfigPath
    [string]$CustomConfigPath

    AppiumBootstrapper() {
        $this.AppiumConfigPath = Join-Path $PSScriptRoot "appium-config.json"
    }

    AppiumBootstrapper([string]$AppiumConfigPath, [string]$CustomConfigPath) {
        $this.AppiumConfigPath = $AppiumConfigPath
        $this.CustomConfigPath = $CustomConfigPath
    }

    # 初始化環境變數
    [void] SetupEnvironment() {
        $env:ANDROID_HOME = $this.AndroidHome
        $env:PATH += ";$this.AndroidHome\platform-tools"
        Write-Host "[Env] 環境變數已設定。" -ForegroundColor Gray
    }

    # 檢查並安裝插件
    [void] EnsurePlugins([string[]]$RequiredPlugins) {
        if ($null -eq $RequiredPlugins) { $RequiredPlugins = $this.DefaultPlugins }
        
        Write-Host "--- 檢查 Appium 插件 ---" -ForegroundColor Cyan
        
        # 取得已安裝清單
        $jsonRaw = appium plugin list --installed --json | Out-String
        $installedData = $jsonRaw | ConvertFrom-Json

        foreach ($plugin in $RequiredPlugins) {
            # 抽離出來的判斷邏輯
            if ($installedData.PSObject.Properties.Name -notcontains $plugin) {
                Write-Host "正在安裝插件: $plugin..." -ForegroundColor Yellow
                appium plugin install $plugin
            } else {
                Write-Host "插件已就緒: $plugin" -ForegroundColor Green
            }
        }
    }

    # # 自動連線手機
    # [void] ConnectDevice() {
    #     讀取 JSON 取得手機 IP
    #     $config = Get-Content $this.CustomConfigPath | ConvertFrom-Json
    #     $targetIp = $config.deviceIp

    #     Write-Host "--- 檢查 ADB 連線狀態 ---" -ForegroundColor Cyan
        
    #     # 檢查是否已連線
    #     $devices = adb devices
    #     if ($devices -notmatch "$($targetIp)\s+device") {
    #         Write-Host "偵測到裝置離線，正在嘗試連線至 $targetIp..." -ForegroundColor Yellow
    #         adb disconnect $targetIp | Out-Null
    #         $result = adb connect $targetIp
    #         if ($result -match "connected") {
    #             Write-Host "連線成功！" -ForegroundColor Green
    #         } else {
    #             Write-Error "連線失敗，請檢查手機無線偵錯是否開啟。"
    #         }
    #     } else {
    #         Write-Host "裝置 $targetIp 已就緒。" -ForegroundColor Green
    #     }
    # }

    # Ensures that at least one usable Android device is available through ADB.
    [void] ConnectDevice() {
        Write-Host "--- 檢查 ADB 連線狀態 ---" -ForegroundColor Cyan

        $deviceLines = @(& adb devices)

        if ($LASTEXITCODE -ne 0) {
            throw "執行 'adb devices' 失敗，ExitCode=$LASTEXITCODE。"
        }

        $readyDevices = @(
            $deviceLines |
            Select-Object -Skip 1 |
            Where-Object {
                $_ -match '^\S+\s+device$'
            }
        )

        if ($readyDevices.Count -gt 0) {
            Write-Host "已偵測到可用 ADB 裝置：" -ForegroundColor Green

            foreach ($device in $readyDevices) {
                Write-Host "  $device"
            }

            return
        }

        if ([string]::IsNullOrWhiteSpace($this.CustomConfigPath)) {
            throw "目前沒有可用的 ADB 裝置，且未提供 CustomConfigPath。"
        }

        if (-not (Test-Path -LiteralPath $this.CustomConfigPath)) {
            throw "找不到 custom config：$($this.CustomConfigPath)"
        }

        try {
            $config = Get-Content `
                -LiteralPath $this.CustomConfigPath `
                -Raw `
                -ErrorAction Stop |
                ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw "讀取 custom config 失敗：$($_.Exception.Message)"
        }

        $targetEndpoint = [string]$config.deviceIp

        if ([string]::IsNullOrWhiteSpace($targetEndpoint)) {
            throw "目前沒有可用的 ADB 裝置，且 custom config 未設定 deviceIp。"
        }

        Write-Host "未偵測到 USB ADB 裝置，嘗試連線至 $targetEndpoint..." `
            -ForegroundColor Yellow

        & adb connect $targetEndpoint | Out-Host

        if ($LASTEXITCODE -ne 0) {
            throw "adb connect '$targetEndpoint' 執行失敗，ExitCode=$LASTEXITCODE。"
        }

        $escapedEndpoint = [regex]::Escape($targetEndpoint)

        $deviceLines = @(& adb devices)

        if ($LASTEXITCODE -ne 0) {
            throw "重新執行 'adb devices' 失敗，ExitCode=$LASTEXITCODE。"
        }

        $connected = @(
            $deviceLines |
            Select-Object -Skip 1 |
            Where-Object {
                $_ -match "^$escapedEndpoint\s+device$"
            }
        )

        if ($connected.Count -eq 0) {
            throw "已執行 adb connect，但 '$targetEndpoint' 仍未處於 device 狀態。"
        }

        Write-Host "裝置 $targetEndpoint 已就緒。" -ForegroundColor Green
    }


    # 確保 Appium Server 正在運行
    [void] StartService() {
        $active = Get-NetTCPConnection -LocalPort 4723 -ErrorAction SilentlyContinue
        if (-not $active) {
            Write-Host "正在啟動 Appium Server (啟用所有插件)..." -ForegroundColor Yellow
            $AppiumArgs = "--config `"$($this.AppiumConfigPath)`" --allow-insecure=uiautomator2:adb_shell"
            # Start-Process "appium" -ArgumentList $AppiumArgs -NoNewWindow   
            Start-Process "cmd.exe" `
                -ArgumentList "/c", "appium $AppiumArgs" `
                -NoNewWindow  
            Start-Sleep -Seconds 8
        } else {
            Write-Host "Appium Server 運行中。" -ForegroundColor Green
        }
    }
}