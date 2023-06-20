$Modules = @(
    "AZ",
    "ExchangeOnlineManagement",
    "ImportExcel",
    "Microsoft.Graph",
    "Microsoft.Online.SharePoint.PowerShell",
    "MicrosoftTeams",
    "Microsoft365DSC",
    "PNP.PowerShell"
)

Foreach($Module in $Modules){
    $ModuleVer = $null
    $InstalledVer = $null

    $ModuleVer = (Find-Module $Module).Version
    $InstalledVer = (Get-InstalledModule -name $Module -ErrorAction SilentlyContinue).Version
    
    # Remove old versions
    if($ModuleVer -ne $InstalledVer){
        if($InstalledVer){
            $ModuleInstlPath = ((Get-InstalledModule -name $Module).InstalledLocation).Split($((Find-Module $Module).Version))[0]

            Get-ChildItem -Path $ModuleInstlPath -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force
            Write-Host "All previous version(s) od $Module module have been removed" -ForegroundColor Magenta
        }
    }
    Else{
        Write-Host "Module $Module latest version is installed already" -ForegroundColor Green
        continue
    }

    Try{
        # Install most recent version of module
        Write-Host "Installing $Module version $ModuleVer"
        Install-Module $module -force -ErrorAction Stop
    }Catch{
        Write-Host "Error Installing $module `n : $_ `n `n" -ForegroundColor Red
    }
}
