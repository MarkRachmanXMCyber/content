### Pre-requisites

* Install PowerShell 7 as documented [here](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7#installing-the-msi-package)
* Install OpenSSH as documented [here](https://hostadvice.com/how-to/how-to-install-an-openssh-server-client-on-a-windows-2016-server/) or [here](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse#:~:text=To%20install%20OpenSSH%2C%20start%20Settings,%2C%20then%20click%20%22Install%22.)
* Manually generate your ssh key in windows as documented [here](https://docs.joyent.com/public-cloud/getting-started/ssh-keys/generating-an-ssh-key-manually/manually-generating-your-ssh-key-in-windows) and [here](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)
* Enable key authentication as documented [here](https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/ssh-remoting-in-powershell-core?view=powershell-7)
* **Important** - In case Windows SSH server refuses key based authentication from client, Search for and comment group matching policy in sshd_config
```
# Match Group administrators
# AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```
For more about that see [here](https://superuser.com/questions/1445976/windows-ssh-server-refuses-key-based-authentication-from-client)

Once all pre-requisites are satisfied, you can try to run the following command on your client and see that it returns a valid response 
```
$Session = New-PSSession -HostName $computerName -UserName $userName -Port $port -SSHTransport -KeyFilePath $filePath -ErrorAction Stop
Invoke-Command $Session -ScriptBlock {
                    $PSVersionTable
                }
```
