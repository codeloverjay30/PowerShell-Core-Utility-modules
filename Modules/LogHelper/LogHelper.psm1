class LogHelper{
	[string]$FileName
	
	LogHelper([string]$fileName){
		$this.FileName = $fileName
	}
	
    hidden [void] InternalLog(
		[string]$level, 
		[string]$message, 
		[string]$color
	){
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $formattedMsg = "[$timestamp] [$level] $message"
        
        $this.Log($formattedMsg,$color)
    }

    ### 列出輸出訊息 

	[void] Log(
		[string]$message,
		[string]$color = "White"
	){
		Write-Host $message -ForegroundColor $color
        $message | Out-File -FilePath $this.FileName -Append -Encoding utf8  # log message 
	}
	
    ### 列出有關Info輸出訊息 
	[void] Info([string]$message) {
        $this.Info($message, "Cyan")
    }
	
    ### 列出有關Info輸出訊息 
	[void] Info([string]$message,[string]$color) {
        $this.InternalLog("INFO", $message, $color)
    }
	
    ### 在任務開始後，立馬列出有關任務已經開始的輸出訊息 
	[void] StartInfo([string]$message) {
        $this.StartInfo($message, "Gray")
    }
	
    ### 在任務開始後，立馬列出有關任務已經開始的輸出訊息 
	[void] StartInfo([string]$message,[string]$color) {
        $this.InternalLog("START", $message, $color)
    }

    ### 在任務成功後，立馬列出有關任務已經成功的輸出訊息
    [void] Success([string]$message) {
        $this.InternalLog("SUCCESS", $message, "Green")
    }
	
    ### 在任務成功後，立馬列出有關任務執行完畢的輸出訊息
	[void] Done([string]$message) {
        $this.InternalLog("DONE", $message, "Green")
    }

    ### 在任務直接被執行時，立馬列出有關任務發生警告的輸出訊息
    [void] Warning([string]$message) {
        $this.InternalLog("WARN", $message, "Yellow")
    }

    ### 在任務直接被執行時，立馬列出有關任務發生異常的輸出訊息
    [void] Error(
        [System.Exception]$ex,
        [string]$message
    ){
        $errorMessage = "$ex.Message"
        $message = "$message. With error message: $errorMessage"
        $this.Error($message);
    }

    ### 在任務直接被執行時，立馬列出有關任務發生異常的輸出訊息
    [void] Error([string]$message) {
        $this.InternalLog("FAIL", $message, "Red")
    }
	
    ### 用串流將日誌書出出
	[void] LogStream([ScriptBlock]$script) {
        # redirect error message to standard output
        & $script 2>&1 | ForEach-Object {
        $line = $_.ToString()
            Write-Host $line -ForegroundColor Gray
            $line | Out-File -FilePath $this.FileName -Append -Encoding utf8 # log message using stream
        }
    }
}