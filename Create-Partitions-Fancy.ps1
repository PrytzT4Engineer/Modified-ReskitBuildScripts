# This script is considered Fancy because it uses the "verbose" commands and is thus more user-friendly

[Cmdletbinding()]
Param()


#defining needed paths for installation
###################################################################################################
#make sure to change these paths if necessary

#path to ISO image windows server 2019
$iso = $PSScriptRoot + '\en_windows_server_2019_updated_jun_2021_x64_dvd_a2a2f782.iso'

#path to VHDX
$RefVhdxPath = $PSScriptRoot + '\ref2019.vhdx'

###################################################################################################

# Step 1 Create Virtual Hard Drive (VHDX) that will be used as common installation media for all VMs
Function New-RefVHDX {

    [cmdletbinding()]
    param(
        #Error message if ISO is not found
        [string] $iso = $(throw 'No ISO specified'),
        #Error message if VHD is not found
        [string] $RefVHDXPath = $(throw 'no reference disk specified')
    )

    #Grabs the current time and states when the process was started
    $StartTime = Get-Date
    Write-Verbose "Beginning at $StartTime"

    #Checking that prerequisite paths have been configured correctly
    if (Test-Path $iso) {Write-Verbose "ISO Path [$iso] exists"}
    else { Write-Verbose "ISO Path missing - quitting"; Return }

    #Importing necessary files
    Import-Module -name DISM 

    #Mount ISO onto local machine (Hypervisor not VM)
    Mount-DiskImage -ImagePath $iso

    #Get the volume of the image
    $ISOImage = Get-DiskImage -ImagePath $iso |Get-Volume

    $ISODrive = [string]$ISOImage.DriveLetter + ":"
    
    $indexlist = Get-WindowsImage -ImagePath $ISODrive\sources\install.wim
    Write-Verbose "$($indexlist.Count) images found"

    $item = $indexlist | Out-GridView -OutputMode Single
    $index = $item.ImageIndex

    Write-Verbose "selected image index [$index]"

    $VMDisk01 = New-VHD -path $RefVHDXPath -SizeBytes 50GB
    Write-Verbose "Created VHDX file [$($VMDisk01.path)]"

    Mount-DiskImage -ImagePath $RefVHDXPath
    $vhddisk = Get-DiskImage -ImagePath $RefVHDXPath | Get-Disk
    $vhddisknumber = [string]$vhddisk.Number
    Write-Verbose "Reference image is on disk number [$vhddisknumber]"
@"
select disk $disknumber
convert gpt
create partition efi size=1024
format quick fs=fat32 label="System"
gpt attributes=0x8000000000000001
set id="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"
assign letter="S"
create partition msr size=50
gpt attributes=0x8000000000000001
Set id="e3c9e316-0b5c-4db8-817d-f92df00215ae"
create partition primary 
gpt attributes=0x8000000000000001
format quick fs=ntfs label="Data"
assign letter="W"
shrink minimum=1024
create partition primary
format quick fs=ntfs label="Recovery"
assign letter="R"
set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
gpt attributes=0x8000000000000001
list volume
exit
"@ | diskpart.exe | Out-Null

    $vhdvolume = "W" + ":"
    $systempartition ="S:"

    Dism.exe /apply-Image /ImageFile:$ISODrive\Sources\install.wim /index:$index /ApplyDir:$vhdvolume\

    bcdboot.exe $vhdvolume\Windows /s $systempartition /f UEFI

    dismount-diskimage -imagepath $ISO
    dismount-diskimage -imagepath $RefVHDXPath

    Get-ChildItem $RefVHDXPath

    $finishtime = Get-Date
    $TT = $finishtime - $StartTime
    Write-Verbose "Finishing at $finishtime"
    Write-Verbose "Creating base image took [$($TT.totalminutes.tostring('n2'))] minutes"

}  #end of function

if (! (test-path $iso)) { "Producy ISO [$ISO] not found"; return }
else { "Product ISO is found" }
    
if (test-path $RefVHDXPath) { "Reference disk already exists"; return}
else { "Reference disk not found - to be created now"}

#Creates the virtual reference disk
New-RefVHDX -iso $iso -RefVHDXPath $RefVhdxPath -Verbose