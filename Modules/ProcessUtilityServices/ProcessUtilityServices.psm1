using module LogHelper 
using module ConfirmImpactLevel
class PSContext 
{
	static [object] $Current
	static [System.Management.Automation.ConfirmImpact] $ConfirmPreference
}
class ProcessUtilityServices
{
	[LogHelper] $_logHelper
	[ConfirmImpactLevel] $_confirmImpactLevel = [ConfirmImpactLevel]::High
	# [object] $_context
	ProcessUtilityServices(
		# [object] $context,
		[ConfirmImpactLevel] $confirmImpactLevel,
		[LogHelper] $logHelper
	)
	{
		$this._logHelper = $logHelper
		# $this._context = $context
		$this._confirmImpactLevel = $confirmImpactLevel
	}

	[bool] AllowPerformProcess(
		[string] $targetName,
		[string] $taskName
	)
	{
		if($this._confirmImpactLevel -eq [ConfirmImpactLevel]::None)
		{
			return $true
		}
		
		if(
			($this._confirmImpactLevel -eq [ConfirmImpactLevel]::Low -or 
			$this._confirmImpactLevel -eq [ConfirmImpactLevel]::Medium) -and 
			$this._confirmImpactLevel -ge [PSContext]::ConfirmPreference -and # 注意：大於等於請用 -ge
			[PSContext]::Current.ShouldProcess($targetName, $taskName)
		)
		{
			return $true
		}

		if (
			$this._confirmImpactLevel -eq [ConfirmImpactLevel]::High -and 
			[PSContext]::Current.ShouldProcess($targetName, $taskName)
		)
		{
			return $true
		}

		return $false
	}

	[void] PerformProcess(
		[string] $targetName,
		[string] $taskName,
		[scriptblock] $block,
		[object] $name,    # 接收名稱
		[object] $service  # 接收實例
	)
	{
		if($this.AllowPerformProcess($targetName,$taskName))
		{
			# 將兩個參數包成陣列傳給 Invoke
			$params = @($name, $service)
			$block.Invoke($params)
		}
	}

	[void] AskForTryingToKillProcess(
    	[string] $processName
	)
	{
		# 改用明確的 ScriptBlock 並捕捉 $this
		$action = { 
			param($name,$service) 
			# 如果 $name 是陣列，就取第一個元素；否則直接使用
			$realName = if ($name -is [array]) { $name[0] } else { $name }
			$service.TryToKillProcess($realName)
		};

		$this.PerformProcess(
			$processName,
			"kill the processes",
			$action,
			$processName,
			$this
		);
	}

	[bool] TryToKillProcess(
		[string] $processName
	)
	{
		try {
			$procs = Get-Process -Name $processName -ErrorAction SilentlyContinue
			if ($null -eq $procs) {
            	$this._logHelper.Success("No $processName processes found.");
            	return $true;
        	}
			$procs | Stop-Process -Force -ErrorAction Stop
			$this._logHelper.Success("Success to kill the $processName process");
			return $true;
		}
		catch {
			$this._logHelper.Error("Failed to kill the $processName process")
			return $false;
		}
	}

	[void] AskForTryToRemoveDirectory(
    	[string] $directory
	)
	{
		# 改用明確的 ScriptBlock 並捕捉 $this
		$action = { 
			param($name,$service) 
			# 如果 $name 是陣列，就取第一個元素；否則直接使用
    		$realName = if ($name -is [array]) { $name[0] } else { $name }
    		$service.TryToRemoveDirectory($realName)
		};

		$this.PerformProcess(
			$directory,
			"remove all items under $directory",
			$action,
			$directory,
			$this
		);
	}

	[bool] TryToRemoveDirectory(
		[string] $directory
	)
	{
		try {
			if([System.String]::IsNullOrWhiteSpace($directory)){
				$this._logHelper.Error("The directory $directory can neither be null nor empty string nor whitespace");
				return $false;
			}
			if(-not (Test-Path $directory)){
				$this._logHelper.Success("The directory $directory does not exist");
				return $true;
			}
			Remove-Item -Path "$directory" -Recurse -Force
			$this._logHelper.Success("Success to remove all items under $directory");
			return $true;
		}
		catch {
			$this._logHelper.Error("Failed to remove all items under $directory");
			return $false;
		}
	}
}