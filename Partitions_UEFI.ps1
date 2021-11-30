    [Cmdletbinding()]
    Param()

$iso = $PSScriptRoot + 'D:\iso\en_windows_server_2019_updated_jun_2021_x64_dvd_a2a2f782.iso' 
$RefVhdxPath = $PSScriptRoot + '\Reference VHDX\ref2019.vhdx'

Function New-RefVHDX {

    [cmdletbinding()]
    param(  
         [string] $iso = $(throw 'no ISO specified'),
         [string] $RefVhdxPath = $(throw 'no reference disk specified')
         )

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
# Initialize-Disk -Number $VHDDiskNumber -PartitionStyle GPT

# Partitioner via Disk Part
@"
select disk $vhddisknumber
convert gpt
create partition efi size=1024
format quick fs=fat32 label="System"
gpt attributes=0x8000000000000001
set id="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"
assign letter="S"
create partition msr size=50
gpt attributes=0x8000000000000001
create partition primary 
gpt attributes=0x8000000000000001
shrink minimum=1024
format quick fs=ntfs label="Data"
assign letter="W"
create partition primary
format quick fs=ntfs label="Recovery"
assign letter="R"
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
gpt attributes=0x8000000000000001
list volume
exit
"@ | diskpart.exe

# Formaterar volymen
Format-Volume -Confirm:$false 
$VHDVolume = "W"+":"
$SystemPartition = "S:"

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
    BCDBoot.exe $VHDVolume\Windows /s $SystemPartition /f UEFI
    Dismount-DiskImage -ImagePath $ISO
    Dismount-DiskImage -ImagePath $RefVHDXPath
    Get-ChildItem $RefVHDXPath

    # Skriver hur lång tid det tog för att skapa partitionen
    $FinishTime = Get-Date
    $TT = $FinishTime - $StartTime
    Write-Verbose  "Finishing at $FinishTime"
    Write-verbose  "Creating base image took [$($TT.totalminutes.tostring('n2'))] minutes"    
}