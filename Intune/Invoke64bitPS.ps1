#requires -version 5
<#
.SYNOPSIS
    This script helps to run PowerShell in 64-bit mode from Intune Management Extension 32-bit process during deployments from Intune (mostly Win32Apps)
.DESCRIPTION
    Script 
.PARAMETER ScriptName
    ScriptName is mandatory parameter points path to the script desired to be executed in PowerShell 64bit console
.PARAMETER Arguments
    If script have ability to ingest some arguments this parameter allows to parse them to executed script
.INPUTS
    $ScriptName is mandatory parameter points path to the script desired to be executed in PowerShell 64bit console. 
.OUTPUTS
    Next version will contain some form of log
.NOTES
  Version:        1.0
  Author:         cquresphere
  Creation Date:  28.06.2023
  Purpose/Change: Initial script development
  
.EXAMPLE
  PowerShell.exe -Executionpolicy Bypass -file .\Invoke64bitPS.ps1 -ScriptName uninstall.ps1

  PowerShell.exe -Executionpolicy Bypass -file .\Invoke64bitPS.ps1 -ScriptName install.ps1 -Arguments "/i /qn APIToken=1234567890"  
#>

param(
        [Parameter(Mandatory)]
        [string]$ScriptName,
        [Parameter()]
        [string]$Arguments
    )

If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        foreach($key in $MyInvocation.BoundParameters.keys)
        {
            switch($MyInvocation.BoundParameters[$key].GetType().Name)
            {
                "SwitchParameter" {if($MyInvocation.BoundParameters[$key].IsPresent) { $argsString += "-$key " } }
                "String"          { $argsString += "-$key `"$($MyInvocation.BoundParameters[$key])`" " }
                "Int32"           { $argsString += "-$key $($MyInvocation.BoundParameters[$key]) " }
                "Boolean"         { $argsString += "-$key `$$($MyInvocation.BoundParameters[$key]) " }
            }
        }
        Start-Process -FilePath "$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -ArgumentList "-File `"$($PSScriptRoot)\$ScriptName`" $($Arguments)" -Wait -NoNewWindow
    }
    Catch {
        Throw "Failed to start 64-bit PowerShell"
    }
    Exit
}
