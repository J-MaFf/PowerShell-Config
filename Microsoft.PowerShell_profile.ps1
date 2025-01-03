# Dependencies: oh-my-posh, 1Password CLI, winget-update.ps1, Chocolatey

#  --------------------------------------------------------------Aliases------------------------------------------------------------
# Alias for output file path
Set-Alias -Name output -Value 'C:\Users\jmaffiola\Documents\output\output.txt'  # output -> output.txt file path

# Alias for winget-update script
Set-Alias -Name winget-update -Value winget-update.ps1

# ---------------------------------------------------------------Functions-----------------------------------------------------------
# Function to change directory to Scripts
function Scripts {
  Set-Location -Path 'C:\Users\jmaffiola\Documents\Scripts'
}

# Function to change directory to user profile
function Home {
  Set-Location -Path $Env:USERPROFILE
}

# Function to open a new PowerShell 7 terminal as administrator
function Admin {
  Start-Process wt -ArgumentList '-p "PowerShell 7" pwsh' -Verb RunAs
}

# Function to restart the terminal, optionally as administrator
function Restart-Terminal {
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if ($isAdmin) {
    Start-Process wt -ArgumentList '-p "PowerShell 7" pwsh' -Verb RunAs
  }
  else {
    Start-Process wt -ArgumentList '-p "PowerShell 7" pwsh'
  }
  exit
}

#---------------------------------------------------------------SSH Servers-----------------------------------------------------------

<#
  Just a tip for future reference: if you want to use the private key in OpenSSH format, you can add ?ssh-format=openssh to the end of the URL.
#>

<#
.SYNOPSIS
  Connects to the JCH BDC Via SSH and opens a new PowerShell window.
.DESCRIPTION
  This function establishes a connection to the JCH BDC. It uses the private key stored
  in 1Password to authenticate the user. Once verified, it opens a new PowerShell window.
.EXAMPLE
  PS C:\> Connect-JCH
  This example shows how to use the Connect-JCH function to connect to the JCH service.
#>
function Connect-JCH {
  try {
    $privateKeyContent = 'op://Employee/JCH BDC SSH Key/private key?ssh-format=openssh' | op inject 
    if (-not $privateKeyContent) {
      Write-Error 'Failed to read the private key from 1Password.'
      return
    }
    $tempKeyPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), 'id_ed25519')
    Set-Content -Path $tempKeyPath -Value $privateKeyContent -Force

    # Restrict file permissions to the current user
    $acl = Get-Acl $tempKeyPath
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$(whoami)", 'FullControl', 'Allow')
    $acl.SetAccessRule($rule)
    Set-Acl $tempKeyPath $acl

    Write-Host 'Connecting to JCH...'
    ssh -i $tempKeyPath admin-jmaffiola@10.70.1.1
  }
  catch {
    Write-Error 'Failed to connect to JCH.'
  }
  finally {
    Remove-Item -Path $tempKeyPath -Force
    Write-Host 'Connection to JCH closed.'
  }
}

# ---------------------------------------------------------------Other---------------------------------------------------------------

# Import Chocolatey profile if it exists
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Enable 1Password command completion
op completion powershell | Out-String | Invoke-Expression

# Initialize oh-my-posh with the easy-term theme
#oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\clean-detailed.omp.json" | Invoke-Expression # clean-detailed theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\easy-term.omp.json" | Invoke-Expression # easy-term theme