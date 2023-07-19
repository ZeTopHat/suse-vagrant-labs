Write-Host "Installing AD packages and tools.."
Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools
Write-Host "Configuring and starting AD services.."
$secured = ConvertTo-SecureString 'Windows2016' -AsPlainText -Force
$secured2 = ConvertTo-SecureString 'vagrant' -AsPlainText -Force
$username = "LABS\Administrator"
$credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $secured2
Set-DNSClientServerAddress "Ethernet" -ServerAddresses ("192.168.0.26")
Set-DNSClientServerAddress "Ethernet 2" -ServerAddresses ("192.168.0.26")
Install-ADDSDomain -ADPrepCredential $credentials -Credential $credentials -NewDomainName 'us' -ParentDomainName 'labs.suse.com' -DomainType 'ChildDomain' -ReplicationSourceDC 'authdc01.labs.suse.com' -InstallDNS -CreateDnsDelegation -DnsDelegationCredential $credentials -SafeModeAdministratorPassword $secured -SkipPreChecks -Force
