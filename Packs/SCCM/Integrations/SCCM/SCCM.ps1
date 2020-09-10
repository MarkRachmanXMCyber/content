. $PSScriptRoot\CommonServerPowerShell.ps1

Function GetLastLogOnUser($Session, $siteCode, $computerName){
    $computer = Invoke-Command $Session -ArgumentList $computerName,$siteCode -ErrorAction Stop -ScriptBlock {
        param($computerName,$siteCode)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        Get-CMResource -ResourceType System -Fast | Where-Object { $_.Name -eq $computerName }

    }
    if ($computer){
        $output = [PSCustomObject]@{
            'SCCM.Computer' = [PSCustomObject]@{
                CreationDate = $computer.CreationDate.ToUniversalTime().ToString("yyyy-mm-ddTHH:MM:ssZ")
                IP = ($computer.IPAddresses | Out-String).Replace("`n", " ")
                Name = $computer.Name
                LastLogonTimestamp = $computer.LastLogonTimestamp.ToUniversalTime().ToString("yyyy-mm-ddTHH:MM:ssZ")
                LastLogonUserName = $computer.LastLogonUserName
            }
        }
        $MDOutput = $output."SCCM.Computer" | TableToMarkdown -Name "Last loggon user on $computerName"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $Output -RawResponse $computer
    }
    else{
        throw "Could not find a computer with the name $computerName"
    }
}
Function GetPrimaryUser($Session, $siteCode, $computerName){
    $user_device_affinity = Invoke-Command $Session -ArgumentList $computerName,$siteCode -ErrorAction Stop -ScriptBlock {
        param($computerName,$siteCode)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        $computer = Get-CMResource -ResourceType System -Fast | Where-Object { $_.Name -eq $computerName }
        if (!$computer) {
            throw "Could not find a computer with the name $computerName"
        }
        Get-CMUserDeviceAffinity -DeviceName $computerName
    }
    if ($user_device_affinity){
        $output = [PSCustomObject]@{
            'SCCM.PrimaryUsers' = $user_device_affinity | ForEach-Object {[PSCustomObject]@{
                "Machine Name" = $_.ResourceName
                "User Name" = $_.UniqueUserName
            }
            }
        }
        $MDOutput = $output."SCCM.PrimaryUsers" | TableToMarkdown -Name "Primary users on $computerName"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $output -RawResponse $user_device_affinity
    }
    else{
        $output = @()
        $MDOutput = $output | TableToMarkdown -Name "Primary users on $computerName"
        ReturnOutputs $MDOutput
    }
}
Function ListInstalledSoftwares($Session, $deviceName, $Creds) {
    $Softwares = Invoke-Command $Session -ArgumentList $deviceName, $Creds -ErrorAction Stop -ScriptBlock {
        param($deviceName, $Creds)
        if (Test-Connection -ComputerName $deviceName -Quiet)
        {
            $SecurePassword = ConvertTo-SecureString -AsPlainText -Force -String $Creds.Password
            $Creds = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($Creds.DomainName)\$($Creds.UserName)", $SecurePassword
            $progressPreference = 'silentlyContinue'
            $result = Get-WmiObject -Class Win32_Product -ComputerName $deviceName -credential $Creds
        }
        $result
    }
    if ($Softwares)
    {
        $output = [PSCustomObject]@{
            "SCCM.InstalledSoftwares" = $Softwares | ForEach-Object {[PSCustomObject]@{
                Name = $_.Name
                Version = $_.Version
                Vendor = $_.Vendor
                Caption = $_.Caption
                IdentifyingNumber = $_.IdentifyingNumber.Trim('{}')
            }
        }
        }
        $MDOutput = $output."SCCM.InstalledSoftwares" | TableToMarkdown -Name "Installed softwares on $deviceName"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $output -RawResponse $Softwares
    }
    else{
        $output = @()
        $MDOutput = $output | TableToMarkdown -Name "Installed softwares on $deviceName"
        ReturnOutputs $MDOutput
    }
}


Function TestModule($Session, $SiteCode, $Creds)
{
    Invoke-Command $Session -ArgumentList $SiteCode, $Creds -ErrorAction Stop -ScriptBlock {
        param($SiteCode, $Creds)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        if ((Get-Module -Name ConfigurationManager).Version -eq $null)
        {
            throw "Could not find SCCM modules in the SCCM machine"
        }
        $Devices = Get-CMResource -ResourceType System -Fast|Where-Object {$_.Name -ne $env:computername} | ForEach-Object {$_.Name}
        # Checking Creds
        if ($Devices){
            $SecurePassword = ConvertTo-SecureString -AsPlainText -Force -String $Creds.Password
            $Creds = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($Creds.DomainName)\$($Creds.UserName)", $SecurePassword
            $progressPreference = 'silentlyContinue'
            $CheckCreds = Get-WmiObject -Class Win32_Product -ComputerName $Devices[0] -credential $Creds | Out-Null
        }
    }
}

function Main
{
    # Parse Params
    $computerName = $demisto.Params()['ComputerName']
    $key = $demisto.Params()['Key']
    $userName = $demisto.Params()['UserName']
    $port = $demisto.Params()['port']
    $UseSSL = $demisto.Params()['insecure']
    $SiteCode = $demisto.Params()['SiteCode']
    $DomainName = $demisto.Params()['DomainName']
    $password = $demisto.Params()['password']
    $tmp = New-TemporaryFile
    $key | Out-File $tmp.FullName
    $Creds = @{DomainName=$DomainName;Password=$password;UserName=$userName}
    $Session = New-PSSession -HostName $computerName -UserName $userName -Port $port -SSHTransport -KeyFilePath $tmp.FullName -ErrorAction Stop
    try
    {
        Switch ( $Demisto.GetCommand())
        {
            "test-module" {
                $Demisto.Debug("Running test-module")
                TestModule $Session $SiteCode $Creds | Out-Null
                ReturnOutputs "ok" | Out-Null
            }
            "sccm-last-log-on-user" {
                $deviceName = $demisto.Args()['ComputerName']
                GetLastLogOnUser $Session $SiteCode $deviceName | Out-Null
            }
            "sccm-get-primary-user" {
                $deviceName = $demisto.Args()['ComputerName']
                GetPrimaryUser $Session $SiteCode $deviceName | Out-Null
            }
            "sccm-get-installed-softwares" {
                $deviceName = $demisto.Args()['ComputerName']
                ListInstalledSoftwares $Session $deviceName $Creds | Out-Null
            }
        }
    }
    catch
    {
        ReturnError -Message "Something has gone wrong in SCCM.ps1:Main() [$( $_.Exception.Message )]" -Err $_ | Out-Null
        return
    }
    finally {
        Remove-Item $tmp.FullName
    }
}

# Execute Main when not in Tests
if ($MyInvocation.ScriptName -notlike "*.tests.ps1" -AND -NOT $Test) {
    Main
}
