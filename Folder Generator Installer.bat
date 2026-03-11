<# :
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content '%~f0') -join [Environment]::NewLine)"
pause
exit /b
#>

<#
.SYNOPSIS
    All-In-One Installer for Project Folder Generator
.DESCRIPTION
    This script contains the main program embedded inside. 
    It installs the script to Documents\FCConfig and creates shortcuts.
.NOTES
    Author: Tye
#>

# --- 1. THE EMBEDDED SCRIPT DATA ---
$embeddedCode = @'
<#
.SYNOPSIS
   Project Organizer - Automated Folder Utility
.NOTES
    Author: Tye (Lead Developer)
    Version: 1.2
    Project: De-Monetization of major companies that extort simple things for money.
#>

$defaultPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
Set-Location $defaultPath

while ($true) {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "                PROJECT FOLDER GENERATOR                  " -ForegroundColor White -BackgroundColor Blue
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host " This script automates folder creation for your Projects. "
    Write-Host " You can type 'exit' at any prompt to close the script.   "
    Write-Host "=========================================================="
    Write-Host "~ Tye" -ForegroundColor Blue 
    
    function Get-Input ($prompt) {
        $val = Read-Host $prompt
        if ($val -eq "exit") { 
            Write-Host "`nExiting script... Have fun with your Project :)" -ForegroundColor Cyan
            exit 
        }
        return $val
    }

    Write-Host "`n================[ PATH SETUP ]=================" -ForegroundColor Magenta
    Write-Host " Current Save Location: $pwd" -ForegroundColor Gray
    Write-Host " 1. Use Default (Desktop)"
    Write-Host " 2. Set Custom Path"
    $pathChoice = Get-Input " Select 1 or 2"

    if ($pathChoice -eq "2") {
        $customPath = Get-Input " Enter the full folder path (e.g., D:\Projects)"
        if (Test-Path $customPath) {
            Set-Location $customPath
        } else {
            Write-Host " Path not found! Reverting to Desktop." -ForegroundColor Red
            Set-Location $defaultPath
            Pause
        }
    }

    Write-Host "`n================[ MAIN FOLDER SETUP ]=================" -ForegroundColor Magenta
    $mainFolderName = Get-Input "Enter the Main Project (Main Folder) Name"
    if (!(Test-Path $mainFolderName)) { New-Item -ItemType Directory $mainFolderName | Out-Null }

    $working = $true
    while ($working) {
        Write-Host "`n  ----------------[ SUB-FOLDER SETUP ]----------------" -ForegroundColor Cyan
        Write-Host "  Active Project: $mainFolderName" -ForegroundColor DarkCyan
        Write-Host "  --- Folder Naming Options ---" -ForegroundColor Cyan
        Write-Host "  1. Pure Numerical (1, 2, 3...)"
        Write-Host "  2. Numerical + Custom Suffix (All at once: 1_PLA, 2_PLA...)"
        Write-Host "  3. Numerical + Custom Suffix (One by one: 1_Fast, 2_Fine...)"
        Write-Host "  4. Custom Prefix + Numerical (All at once: Test_1, Test_2...)"
        Write-Host "  5. Custom Prefix + Numerical (One by one: PLA_1, PETG_2...)"
        Write-Host "  6. Pure Custom Names (One by one)"
        $choice = Get-Input "`n  Select an option (1-6)"

        switch ($choice) {
            "1" {
                $count = Get-Input "  > How many folders?"
                1..$count | ForEach-Object { 
                    $path = Join-Path $mainFolderName $_
                    if (!(Test-Path $path)) { New-Item -ItemType Directory $path | Out-Null }
                }
            }
            "2" {
                $count = Get-Input "  > How many folders?"
                $suffix = Get-Input "  > Enter the suffix for all folders"
                1..$count | ForEach-Object { 
                    $path = Join-Path $mainFolderName "$($_)_$suffix"
                    if (!(Test-Path $path)) { New-Item -ItemType Directory $path | Out-Null }
                }
            }
            "3" {
                $count = Get-Input "  > How many folders?"
                1..$count | ForEach-Object {
                    $suffix = Get-Input "  > Enter suffix for folder $_"
                    $path = Join-Path $mainFolderName "$($_)_$suffix"
                    if (!(Test-Path $path)) { New-Item -ItemType Directory $path | Out-Null }
                }
            }
            "4" {
                $count = Get-Input "  > How many folders?"
                $prefix = Get-Input "  > Enter the prefix for all folders"
                1..$count | ForEach-Object { 
                    $path = Join-Path $mainFolderName "$($prefix)_$_"
                    if (!(Test-Path $path)) { New-Item -ItemType Directory $path | Out-Null }
                }
            }
            "5" {
                $count = Get-Input "  > How many folders?"
                1..$count | ForEach-Object {
                    $prefix = Get-Input "  > Enter prefix for folder $_"
                    $path = Join-Path $mainFolderName "$($prefix)_$_"
                    if (!(Test-Path $path)) { New-Item -ItemType Directory $path | Out-Null }
                }
            }
            "6" {
                while ($true) {
                    $name = Get-Input "  > Enter folder name (or type 'done' to finish)"
                    if ($name -eq "done") { break }
                    $path = Join-Path $mainFolderName $name
                    if (!(Test-Path $path)) { New-Item -ItemType Directory $path | Out-Null }
                }
            }
        }
        Write-Host "`n  [+] Batch created!" -ForegroundColor Green
        $more = Get-Input "  > Do you want to add more folders to THIS project? (yes/no)"
        if ($more -ne "yes" -and $more -ne "y") { $working = $false }
    }

    Write-Host "`n==============================================" -ForegroundColor Magenta
    Write-Host "Success! Opening project folder..." -ForegroundColor Green
    Invoke-Item $mainFolderName
    
    $finalCheck = Get-Input "`nStart a NEW project? (Enter to continue / 'exit' to quit)"
}
'@

# --- 2. INSTALLATION LOGIC ---
$configDir = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "FCConfig"
$destScript = Join-Path $configDir "ProjectFolderGenerator.ps1"
$desktopPath = [Environment]::GetFolderPath("Desktop")

Clear-Host
Write-Host "--- Starting Installation ---" -ForegroundColor Cyan

if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir | Out-Null
    Write-Host "[1/4] Created Config Folder."
}

$embeddedCode | Out-File -FilePath $destScript -Encoding utf8
Unblock-File -Path $destScript
Write-Host "[2/4] Generated Project Script."

$WshShell = New-Object -ComObject WScript.Shell
function Create-Link ($lnkPath) {
    $Shortcut = $WshShell.CreateShortcut($lnkPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File ""$destScript"""
    $Shortcut.WorkingDirectory = $configDir
    $Shortcut.IconLocation = "powershell.exe, 0"
    $Shortcut.Save()
}

Create-Link (Join-Path $desktopPath "Project Folder Generator.lnk")
Write-Host "[3/4] Created Desktop Shortcut."
Create-Link (Join-Path $configDir "Launcher.lnk")
Write-Host "[4/4] Created Config Launcher."

Write-Host "`nDONE! You can now delete this installer file." -ForegroundColor Green

Write-Host "Use the 'Project Folder Generator' icon on your Desktop."
