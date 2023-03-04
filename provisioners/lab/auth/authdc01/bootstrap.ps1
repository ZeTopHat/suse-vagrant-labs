Write-Host "Installing AD packages and tools.."
Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools
Write-Host "Configuring and starting AD services.."
$secured = ConvertTo-SecureString 'Windows2016' -AsPlainText -Force
Install-ADDSForest -DomainName 'labs.suse.com' -CreateDnsDelegation:$false -DomainMode '7' -DomainNetbiosName 'LABS' -ForestMode '7' -InstallDNS -SafeModeAdministratorPassword $secured -SkipPreChecks -Force
Write-Host "Attempting to create DNS zone... This may take several minutes."
$zoneCreated = $false
while (!$zoneCreated) {
    try {
				add-dnsserverprimaryzone -NetworkID '192.168.0.0/24' -ReplicationScope 'Domain' -ErrorAction Stop
        Write-Host "DNS zone created successfully."
        $zoneCreated = $true
    }
    catch {
        Write-Host "Couldn't create DNS zone yet: $_. Retrying in 15 seconds..."
        Start-Sleep -Seconds 15
    }
}
add-dnsserverresourcerecordptr -ZoneName '0.168.192.in-addr.arpa' -Name '26' -PTRDomainName 'authdc01.labs.suse.com.'
Write-Host "Configuration complete."
