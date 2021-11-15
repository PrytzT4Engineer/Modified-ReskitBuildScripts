# Variabler
$ISO = 'D:\iso\en_windows_server_2019_updated_jun_2021_x64_dvd_a2a2f782' 
$RefVhdxPath = 'D:\Build\Ref2022.vhdx'

# Startar tidtagning
$StartTime = Get-Date
Write-Verbose "Beginning at $StartTime"
Import-Module -Name DISM
Mount-DiskImage -ImagePath $iso
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume

$VMDisk01 = New-VHD –Path $RefVHDXPath -Size 500GB
Mount-DiskImage -ImagePath $RefVHDXPath
$VHDDisk = Get-DiskImage -ImagePath $RefVHDXPath | Get-Disk
$VHDDiskNumber = [string]$VHDDisk.Number
Initialize-Disk -Number $VHDDiskNumber -PartitionStyle GPT
$VHDDrive = New-Partition -DiskNumber $VHDDiskNumber `
-AssignDriveLetter -Size 500 |

Format-Volume -Confirm:$false
$VHDVolume = [string]$VHDDrive.DriveLetter + ":"

Write-Verbose "Started at [$(Get-Date)]"
Write-Verbose 'THIS WILL TAKE SOME TIME!'
Dism.exe /apply-Image /ImageFile:$ISODrive\Sources\install.wim /index:$Index /ApplyDir:$VHDVolume\
Write-Verbose "Finished at [$(Get-Date)]"

# Finishing touches, skapar Windows Defender på den nya partitionen och dismountar alla variabler
BCDBoot.exe $VHDVolume\Windows /s $VHDVolume /f BIOS
Dismount-DiskImage -ImagePath $ISO
Dismount-DiskImage -ImagePath $RefVHDXPath
Get-ChildItem $RefVHDXPath

# Skriver hur lång tid det tog för att skapa partitionen
$FinishTime = Get-Date
$TT = $FinishTime - $StartTime
Write-Verbose  "Finishing at $FinishTime"
Write-verbose  "Creating base image took [$($TT.totalminutes.tostring('n2'))] minutes"



select disk | where-object {($_.Number -is "0")}

create partition efi size=500
format quick fs=fat32 label="System"
assign letter="S"
create partition msr size=16
create partition primary 
shrink minimum=500
format quick fs=ntfs label="Windows"
assign letter="W"
list volume
exit

Initialize-Disk -Number $VHDDiskNumber -PartitionStyle GPT
$VHDDrive = New-Partition -DiskNumber $VHDDiskNumber `
-DriveLetter S -Size 500 |
Format-Volume -Confirm:$false

# Skapar en partition på 500GB med namnet System och S:
new-partition -disknumber 0 -size 500gb -driveletter S | format-volume -filesystem NTFS -new filesystemlabel System

# Kolla på partitionen
get-partition -disknumber 0

# Ändrar storleken på en partition
get-partition -disknumber 0
get-partition -driveletter S | resize-partition -size XXgb