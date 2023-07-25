Write-Host "Installing AD packages and tools.."
Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools
Write-Host "Configuring and starting AD services.."
$secured = ConvertTo-SecureString 'Windows2016' -AsPlainText -Force
Install-ADDSForest -DomainName 'labs.suse.com' -CreateDnsDelegation:$false -DomainMode '7' -DomainNetbiosName 'LABS' -ForestMode '7' -InstallDNS -SafeModeAdministratorPassword $secured -SkipPreChecks -Force
