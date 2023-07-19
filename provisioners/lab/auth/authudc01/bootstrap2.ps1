Write-Host "Attempting to create User Principal Names... This may take several minutes."
$userFound = $false
while (!$userFound) {
    try {
        Get-ADUser -Identity "Administrator" -ErrorAction Stop
        Write-Host "AD Users found. Creating User Principal Names.."
        $userFound = $true
    }
    catch {
        Write-Host "Couldn't find AD users yet: $_. Retrying in 15 seconds..."
        Start-Sleep -Seconds 15
    }
}
Get-ADUser -Identity "Administrator" | Set-ADUser -UserPrincipalName "Administrator@us.labs.suse.com"
Get-ADUser -Identity "vagrant" | Set-ADUser -UserPrincipalName "vagrant@us.labs.suse.com"
Get-ADUser -Identity "Administrator"
Write-Host "Configuration complete."
