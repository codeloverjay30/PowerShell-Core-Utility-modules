enum FileExtensionsOptions{
	Log
	Text
	Xml
}

class FileExtensionDecisionMaker{
	[FileExtensionsOptions] $FileExtensionOption = [FileExtensionsOptions]::Log
	[string] $BaseDirectory
	[string] $FileName
	
	[System.Collections.Generic.Dictionary[FileExtensionsOptions,string]] $_FileExtensionMappingTable
	
	FileExtensionDecisionMaker(
		[string] $baseDirectory,
		[string] $filename,
		[FileExtensionsOptions] $option = [FileExtensionsOptions]::Log
	){
		$this.BaseDirectory = $baseDirectory
		$this.FileName = $filename
		$this.FileExtensionOption = $option
		
		#  初始化 Dictionary
        $this._FileExtensionMappingTable = [System.Collections.Generic.Dictionary[FileExtensionsOptions,string]]::new()
        $this._FileExtensionMappingTable.Add([FileExtensionsOptions]::Log, "log")
        $this._FileExtensionMappingTable.Add([FileExtensionsOptions]::Text, "txt")
        $this._FileExtensionMappingTable.Add([FileExtensionsOptions]::Xml, "xml")
	}

	[string] DecideFileNameByTimeStamp(){
		$fileExtType = ""
		$this.TryGetFileExtensionType([ref] $fileExtType)
		## 日期格式為:
		# yy:四位數年
		# MM:月 (兩位數，若不足則前補零)
		# dd:當月的第幾天(兩位數，若不足則前補零)
		# hh: 小時 (兩位數，若不足則前補零)
		## mm: 分鐘 (兩位數，若不足則前補零)
		## ss: 秒鐘 (兩位數，若不足則前補零)
		$timestamp = [System.DateTime]::Now.ToString("yyMMddhhmmss")
		## 檔案格式為:
		# Join-Path 目錄 檔案名稱.副檔名
		# 其中，檔案名稱為`原本檔名`-`日期`(詳見日期格式的說明)
		$fullFilePath = [System.IO.Path]::Combine($this.BaseDirectory,"$($this.FileName)-${timestamp}.${fileExtType}")
		return $fullFilePath
	}
	
	[void] TryGetFileExtensionType([ref] $fileExtensionType){
		$null = $this._FileExtensionMappingTable.TryGetValue($this.FileExtensionOption,[ref]$fileExtensionType.Value);
	}
}