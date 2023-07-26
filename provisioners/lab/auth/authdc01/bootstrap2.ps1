Write-Host "Attempting to create DNS zone... This may take several minutes."
$zoneCreated = $false
$subnet = "$Env:SUBNET"
$dcip = "$Env:DCIP"
$dcip = $dcip -replace "\."
$ipaddress = $subnet + '.0/24'
while (!$zoneCreated) {
    try {
				add-dnsserverprimaryzone -NetworkID $ipaddress -ReplicationScope 'Domain' -ErrorAction Stop
        Write-Host "DNS zone created successfully."
        $zoneCreated = $true
    }
    catch {
        Write-Host "Couldn't create DNS zone yet: $_. Retrying in 15 seconds..."
        Start-Sleep -Seconds 15
    }
}
$thirdO = ([version] "$subnet").Build
$secondO = ([version] "$subnet").Minor
$firstO = ([version] "$subnet").Major
$zonename = "$thirdO" + "." + "$secondO" + "." + "$firstO" + ".in-addr.arpa"
add-dnsserverresourcerecordptr -ZoneName $zonename -Name $dcip -PTRDomainName 'authdc01.labs.suse.com.'
Write-Host "Configuration complete."
