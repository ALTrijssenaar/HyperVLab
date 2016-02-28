#Requires -Version 4.0
<#
.SYNOPSIS
    Determine the available images in a Windows installation medium (iso).

.DESCRIPTION
    Determine the available images in a Windows installation medium (iso).

.NOTES
    Copyright (c) 2016 Jeroen Swart. All rights reserved.
#>
function Get-LabOSImage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw 'The provided path to the installation medium does not exist.'
    }

    try {
        Write-Verbose "Opening ISO '$(Split-Path $Path -Leaf)'..."
        $openIso = Mount-DiskImage -ImagePath $Path -StorageType ISO -PassThru
        $openIso = Get-DiskImage -ImagePath $Path

        $driveLetter = ($openIso | Get-Volume).DriveLetter
        $sourcePath = "$($driveLetter):\sources\install.wim"

        Write-Verbose "Looking for $($sourcePath)..."
        if (-not (Test-Path $sourcePath)) {
            throw 'The specified ISO does not appear to be valid Windows installation media.'
        }

        Write-Verbose 'Extracting available images...'
        $openWim = New-Object WIM2VHD.WimFile $sourcePath
        
        return $openWim.Images | ForEach-Object {
            New-Object PSCustomObject `
                | Add-Member -MemberType NoteProperty -Name ImageName -Value $_.ImageName -PassThru `
                | Add-Member -MemberType NoteProperty -Name ImageIndex -Value $_.ImageIndex -PassThru `
                | Add-Member -MemberType NoteProperty -Name ImageVersion -Value $_.ImageVersion -PassThru
        }
    }
    finally {
        if ($openWim) {
            Write-Verbose 'Closing Windows image...'
            $openWim.Close()
        }
        if ($openIso) {
            Write-Verbose 'Closing ISO...'
            Dismount-DiskImage $Path
        }
    }
}
