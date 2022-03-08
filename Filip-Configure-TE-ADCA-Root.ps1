# Configure-TE-ADCA-Root.ps1
# Version    Date         What Changed
# -------    -----------  -------------------------------------------
# 1.0.0      14 Jan 2013  Initial release
# 1.1.0      06 Feb 2013  Added better vervose output
####

# Define first config block that creates the CA 
$conf = {
$VerbosePreference = 'Continue'
$ComputerName = "ADCS01"
$Username   = "$ADCS01\Administrator"
$PasswordSS = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
$Cred     = New-Object System.Management.Automation.PSCredential $Username,$PasswordSS

# Prepare CAPolicy.inf

Set-Content -Path $env:systemroot\CAPolicy.inf -Value "[Version]"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value 'Signature="$Windows NT$"'
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "[PolicyStatementExtension]"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "Policies=InternalPolicy"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "[InternalPolicy]"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "OID=1.2.3.4.5.6.7.8"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value 'Notice="Legal Policy Statement"'
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "URL=https://pki.ugs.academy/pki/cps.html"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "[Certsrv_Server]"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "RenewalKeyLength=2048"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "RenewalValidityPeriod=Years"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "RenewalValidityPeriodUnits=20"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "CRLPeriod=Years"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "CRLPeriodUnits=20"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "LoadDefaultTemplates=0"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "AlternateSignatureAlgorithm=1"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "CRLDeltaPeriod=Days"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "CRLDeltaPeriodUnits=0"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "[CRLDistributionPoint]"
Add-Content -Path $env:systemroot\CAPolicy.inf -Value "[AuthorityInformationAccess]"

# Import server manager module, but quietly
Import-Module ServerManager -Verbose:$false

# Ensure we have all the required pre-req features loaded
# First create an array of the modules to install
Write-Verbose 'Adding Required Windows features for CA'
$Mods = @('Adcs-Cert-Authority')
Install-WindowsFeature $Mods -Verbose -IncludemanagementTools

# Now install the CA
Write-Verbose "Installing CA on $ComputerName"
# Specify CA details to be used to create this CA
$CaParmsHT = @{CACommonName = 'UGS-ROOT-CA';
               CAType       = 'StandAloneRootCA';
               KeyLength    = "4096";
               CryptoProviderName = "RSA#Microsoft Software Key Storage Provider";
               HashAlgorithmName = 'SHA512';
               ValidityPeriod = 'Years';
               ValidityPeriodUnits = "20";
               Cred         = $cred
}
Install-AdCsCertificationAuthority @CaParmsHT -OverwriteExistingCAinDS -OverwriteExistingDatabase -OverwriteExistingKey -Force -Verbose
}# end of conf script block

# This is second script block - run after the reboot.
$conf2 = {
$VerbosePreference = 'Continue'
$ComputerName = "ADCS02"
$Username   = "$ComputerName\Administrator"
$PasswordSS = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
$Cred     = New-Object System.Management.Automation.PSCredential $Username,$PasswordSS

# Post install configuration
Write-Verbose "Running post configuration tasks on $ComputerName"

$crllist = Get-CACrlDistributionPoint; foreach ($crl in $crllist) {Remove-CACrlDistributionPoint $crl.uri -Force}; 
Add-CACRLDistributionPoint -Uri C:\Windows\System32\CertSrv\CertEnroll\UGS-ROOT-CA%8%9.crl -PublishToServer -PublishDeltaToServer -Force
Add-CACRLDistributionPoint -Uri http://pki.ugs.academy/pki/UGS-ROOT-CA%8%9.crl -AddToCertificateCDP -AddToFreshestCrl -Force
Get-CAAuthorityInformationAccess | Where-Object {$_.Uri -like '*ldap*' -or $_.Uri -like '*http*' -or $_.Uri -like '*file*'} | Remove-CAAuthorityInformationAccess -Force
Add-CAAuthorityInformationAccess -AddToCertificateAia http://pki.ugs.academy/pki/UGS-ROOT-CA%3%4.crt -Force 
certutil.exe –setreg CA\CRLPeriodUnits 20 
certutil.exe –setreg CA\CRLPeriod “Years” 
certutil.exe –setreg CA\CRLOverlapPeriodUnits 3 
certutil.exe –setreg CA\CRLOverlapPeriod “Weeks” 
certutil.exe –setreg CA\ValidityPeriodUnits 10 
certutil.exe –setreg CA\ValidityPeriod “Years” 
certutil.exe -setreg CA\AuditFilter 127
Restart-Service certsvc

# We now need to wait until the CA has started up and has created a cert for $ComputerName.
# This is fairly quick, but may need a GPUpdate to create the cert. So we first force
# a GPUpdate. Then we go to sleep for 5 seconds to enable the Cert to be fully registered
# and. We then poll for the cert sleeping 5 seconds between checks.
Write-Verbose "Waiting for $ComputerName Cert to be created"
Write-Verbose 'Force a GPUpdate first, then wait...'
Gpupdate /Target:Computer /Force

$CertRoot = "UGS-ROOT-CA"

# Next check if the cert is there, if not wait and try again
While (! (Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -Match $CertRoot)) {
  Write-Host "Sleeping for 5 seconds waiting for $ComputerName cert $CertRoot..."
  Start-sleep -seconds 5
}

# OK - now we're here, cert has been created - so get it and display
$Cert=(Get-ChildItem Cert:\localmachine\my | Where-Object Subject -Match $CertRoot)
Write-Verbose "Cert being used is: [$($cert.thumbprint)]"

} # end of conf2 script block

##############################################

# Start of the main script
$StartTime = Get-Date
$ComputerName = "ADCS02"
Write-Verbose "Starting creation of CA on $ComputerName at $StartTime"
$VerbosePreference = 'Continue'

#Snapshot before configuration
Checkpoint-VM -VM $(Get-VM ADCS02) -SnapshotName "ADCS02 - Before 

# Invoke the firt script block, $Conf, on ADCS02 using the folowing credentials
$PasswordSS = ConvertTo-SecureString 'Kluft9!' -AsPlainText -Force
$Username   = "$ComputerName\administrator"
$Cred     = New-Object system.management.automation.PSCredential $username,$PasswordSS
Write-Verbose "Runing Conf block on $ComputerName"
Invoke-command -VMName $ComputerName -Scriptblock $Conf -Credential $Cred -Verbose
Write-Verbose 'Completed basic CA installation, let us reboot'

# Now reboot
Write-Verbose 'Rebooting system, please be patient'
Restart-Computer -ComputerName $ComputerName -Wait -For Wmi -Force -Credential $Cred

# and now after the reboot, finish off the CA configuration
Write-Verbose "Running Conf2 block on $ComputerName"
Invoke-Command -VMName $ComputerName -Scriptblock $Conf2 -Credential $Cred -Verbose

# Now reboot again
Write-Verbose 'Final reboot, please be patient'
Restart-Computer -ComputerName $ComputerName -Wait -For Wmi -Force -Credential $Cred

#Snapshot after configuration
Checkpoint-VM -VM $(Get-VM ADCS02) -SnapshotName "ADCS02 - After" 

# Print out stats and quit
$Finishtime = Get-Date
$Diff = $FinishTime - $StartTime
Write-Host ("CA Installation took {0} minutes" -f $diff.minutes)