if ( -not (Test-Path -Path HKU:\)) {
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
}

$UsersSIDs = (Get-ChildItem -Path "HKU:\").PSChildName | Where-Object { ($_ -ne ".DEFAULT") -and ($_ -ne "S-1-5-18") -and ($_ -ne "S-1-5-19") -and ($_ -ne "S-1-5-20") -and ($_ -notlike "*_Classes") } 

Foreach ($UsersSID in $UsersSIDs) {
    $RegPath = "HKU:\\" + $UsersSID + "\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Google Chrome"
    
    if(Test-Path -Path  $RegPath){
      $UninstallStr = Get-ItemPropertyValue -Path $RegPath -Name "UninstallString"
      $UnistallPath = $UninstallStr.Split(" ")[0]
      $UnistallArgs = "--uninstall --channel=stable --force-uninstall --verbose-logging"
      
      try {
        Start-Process $UnistallPath -ArgumentList $UnistallArgs -Wait -ErrorAction Stop
      }
      catch {
        Write-Output $Error[0]
      }
    }
    Else{
      continue
    }    
}
