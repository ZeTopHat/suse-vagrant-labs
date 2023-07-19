$secured = ConvertTo-SecureString 'Windows2016' -AsPlainText -Force
$secured2 = ConvertTo-SecureString 'vagrant' -AsPlainText -Force
$username = "LABS\Administrator"
$credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $secured2
Uninstall-ADDSDomainController -Credential $credentials -localadministratorpassword $secured -LastDomainControllerInDomain -RemoveApplicationPartitions -Norebootoncompletion -force
