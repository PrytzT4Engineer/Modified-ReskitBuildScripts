Function New-RefVHDX {

    [cmdletbinding()]
    param(  
         [string] $iso = $(throw 'no ISO specified'),
         [string] $RefVhdxPath = $(throw 'no reference disk specified')
         )

Import-Module -Name DISM
Mount-DiskImage -ImagePath $ISO
$ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume

# Sätter Drivebokstaven (exempel D:)
$ISODrive = [string]$ISOImage.DriveLetter + ':'

$VMDisk01 = New-VHD -Path $RefVHDXPath -Size 64GB
Mount-DiskImage -ImagePath $RefVHDXPath
$VHDDisk = Get-DiskImage -ImagePath $RefVHDXPath | Get-Disk
$VHDDiskNumber = [string]$VHDDisk.Number

# Partitioner via Disk Part

@"
select disk $VHDDiskNumber
convert gpt
create partition efi size=1024
format quick fs=fat32 label='System'
gpt attributes=0x8000000000000001
set id='c12a7328-f81f-11d2-ba4b-00a0c93ec93b'
assign letter='S'
create partition msr size=50
gpt attributes=0x8000000000000001
Set id='e3c9e316-0b5c-4db8-817d-f92df00215ae'
create partition primary 
gpt attributes=0x8000000000000001
format quick fs=ntfs label='Data'
assign letter='W'
shrink minimum=1024
create partition primary
format quick fs=ntfs label='Recovery'
assign letter='R'
set id='de94bba4-06d1-4d40-a16a-bfd50179d6ac'
gpt attributes=0x8000000000000001
list volume
exit
"@ | diskpart.exe

$VHDVolume = 'W:'
$SystemPartition = 'S:'

$IndexList = Get-WindowsImage -ImagePath $ISODrive\sources\install.wim

$item = $IndexList | Out-GridView -OutputMode Single
$index = $item.ImageIndex


Dism.exe /apply-Image /ImageFile:$ISODrive\Sources\install.wim /index:$Index /ApplyDir:$VHDVolume\

BCDBoot.exe $VHDVolume\Windows /s $SystemPartition /f UEFI
Dismount-DiskImage -ImagePath $ISO
Dismount-DiskImage -ImagePath $RefVHDXPath
Get-ChildItem $RefVHDXPath

}

$iso = 'd:\iso\en_windows_server_2019_updated_jun_2021_x64_dvd_a2a2f782.iso'
$RefVhdxPath = 'd:\build\ref2019.vhdx'

New-RefVHDX -iso $Iso -RefVHDXPath $RefVhdxPath -Verbose