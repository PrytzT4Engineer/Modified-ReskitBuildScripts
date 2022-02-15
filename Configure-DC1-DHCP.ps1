#    Turn on verbosity
$VerbosePreference = 'Continue'

#    Install and configure DHCP
Write-Verbose -Message 'Adding and then configuring DHCP'
Install-WindowsFeature DHCP -IncludeManagementTools

# Create necessary DHCP Groups and set config appropriately and restart the service
Import-Module DHCPServer -Verbose:$False 
Add-DHCPServerSecurityGroup -Verbose
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2
Restart-Service -Name DHCPServer -Force 
Write-Verbose 'DHCP Installed'

Add-DhcpServerV4Scope -Name "Filip" `
-StartRange 192.168.206.1 `
-EndRange 192.168.206.100 `
-SubnetMask 255.255.255.0
Write-Verbose 'Filip DHCP Scope added'

# Set Option Values
Set-DhcpServerV4OptionValue -DnsDomain Filip.local `
                            -DnsServer 192.168.206.21 `
                            -Router 192.168.206.1
# Authorise the DCHP server in the AD                            
Write-Verbose 'Authorising DHCP Server in AD'                            
Add-DhcpServerInDC -DnsName ADDS01.Filip.local
Write-Verbose 'DHCP Server authorised in AD'