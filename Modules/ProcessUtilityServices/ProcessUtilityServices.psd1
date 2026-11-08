@{
    # 這是模組的主入口，載入清單時會自動執行此檔案
    RootModule = 'ProcessUtilityServices.psm1'

    ModuleVersion = '1.0.0.0'

    RequiredModules = @(
        'LogHelper'
    )
}