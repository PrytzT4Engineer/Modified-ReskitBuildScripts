# Variabler (ändra path)
$ISO = 'D:\iso\en_windows_server_2019_updated_jun_2021_x64_dvd_a2a2f782.iso' 
$RefVhdxPath = 'D:\Build\Ref2022.vhdx'

# Startar tidtagning
$StartTime = Get-Date
Write-Verbose "Beginning at $StartTime"
Import-Module -Name DISM
Mount-DiskImage -ImagePath $ISO
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume

# Sätter Drivebokstaven (exempel D:)
$ISODrive = [string]$ISOImage.DriveLetter + ":"

$VMDisk01 = New-VHD –Path $RefVHDXPath -Size 64GB
Write-Verbose "Created VHDX File [$($vmdisk01.path)]"
Mount-DiskImage -ImagePath $RefVHDXPath
$VHDDisk = Get-DiskImage -ImagePath $RefVHDXPath | Get-Disk
$VHDDiskNumber = [string]$VHDDisk.Number
Initialize-Disk -Number $VHDDiskNumber -PartitionStyle GPT

# Partitioner via Disk Part
@"
Select disk $VHDDiskNumber
Convert GPT
Create partition efi size=550MB
Format FS=FAT32 quick label="System"
Assign letter="S"
Create partition MSR size=120MB
Set id="{e3c9e316-0b5c-4db8-817d-f92df00215ae}" 
GPT attributes=0x8000000000000001
Create partition primary
Shrink minimum=1GB
Format fs=ntfs quick label="Windows"
Assign letter="W"
Set id="{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}"
GPT attributes=0x8000000000000001
Create partition primary
Format fs=ntfs quick label="Recovery"
Assign letter="R"
Set id="{de94bba4-06d1-4d40-a16a-bfd50179d6ac}"
GPT attributes=0x8000000000000001
List volume
Exit
"@ | diskpart.exe | Out-Null

# MSR
#New-Partition -DiskNumber $VHDDiskNumber `
#-Size 120MB -GptType "{e3c9e316-0b5c-4db8-817d-f92df00215ae}" 

# Datavolym
#$VHDDrive = New-Partition -DiskNumber $VHDDiskNumber `
#-AssignDriveLetter -UseMaximumSize -GptType "{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}" # Kör shrink

# Recovery
#New-Partition -DiskNumber $VHDDiskNumber `
#-UseMaximumSize -GptType "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}" |

# Formaterar volymen
Format-Volume -Confirm:$false 
$VHDVolume = "W:" # Formatera System, Datavolym och Recovery (använd pipes |)

# Hämtar Windows versionerna
$IndexList = Get-WindowsImage -ImagePath $ISODrive\sources\install.wim
Write-Verbose "$($indexList.count) images found"

# Visar Windows versioner (Home, Professional, Standard Server)
$item = $IndexList | Out-GridView -OutputMode Single
$index = $item.ImageIndex

# Tar tiden för DISM:en
Write-Verbose "Started at [$(Get-Date)]"
Write-Verbose 'THIS WILL TAKE SOME TIME!'
Dism.exe /apply-Image /ImageFile:$ISODrive\Sources\install.wim /index:$Index /ApplyDir:$VHDVolume\
Write-Verbose "Finished at [$(Get-Date)]"

# Finishing touches, installerar firmware för UEFI
BCDBoot.exe $VHDVolume\Windows /s $VHDVolume /f UEFI
Dismount-DiskImage -ImagePath $ISO
Dismount-DiskImage -ImagePath $RefVHDXPath
Get-ChildItem $RefVHDXPath

# Skriver hur lång tid det tog för att skapa partitionen
$FinishTime = Get-Date
$TT = $FinishTime - $StartTime
Write-Verbose  "Finishing at $FinishTime"
Write-verbose  "Creating base image took [$($TT.totalminutes.tostring('n2'))] minutes"
