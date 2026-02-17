# Vagrant file addition:
#   windows.vm.provision "shell" do |s|
#     s.name = "create_user"
#     s.path = "#{WD}provisioners/lab/#{LABNAME}/#{LABNAME}dc01/create_user.ps1"
#   end
# Vagrant command: vagrant provision authdc01 --provision-with create_user

# Define parameters
$Username = "prick"  # Or whatever samaccountname you want.
$Password = "P@ssword123"   # Change for security reasons
$CN = "Rick\, Pickle M (Admin)" # Escaped comma in the CN.

# Import Active Directory module
Import-Module ActiveDirectory

# Generate a secure password
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

# Create the user if it doesn't exist
if (-not (Get-ADUser -Filter { SamAccountName -eq $Username })) {
    $UserPrincipalName = "$Username@$((Get-ADDomain).Forest)".ToLower()

    New-ADUser -Name $CN `
               -SamAccountName $Username `
               -UserPrincipalName $UserPrincipalName `
               -AccountPassword $SecurePassword `
               -Enabled $true `
               -PasswordNeverExpires $true

    Write-Host "Created user with CN: $CN"
    Write-Host "Username: $Username"
    Write-Host "Password: $Password"
} else {
    Write-Host "User $Username already exists."
}

Write-Host "Finished processing user $Username."
