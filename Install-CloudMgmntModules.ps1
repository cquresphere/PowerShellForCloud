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

$PackageProviderNames = (Get-PackageProvider).Name
if($PackageProviderNames -notcontains 'NuGet'){
    Install-PackageProvider -Name NuGet -minimumVersion 2.8.5.201 -Force
}

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
        # Install the most recent version of the module
        Write-Host "Installing $Module version $ModuleVer"
        Install-Module -Name $module -force -ErrorAction Stop
    }
    Catch{
        Write-Host "Error Installing $module `n : $_ `n `n" -ForegroundColor Red
        $global:Error[0].Exception.GetType().FullName
        $global:Error[0]
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $CallAPI = Invoke-WebRequest 'https://www.powershellgallery.com/api/v2'
        if($($CallAPI.StatusCode) -ne 200){
            Write-Host 'Check your network connection. Confirm that your firewall does not block the powershell.exe and the ieexec.exe' -ForegroundColor Red
            throw
        }
        Set-ExecutionPolicy RemoteSigned -Force

        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        try{
            Install-Module $Module -Force -AllowClobber -ErrorAction Stop
        }
        catch{
            $global:Error[0].Exception.GetType().FullName
            # Install module
            Install-Module $Module -Force -AllowClobber -ErrorAction Stop -SkipPublisherCheck
        }
    }
}
