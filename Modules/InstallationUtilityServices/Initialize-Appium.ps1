. "$PSScriptRoot\AppiumManager.ps1"

$isInExperimental = $true
$packagesChildPath = "";
if($isInExperimental -eq $true){
    $packagesChildPath = "experiments";
}
else
{
    $packagesChildPath = "modules";
}

$appiumConfigPath = "D:\workspace\utility_packages\experiments\Scrawler\Phone\AndroidApp\GamesScrawler\OmniAppium.Engine\OmniAppiumDemo\appium.config.json"
$customConfigPath = "D:\workspace\utility_packages\experiments\Scrawler\Phone\AndroidApp\GamesScrawler\OmniAppium.Engine\OmniAppiumDemo\custom-config.json"

# $appiumConfigPath = "D:\workspace\utility packages\$packagesChildPath\Scrawler\Phone\AndroidApp\GamesScrawler\OmniAppium.Engine\OmniAppiumDemo\appium.config.json"
# $customConfigPath = "D:\workspace\utility packages\$packagesChildPath\Scrawler\Phone\AndroidApp\GamesScrawler\OmniAppium.Engine\OmniAppiumDemo\custom-config.json"

$appium = [AppiumBootstrapper]::new($appiumConfigPath, $customConfigPath)
$appium.SetupEnvironment()
$appium.ConnectDevice()
$appium.EnsurePlugins(@("images", "wait-2", "execute-driver"))
$appium.StartService()