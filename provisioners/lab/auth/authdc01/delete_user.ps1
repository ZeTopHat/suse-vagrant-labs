# Vagrant file addition:
#   windows.vm.provision "shell" do |s|
#     s.name = "delete_user"
#     s.path = "#{WD}provisioners/lab/#{LABNAME}/#{LABNAME}dc01/delete_user.ps1"
#   end
# Vagrant command: vagrant provision authdc01 --provision-with delete_user

# Define parameters
$Username = "prick"  # Change to the username you want to delete

# Import Active Directory module
Import-Module ActiveDirectory

# Check if the user exists
if (Get-ADUser -Filter { SamAccountName -eq $Username }) {
    # Delete the user
    Remove-ADUser -Identity $Username -Confirm:$false #Confirm:$false suppresses the confirmation prompt
    Write-Host "Deleted user: $Username"
} else {
    Write-Host "User $Username does not exist."
}

Write-Host "Finished processing user $Username."
