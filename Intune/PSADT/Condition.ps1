#requires -version 2
<#
.SYNOPSIS
  The script is inspired by a blog article 'https://svdbusse.github.io/SemiAnnualChat/2019/09/14/User-Interactive-Win32-Intune-App-Deployment-with-PSAppDeployToolkit.html' which describes its idea and presents simpler code version.
.DESCRIPTION
  The script is used for conditional deployment option interactive if requires the user's action (to save work and close interrupting processes) 
  or noninteractive if user interaction is not needed to proceed. 
.PARAMETER -DeploymentType
    
        Specifies the deployment type Install|Uninstall|Repair

        Required?                    false
        Position?                    0
        Default value                Install
        Accept pipeline input?       false
        Accept wildcard characters?  false

.PARAMETER -ProcessToCheck
        Specifies the phrase used to search applications

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?

.PARAMETER <CommonParameters>
        This cmdlet supports the common parameters: -Verbose, -Debug,
        -ErrorAction, -ErrorVariable, -WarningAction, -WarningVariable,
        -OutBuffer and -OutVariable. For more information, type
        "get-help about_commonparameters".

.INPUTS
  DeploymentType
.OUTPUTS

.NOTES
  Version:        2.1
  Author:         Karol Kula
  Creation Date:  28.11.2023
  Purpose/Change: Adding the possibility to input more than one process into the ProcessToCheck parameter. 
  
  Version:        2.0
  Author:         Karol Kula
  Creation Date:  17.11.2023
  Purpose/Change: Replacement of ServiceUI.exe with Psexec64.exe. I decided to include logging with Start-Transcript and more details with Write-Output
  
  Version:        1.2
  Author:         Karol Kula
  Creation Date:  11.10.2023
  Purpose/Change: Fix formatting issues and, add string validation to the ProcessToCheck parameter. 
  		  Insert the link reference that inspired me to create this script. 
  
  Version:        1.0
  Author:         Karol Kula
  Creation Date:  11.10.2023
  Purpose/Change: Initial script development
  
.EXAMPLE
  
  powershell.exe -executionpolicy bypass -file .\Invoke64bitPS.ps1 -ScriptName "Condition.ps1" -ArgumentList "-ProcessToCheck 'chrome.exe'"

   -Runs as 64-bit process script Condition.ps1 to check if the process chrome.exe is running to start deploy (install) 

.EXAMPLE

  powershell.exe -executionpolicy bypass -file .\Invoke64bitPS.ps1 -ScriptName "Condition.ps1" -ArgumentList "-DeploymentType Uninstall -ProcessToCheck '7zFM.exe'"

   -Runs as 64-bit process script Condition.ps1 to check if the process 7zFM.exe is running to start deployment (uninstall) 

.EXAMPLE

  powershell.exe -executionpolicy bypass -file .\Invoke64bitPS.ps1  -ScriptName "Condition.ps1" -Arguments "-DeploymentType Uninstall -ProcessToCheck 'Acrobat.exe,AcroRd32.exe'"

   -Runs as 64-bit process script Condition.ps1 to check if the processes Acrobat.exe or AcroRd32.exe are running to start deployment (uninstall) 

#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $true)]
    [String]$ProcessToCheck
)
$DateTimeStamp = $(Get-Date -format '_HH-mm_ddMMyyyy')
Start-Transcript "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Condition-$($ProcessToCheck.Split('.')[0])$DateTimeStamp.log"

if ($ProcessToCheck -match ',') {
    Write-Output "There is more than one process to check"
    $ArrayOfProcesses = @()
    $ArrayOfProcesses += @($ProcessToCheck.Split(','))
}

$ProcessNames = @()

Foreach($item in $ArrayOfProcesses){
    if ($item -match '"') {
        $item = $item.Replace('"', '')
        $ProcessNames += "'" + $item.replace(' ','') + "'"
    }
    Elseif ($item -match "'") {
        $item = $item.Replace("'", '')
        $ProcessNames += "'" + $item.replace(' ','') + "'"
    }
    Else {
        $ProcessNames += "'" + $item.replace(' ','') + "'"
    }
}

Write-Output "Current directory: $PSScriptRoot"
if ($pwd -ne $PSScriptRoot) {
    Set-Location $PSScriptRoot
}
$LoggedOnUser = (Get-WmiObject -Class win32_computersystem).UserName
$Is64bit = [Environment]::Is64BitProcess
Write-Output "Is 64-bit process? $Is64bit"
Write-Output $LoggedOnUser
$DAppExe = Test-Path $PSScriptRoot\Deploy-Application.exe
Write-Output "Is Deploy-Application present? $DAppExe"

$ExplorerSessionID = (Get-Process explorer -IncludeUserName | Where-Object { $_.UserName -eq $LoggedOnUser } |  Select-Object -Last 1).SessionID
Write-Output "Session ID for explorer is: $ExplorerSessionID" 

$targetprocesses = @()
Foreach ($ProcessName in $ProcessNames) {
    $targetprocesses += @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name=$ProcessName" -ErrorAction SilentlyContinue)
}
if ($targetprocesses.Count -eq 0) {
    Try {
        Write-Output "No interrupting process is running. Starting to deploy your application without ServiceUI"
        if ($DeploymentType -ne 'Uninstall' -and $DeploymentType -ne 'Repair') {
	    Write-Output "Trying to start deployment type install with Deploy-Application.exe in NonInteractive mode"
            Start-Process .\Deploy-Application.exe -ArgumentList '-DeployMode NonInteractive' -ErrorAction Stop
        }
        Elseif ($DeploymentType -eq 'Uninstall'){
	    Write-Output "Trying to start deployment type uninstall with Deploy-Application.exe in NonInteractive mode"
            Start-Process .\Deploy-Application.exe -ArgumentList '-DeploymentType Uninstall -DeployMode NonInteractive' -ErrorAction Stop
        }
        Else {
            Write-Output "Trying to start deployment type repair with Deploy-Application.exe in NonInteractive mode"
	    Start-Process .\Deploy-Application.exe -ArgumentList '-DeploymentType Repair -DeployMode NonInteractive' -ErrorAction Stop 
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
}
else {
    Foreach ($targetprocess in $targetprocesses) {
        $ProcessOwner = $targetprocess.GetOwner().User
	      $TargetProcessName = $targetprocess.Name
        Write-output "Interrupting process $TargetProcessName is running by $ProcessOwner,  Starting to deploy your application with Psexec."
    }
    Try {
        if ($DeploymentType -ne 'Uninstall' -and $DeploymentType -ne 'Repair') {
             Write-Output "Trying to start deployment type install with Deploy-Application.exe in Interactive mode"
            .\Psexec64.exe -accepteula -si $ExplorerSessionID $PSScriptRoot\Deploy-Application.exe            
        }
        Elseif ($DeploymentType -eq 'Uninstall') {
            Write-Output "Trying to start deployment type uninstall with Deploy-Application.exe in Interactive mode"
            .\Psexec64.exe -accepteula -si $ExplorerSessionID $PSScriptRoot\Deploy-Application.exe Uninstall          
        }
        Else {
            Write-Output "Trying to start deployment type repair with Deploy-Application.exe in Interactive mode"
            .\Psexec64.exe -accepteula -si $ExplorerSessionID $PSScriptRoot\Deploy-Application.exe Repair          
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
}
Write-Output "Install Exit Code = $LASTEXITCODE"
Stop-Transcript
Exit $LASTEXITCODE
