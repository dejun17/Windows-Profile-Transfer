# User Profile Transfer

# Add the additional user folders you want to copy here
$AdditionalFoldersToCopy = @(
    'Documents',
    'Downloads',
    'Music',
    'Pictures',
    'OtherFolder'
)

$FoldersToCopy = @(
    'Desktop',
    'Videos',
    'Favorites',
    # Microsoft Edge Favorites
    'AppData\Local\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\AC\MicrosoftEdge\User\Default\Favorites',
    # Outlook Signatures
    'AppData\Roaming\Microsoft\Signatures',
    # Adding Taskbar Icons
    'AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar',
    # Google Chrome Favorites
    'AppData\Local\Google\Chrome\User Data\Default'
)

# Ask the user if they want to perform a local transfer
$TransferType = Read-Host -Prompt "Choose transfer type (Local/Remote):"
$TransferToDifferentDrive = $false

if ($TransferType -eq "Local") {
    # For local transfer, ask for a different drive letter
    $DriveLetter = Read-Host -Prompt "Enter the drive letter for local transfer (e.g., D):"
    $DestinationRoot = "$DriveLetter:\Users\$User"
    $TransferToDifferentDrive = $true

    $FromComputer = $null
    while (-not (Test-Connection -ComputerName $FromComputer -Count 2 -Quiet)) {
        $FromComputer = Read-Host -Prompt 'Enter the computer to copy from'
        Write-Warning "$FromComputer is not online. Please enter another computer name."
    }

    $ToComputer = $FromComputer  # Local transfer, set ToComputer to be the same as FromComputer

    $User = $null
    while ((-not (Test-Path -Path "$DriveLetter:\Users\$User" -PathType Container))) {
        $User = Read-Host -Prompt 'Enter the user profile to copy from'
        Write-Warning "$User could not be found on $DriveLetter:\. Please enter another user profile."
    }
} elseif ($TransferType -eq "Remote") {
    $FromComputer = Read-Host -Prompt 'Enter the source computer name'
    $ToComputer = Read-Host -Prompt 'Enter the destination computer name'

    $User = Read-Host -Prompt 'Enter the user profile to copy from'

    $SourceRoot = "\\$FromComputer\c$\Users\$User"
    $DestinationRoot = "\\$ToComputer\c$\Users\$User"
}

# This piece of code actually transfers the profile.
foreach ($Folder in $FoldersToCopy) {
    $Source = Join-Path -Path $SourceRoot -ChildPath $Folder
    $Destination = Join-Path -Path $DestinationRoot -ChildPath $Folder

    if (-not (Test-Path -Path $Source -PathType Container)) {
        Write-Warning "Could not find path`t$Source"
        continue
    }

    robocopy.exe $Source $Destination /E /IS /NP /NFL
}

# If you chose a local transfer and specified a different drive, copy the additional folders
if ($TransferToDifferentDrive -eq $true) {
    foreach ($Folder in $AdditionalFoldersToCopy) {
        $Source = Join-Path -Path $SourceRoot -ChildPath $Folder
        $Destination = Join-Path -Path $DestinationRoot -ChildPath $Folder

        if (-not (Test-Path -Path $Source -PathType Container)) {
            Write-Warning "Could not find path`t$Source"
            continue
        }

        robocopy.exe $Source $Destination /E /IS /NP /NFL
    }
}

# Message to inform about updating registry and environment variables
$Message = @"
To complete the profile transfer, you may need to update the following:
1. Registry: Change the profile path in 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' for the user.
   Example: Update 'ProfileImagePath' to the new profile path, e.g., '$DestinationRoot'.

2. Environment Variables: Check and update any environment variables or shortcuts that point to the old profile path.

Please ensure that these changes are made to reflect the new profile path.

"@
Write-Host $Message

# Ask the user if they want to restart the computer
$RestartComputer = Read-Host -Prompt "Do you want to restart the computer now? (y/n)"
if ($RestartComputer -eq 'y') {
    Restart-Computer
}

Write-Host "Profile transfer completed."
