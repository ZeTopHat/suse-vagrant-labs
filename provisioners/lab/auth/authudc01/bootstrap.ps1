Write-Host "Installing AD packages and tools.."
Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools
Write-Host "Configuring and starting AD services.."
$secured = ConvertTo-SecureString 'Windows2016' -AsPlainText -Force
$secured2 = ConvertTo-SecureString 'vagrant' -AsPlainText -Force
$username = "labs.suse.com\Administrator"
$credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $secured2
$subnet = "$Env:SUBNET"
$dcip = "$Env:DCIP"
$ipaddress = $subnet + $dcip
$interface1 = Get-DNSClientServerAddress | Where-Object AddressFamily -Like 2 | select InterfaceAlias -First 1 -ExpandProperty InterfaceAlias
$interface2 = Get-DNSClientServerAddress | Where-Object AddressFamily -Like 2 | select InterfaceAlias -First 2 -ExpandProperty InterfaceAlias | select -Last 1
Set-DNSClientServerAddress $interface1 -ServerAddresses ($ipaddress)
Set-DNSClientServerAddress $interface2 -ServerAddresses ($ipaddress)
Install-ADDSDomain -ADPrepCredential $credentials -Credential $credentials -NewDomainName 'us' -ParentDomainName 'labs.suse.com' -DomainType 'ChildDomain' -ReplicationSourceDC 'authdc01.labs.suse.com' -InstallDNS -CreateDnsDelegation -DnsDelegationCredential $credentials -SafeModeAdministratorPassword $secured -SkipPreChecks -Force
