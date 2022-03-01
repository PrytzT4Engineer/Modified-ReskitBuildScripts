################################################################################

# VARIABLERNA $Username och $PasswordSS MÅSTE DUBBELKOLLAS INNAN DU KÖR SCRIPTET

################################################################################




# Define first config block that creates the CA 
$conf = {
$VerbosePreference = 'Continue'
$Username   = "ADCS02\Administrator"
$PasswordSS = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force # Lösenord, Password
$CredRk     = New-Object System.Management.Automation.PSCredential $Username,$PasswordSS

# Import server manager module, but quietly
Import-Module ServerManager -Verbose:$false

# Ensure we have all the required pre-req features loaded
# First create an array of the modules to install
Write-Verbose 'Adding Required Windows features for CA'
$Mods = @('AD-Certificate','Adcs-Cert-Authority', 'Adcs-Enroll-Web-Svc','Adcs-Web-Enrollment','Adcs-Enroll-Web-Pol')  
Install-WindowsFeature $Mods -Verbose -IncludemanagementTools

# Now install the CA
Write-Verbose 'Installing CA on ADCS02'
# Specify CA details to be used to create this CA
$CaParmsHT = @{CACommonName = 'FilipCA';
               CAType       = 'EnterpriseRootCA';
               KeyLength    = 2048;
               Cred         = $credrk 
}
Install-AdCsCertificationAuthority @CaParmsHT -OverwriteExistingCAinDS -Force -Verbose 

# With CA installed, add the web enrollment pages
Write-Verbose 'Installing ADCS web enrollment feature'
Install-AdcsWebEnrollment -Force -Verbose

# And now perform a GPupdate and exit
Invoke-Gpupdate -Target Computer -Force
}# end of conf script block

# This is second script block - run after the reboot.
$conf2 = {
$VerbosePreference = 'Continue'
$Username   = "ADCS02\Administrator"
$PasswordSS = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force # Lösenord, Password
$CredRk     = New-Object System.Management.Automation.PSCredential $Username,$PasswordSS

# SSL enable the site to make Certsv happy
Write-Verbose 'Creating SSL Binding for ADCS02'
Import-Module WebAdministration -Verbose:$false
New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https

# We now need to wait until the CA has started up and has created a cert for ADCS02.
# This is fairly quick, but may need a GPUpdate to create the cert. So we first force
# a GPUpdate. Then we go to sleep for 5 seconds to enable the Cert to be fully registered
# and. We then poll for the cert sleeping 5 seconds between checks.
Write-Verbose "Waiting for ADCS02 Cert to be created"
Write-Verbose 'Force a GPUpdate first, then wait...'
Gpupdate /Target:Computer /Force

# Next check if the cert is there, if not wait and try again
While (! (Get-ChildItem Cert:\LocalMachine\My | Where Subject -Match 'ADCS02')) {
  Write-Host "Sleeping for 5 seconds waiting for ADCS02 cert..."
  Start-sleep -seconds 5
}

# OK - now we're here, cert has been created - so get it and display
$Cert=(Get-ChildItem Cert:\localmachine\my | Where Subject -Match 'ADCS02')
Write-Verbose "Cert being used is: [$($cert.thumbprint)]"

# Now set binding with the ADCS02 cert
Write-Verbose "Setting SSL bindings with this cert"
New-Item IIS:\SSLBindings\0.0.0.0!443 -value $Cert

} # end of conf2 script block

##############################################

# Start of the main script
$StartTime = Get-Date
Write-Verbose "Starting creation of CA on ADCS02 at $StartTime"
$VerbosePreference = 'Continue'

# Skapar en snapshot innan scriptet körs
$VMNAME = 'ADCS02'
Checkpoint-VM -Name $VMNAME -SnapshotName BeforeScript-FilipConfDC1CA

# Invoke the firt script block, $Conf, on ADCS02 using the folowing credentials
$PasswordSS = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force # Lösenord, Password
$Username   = "ADCS02\administrator"
$CredRk     = New-Object system.management.automation.PSCredential $username,$PasswordSS
Write-Verbose 'Runing Conf block on ADCS02'
Invoke-Command -VMName ADCS02 -Scriptblock $Conf -Credential $CredRK -Verbose
Write-Verbose 'Completed basic CA installation, let us reboot'

# Now reboot
Write-Verbose 'Rebooting system, please be patient'
Restart-Computer -ComputerName ADCS02  -Wait -For PowerShell -Force -Credential $CredRK

# and now after the reboot, finish off the CA configuration
Write-Verbose 'Running $Conf2 block on ADCS02'
Invoke-Command -VMName ADCS02 -Scriptblock $Conf2 -Credential $CredRK -Verbose

# Now reboot again
Write-Verbose "And a final reboot"
Restart-Computer -ComputerName ADCS02  -Wait -For PowerShell -Force -Credential $CredRK

# Skapar en snapshot efter scriptet körs
Checkpoint-VM -Name $VMNAME -SnapshotName AfterScript-FilipConfDC1CA

# Print out stats and quit
$Finishtime = Get-Date
$Diff = $FinishTime - $StartTime
Write-Host ("CA Installation took {0} minutes" -f $diff.minutes)