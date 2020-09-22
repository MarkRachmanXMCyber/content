. $PSScriptRoot\CommonServerPowerShell.ps1
$COLLECTION_TYPE_MAPPING = @{
    "0" = "Root"
    "1" = "User"
    "2" = "Device"
    "3" = "Unknown"
}
$COLLECTION_CURRENT_STATUS_MAPPING = @{
    "0" = "NONE"
    "1" = "READY"
    "2" = "REFRESHING"
    "3" = "SAVING"
    "4" = "EVALUATING"
    "5" = "AWAITING_REFRESH"
    "6" = "DELETING"
    "7" = "APPENDING_MEMBER"
    "8" = "QUERYING"
}
$SCRIPT_APPROVAL_STATE = @{
    "0" = "Waiting for approval"
    "1" = "Declined"
    "3" = "Approved"
}
<#
.DESCRIPTION
This function converts a datetime object onto ISO format string

.PARAMETER date
The date that should be parsed

.OUTPUTS
Return The String representation of the datetime object normalized to UTC if or $null if $date is $null
#>
Function ParseDateTimeObjectToIso($date)
{
    if ($date)
    {
        return $date.ToUniversalTime().ToString("yyyy-mm-ddTHH:MM:ssZ")
    }
    return $null
}
<#
.DESCRIPTION
This function Verifies only one of the following arguments was actually given and throws an exception if not.

.PARAMETER $errorMessage
The error message with which the error should be raised

.PARAMETER $parameters
The parameters list from which only non-null parameter should be given
#>
Function AssertNoMoreThenOneParameterGiven
{
    param([Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string] $errorMessage,
        [Parameter(Mandatory = $true, Position = 1, ValueFromRemainingArguments = $true)]
        [AllowEmptyString()]
        [string[]] $parameters)
    if (([array]($parameters| where-Object { !!$_ })).Length -gt 1)
    {
        throw "Parameter set cannot be resolved using the specified named parameters. $errorMessage"
    }
}

<#
.DESCRIPTION
This function Verifies none of the following arguments was actually given and throws an exception if it was.

.PARAMETER $errorMessage
The error message with which the error should be raised

.PARAMETER $parameters
The parameters list from which all parameters should be null
#>
Function AssertNoParameterGiven
{
    param([Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string] $errorMessage,
        [Parameter(Mandatory = $true, Position = 1, ValueFromRemainingArguments = $true)]
        [AllowEmptyString()]
        [string[]] $parameters)
    if (([array]($parameters| where-Object { !!$_ })).Length -gt 0)
    {
        throw "Parameter set cannot be resolved using the specified named parameters. $errorMessage"
    }
}

<#
.DESCRIPTION
This function Verifies only one of the following arguments was actually given and throws an exception if not.
For more info see https://docs.microsoft.com/en-us/powershell/module/configurationmanager/get-cmcollection?view=sccm-ps

.PARAMETER collection_id
Specifies a collection ID

.PARAMETER collection_name
Specifies a collection name

.PARAMETER distribution_point_group_id
Specifies the ID of the distribution point group that is associated with the collection

.PARAMETER distribution_point_group_name
Specifies the name of the distribution point group that is associated with a collection

.OUTPUTS
Return the used parameter or throws an exception if more then one is used
#>
Function ValidateGetCollectionListParams($collection_id, $collection_name, $distribution_point_group_id, $distribution_point_group_name)
{
    AssertNoMoreThenOneParameterGiven "Please select only one of: collection_id, collection_name, distribution_point_group_id, distribution_point_group_name."  `
    $collection_id $collection_name $distribution_point_group_id $distribution_point_group_name
    $result = ""
    if ($collection_id)
    {
        $result = "collection_id"
    }
    elseif ($collection_name)
    {
        $result = "collection_name"
    }
    elseif ($distribution_point_group_id)
    {
        $result = "distribution_point_group_id"
    }
    elseif ($distribution_point_group_name)
    {
        $result = "distribution_point_group_name"
    }
    Return $result
}
<#
.DESCRIPTION
This function Verifies only one of the following arguments was actually given and throws an exception if not.
For more info see https://docs.microsoft.com/en-us/powershell/module/ConfigurationManager/Get-CMDevice?view=sccm-ps

.PARAMETER collection_id
Specifies a collection ID

.PARAMETER collection_name
Specifies a collection name

.PARAMETER device_name
Specifies the name of the device

.PARAMETER resource_id
Specifies the resource ID of a device

.PARAMETER threat_id
Specifies an ID of a threat

.PARAMETER threat_name
Specifies the a name of a threat

.OUTPUTS
Return the used parameters or throws an exception if parameter set cannot be resolved
#>
Function ValidateGetDeviceListParams($collection_id, $collection_name, $device_name, $resource_id, $threat_id, $threat_name)
{
    if ($device_name)
    {
        AssertNoParameterGiven "device_name parameter can be resolved only with collection_name or collection_id" $resource_id $threat_id $threat_name
        if ($collection_name)
        {
            AssertNoParameterGiven "device_name parameter can be resolved with collection_name or collection_id, not both" $collection_id
            return "device_name&collection_name"
        }
        elseif ($collection_id)
        {
            return "device_name&collection_id"
        }
        return "device_name"
    }
    if ($collection_id)
    {
        AssertNoParameterGiven "collection_id parameter can be resolved only with device_name, threat_id or threat_name" $collection_name $resource_id
        if ($threat_id)
        {
            return "collection_id&threat_id"
        }
        elseif($threat_name)
        {
            return "collection_id&threat_name"
        }
        throw "collection_id parameter can be resolved only with device_name, threat_id or threat_name"
    }
    if ($resource_id)
    {
        AssertNoParameterGiven "resource_id must be resolved with no other parameter" $collection_id $collection_name $device_name $threat_id $threat_name
        return "resource_id"
    }
    return ""
}
<#
.DESCRIPTION
This function Verifies only one of the following arguments was actually given and throws an exception if not.
For more info see https://docs.microsoft.com/en-us/powershell/module/configurationmanager/new-cmscript?view=sccm-ps

.PARAMETER script_file_entry_id
Specifies the script file entry id ID

.PARAMETER script_text
Specifies the script code string content

.OUTPUTS
Return the used parameters or throws an exception if parameter set cannot be resolved
#>
Function ValidateCreateScriptParams($script_file_entry_id, $script_text){
    AssertNoMoreThenOneParameterGiven "script_file_entry_id cannot be resolved with script_text" $script_file_entry_id $script_text
    if (!$script_file_entry_id -And !$script_text){
        throw "Please supply either script_file_entry_id or script_text"
    }
    if ($script_file_entry_id){
        return "script_path"
    }
    return "script_text"
}
Function GetLastLogOnUser($deviceName)
{
    $device = Invoke-Command $global:Session -ArgumentList $deviceName, $global:siteCode -ErrorAction Stop -ScriptBlock {
        param($deviceName, $siteCode)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        Get-CMResource -ResourceType System -Fast |Where-Object { $_.Name -eq $deviceName }

    }
    if ($device)
    {
        $output = [PSCustomObject]@{
            "MicrosoftECM.LastLogOnUser" = [PSCustomObject]@{
                CreationDate = $device.CreationDate | ParseDateTimeObjectToIso
                IP = ($device.IPAddresses | Out-String).Replace("`n", " ")
                Name = $device.Name
                LastLogonTimestamp = $device.LastLogonTimestamp | ParseDateTimeObjectToIso
                LastLogonUserName = $device.LastLogonUserName
            }
        }
        $MDOutput = $output."MicrosoftECM.LastLogOnUser" | TableToMarkdown -Name "Last loggon user on $deviceName"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $Output -RawResponse $device
    }
    else
    {
        throw "Could not find a computer with the name $deviceName"
    }
}


Function GetPrimaryUser($deviceName)
{
    $user_device_affinity = Invoke-Command $global:Session -ArgumentList $deviceName, $global:siteCode -ErrorAction Stop -ScriptBlock {
        param($deviceName, $siteCode)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        $device = Get-CMDevice -Name $deviceName -Fast
        if (!$device)
        {
            throw "Could not find a computer with the name $computerName"
        }
        Get-CMUserDeviceAffinity -DeviceName $deviceName
    }
    if ($user_device_affinity)
    {
        $output = [PSCustomObject]@{
            'MicrosoftECM.PrimaryUsers' = $user_device_affinity | ForEach-Object {
                [PSCustomObject]@{
                    "Machine Name" = $_.ResourceName
                    "User Name" = $_.UniqueUserName
                }
            }
        }
        $MDOutput = $output."MicrosoftECM.PrimaryUsers" | TableToMarkdown -Name "Primary users on $computerName"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $output -RawResponse $user_device_affinity
    }
    else
    {
        $output = @()
        $MDOutput = $output | TableToMarkdown -Name "Primary users on $computerName"
        ReturnOutputs $MDOutput
    }
}

# TODO not working well
Function ListInstalledSoftwares($deviceName)
{
    $Softwares = Invoke-Command $global:Session -ArgumentList $computerName, $global:Creds -ErrorAction Stop -ScriptBlock {
        param($deviceName, $Creds)
        if (Test-Connection -ComputerName $deviceName -Quiet)
        {
            $SecurePassword = ConvertTo-SecureString -AsPlainText -Force -String $Creds.Password
            $Creds = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($Creds.UserName)", $SecurePassword
            $progressPreference = 'silentlyContinue'
            $result = Get-WmiObject -Class Win32_Product -ComputerName $deviceName -credential $Creds
        }
        $result
    }
    if ($Softwares)
    {
        $output = [PSCustomObject]@{
            "MicrosoftECM.InstalledSoftwares(val.IdentifyingNumber && val.IdentifyingNumber === obj.IdentifyingNumber)" = $Softwares | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.Name
                    Version = $_.Version
                    Vendor = $_.Vendor
                    Caption = $_.Caption
                    IdentifyingNumber = $_.IdentifyingNumber.Trim('{}')
                }
            }
        }
        $MDOutput = $output."MicrosoftECM.InstalledSoftwares(val.IdentifyingNumber && val.IdentifyingNumber === obj.IdentifyingNumber)" | TableToMarkdown -Name "Installed softwares on $deviceName"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $output -RawResponse $Softwares
    }
    else
    {
        $output = @()
        $MDOutput = $output | TableToMarkdown -Name "Installed softwares on $deviceName"
        ReturnOutputs $MDOutput
    }
}
Function GetCollectionList($collection_type, $collection_id, $collection_name, $distribution_point_group_id, $distribution_point_group_name)
{
    $usedParameterName = ValidateGetCollectionListParams $collection_id $collection_name $distribution_point_group_id $distribution_point_group_name
    $parameters = @{
        usedParameterName = $usedParameterName
        collection_type = $collection_type
        collection_id = $collection_id
        collection_name = $collection_name
        distribution_point_group_id = $distribution_point_group_id
        distribution_point_group_name = $distribution_point_group_name
    }
    $Collections = Invoke-Command $global:Session -ArgumentList $parameters, $global:siteCode -ErrorAction Stop -ScriptBlock {
        param($parameters, $siteCode)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        switch ($parameters.usedParameterName)
        {
            "collection_id" {
                Get-CMCollection -CollectionType $parameters.collection_type -Id $parameters.collection_id
            }
            "collection_name" {
                Get-CMCollection -CollectionType $parameters.collection_type -Name $parameters.collection_name
            }
            "distribution_point_group_id" {
                Get-CMCollection -CollectionType $parameters.collection_type -DistributionPointGroupId  $parameters.distribution_point_group_id
            }
            "distribution_point_group_name" {
                Get-CMCollection -CollectionType $parameters.collection_type -DistributionPointGroupName $parameters.distribution_point_group_name
            }
            default {
                Get-CMCollection -CollectionType $parameters.collection_type
            }
        }
    }
    if ($Collections)
    {
        $output = [PSCustomObject]@{
            "MicrosoftECM.Collections(val.ID && val.ID === obj.ID)" = $Collections | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.Name
                    ID = $_.CollectionID
                    Rules = $_.CollectionRules
                    Type = $COLLECTION_TYPE_MAPPING["$( $_.CollectionType )"]
                    Comment = $_.Comment
                    CurrentStatus = $COLLECTION_CURRENT_STATUS_MAPPING["$( $_.CurrentStatus )"]
                    HasProvisionedMember = $_.HasProvisionedMember
                    IncludeExcludeCollectionsCount = $_.IncludeExcludeCollectionsCount
                    IsBuiltIn = $_.IsBuiltIn
                    IsReferenceCollection = $_.IsReferenceCollection
                    LastChangeTime = ParseDateTimeObjectToIso $_.LastChangeTime
                    LastMemberChangeTime = ParseDateTimeObjectToIso $_.LastMemberChangeTime
                    LastRefreshTime = ParseDateTimeObjectToIso $_.LastRefreshTime
                    LimitToCollectionID = $_.LimitToCollectionID
                    LimitToCollectionName = $_.LimitToCollectionName
                    LocalMemberCount = $_.LocalMemberCount
                    MemberClassName = $_.MemberClassName
                    MemberCount = $_.MemberCount
                    UseCluster = $_.UseCluster
                }
            }
        }
        $MDOutput = $output."MicrosoftECM.Collections(val.ID && val.ID === obj.ID)" | TableToMarkdown -Name "Collection List"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $output -RawResponse $Softwares
    }
    else
    {
        $output = @()
        $MDOutput = $output | TableToMarkdown -Name "Collection List"
        ReturnOutputs $MDOutput
    }
}
Function GetDeviceList($collection_id, $collection_name, $device_name, $resource_id, $threat_id, $threat_name)
{
    $usedParameterName = ValidateGetDeviceListParams $collection_id $collection_name $device_name $resource_id $threat_id $threat_name
    $parameters = @{
        usedParameterName = $usedParameterName
        collection_id = $collection_id
        collection_name = $collection_name
        device_name = $device_name
        resource_id = $resource_id
        threat_id = $threat_id
        threat_name = $threat_name
    }
    $Devices = Invoke-Command $global:Session -ArgumentList $parameters, $global:siteCode -ErrorAction Stop -ScriptBlock {
        param($parameters, $siteCode)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        switch ($parameters.usedParameterName)
        {
            "device_name" {
                Get-CMDevice -Name $parameters.device_name
            }
            "device_name&collection_name" {
                Get-CMDevice -CollectionName $parameters.collection_name -Name $parameters.device_name
            }
            "device_name&collection_id" {
                Get-CMDevice -CollectionId $parameters.collection_id -Name $parameters.device_name
            }
            "collection_id&threat_id" {
                Get-CMDevice -CollectionId $parameters.collection_id -ThreatId $parameters.threat_id
            }
            "collection_id&threat_name" {
                Get-CMDevice -CollectionId $parameters.collection_id -ThreatName $parameters.threat_name
            }
            "resource_id" {
                Get-CMDevice -ResourceId $parameters.resource_id
            }
            default {
                Get-CMDevice
            }
        }
    }
    if ($Devices)
    {
        $output = [PSCustomObject]@{
            "MicrosoftECM.Devices(val.ResourceID && val.ResourceID === obj.ResourceID)" = $Devices | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.Name
                    ClientVersion = $_.ClientVersion
                    CurrentLogonUser = $_.CurrentLogonUser
                    DeviceAccessState = $_.DeviceAccessState
                    DeviceCategory = $_.DeviceCategory
                    DeviceOS = $_.DeviceOS
                    DeviceOSBuild = $_.DeviceOSBuild
                    Domain = $_.Domain
                    IsActive = $_.IsActive
                    LastActiveTime = ParseDateTimeObjectToIso $_.LastActiveTime
                    LastHardwareScan = ParseDateTimeObjectToIso $_.LastHardwareScan
                    LastInstallationError = ParseDateTimeObjectToIso $_.LastInstallationError
                    LastLogonUser = $_.LastLogonUser
                    LastMPServerName = $_.LastMPServerName
                    MACAddress = $_.MACAddress
                    PrimaryUser = $_.PrimaryUser
                    ResourceID = $_.ResourceID
                    SiteCode = $_.SiteCode
                    Status = $_.Status
                }
            }
        }
        $MDOutput = $output."MicrosoftECM.Devices(val.ResourceID && val.ResourceID === obj.ResourceID)" | TableToMarkdown -Name "Devices List"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $output -RawResponse $Softwares | Out-Null
    }
    else
    {
        $output = @()
        $MDOutput = $output | TableToMarkdown -Name "Devices List"
        ReturnOutputs $MDOutput | Out-Null
    }
}

Function GetScriptList($author, $script_name)
{
    $scripts = Invoke-Command $global:Session -ArgumentList $author, $script_name, $global:SiteCode -ErrorAction Stop -ScriptBlock {
        param($author, $script_name, $SiteCode)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        $CMPSSuppressFastNotUsedCheck = $true
        if ($author -And $script_name)
        {
            Get-CMScript -Author $author -ScriptName $script_name
        }
        elseif ($author)
        {
            Get-CMScript -Author $author
        }
        elseif ($script_name)
        {
            Get-CMScript -ScriptName $script_name
        }
        else {
            Get-CMScript
        }
    }
    if ($scripts)
    {
        $output = [PSCustomObject]@{
            "MicrosoftECM.Scripts(val.ScriptGuid && val.ScriptGuid === obj.ScriptGuid)" = $scripts | ForEach-Object {
                [PSCustomObject]@{
                    ApprovalState = $SCRIPT_APPROVAL_STATE["$($_.ApprovalState)"]
                    Approver = $_.Approver
                    Author = $_.Author
                    Comment = $_.Comment
                    LastUpdateTime = ParseDateTimeObjectToIso $_.LastUpdateTime
                    Parameterlist = $_.Parameterlist
                    Script = [System.Text.Encoding]::UTF8.GetString(([System.Convert]::FromBase64String("$($_.Script)")|?{$_})).Substring(2)
                    ScriptGuid = $_.ScriptGuid
                    ScriptHash = $_.ScriptHash
                    ScriptHashAlgorithm = $_.ScriptHashAlgorithm
                    ScriptName = $_.ScriptName
                    ScriptType = $_.ScriptType
                    ScriptVersion = $_.ScriptVersion
                }
            }
        }
        $MDOutput = $output."MicrosoftECM.Scripts(val.ScriptGuid && val.ScriptGuid === obj.ScriptGuid)" | TableToMarkdown -Name "Scripts List"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $output -RawResponse $Softwares | Out-Null
    }
    else
    {
        $output = @()
        $MDOutput = $output | TableToMarkdown -Name "Scripts List"
        ReturnOutputs $MDOutput | Out-Null
    }
}

Function CreateScript($script_file_entry_id, $script_text, $script_name){
    $usedParameterName = ValidateCreateScriptParams $script_file_entry_id $script_text
    $script_path = ""
    if ($script_file_entry_id){
        $script_path = $demisto.GetFilePath($script_file_entry_id).path
        Copy-Item –Path $script_path –Destination "C:\$file_path" –ToSession $session
    }
    $script = Invoke-Command $global:Session -ArgumentList $global:SiteCode, $usedParameterName, $script_path, $script_text, $script_name -ErrorAction Stop -ScriptBlock {
        param($SiteCode, $usedParameterName, $script_path, $script_text, $script_name)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        $CMPSSuppressFastNotUsedCheck = $true
        switch ("$usedParameterName") {
            "script_path" {
                New-CMScript -ScriptFile "C:\$script_path" -ScriptName $script_name
            }
            "script_text" {
                New-CMScript -ScriptText $script_text -ScriptName $script_name
            }
        }
    }
    if ($script)
    {
        $output = [PSCustomObject]@{
            "MicrosoftECM.Scripts(val.ScriptGuid && val.ScriptGuid === obj.ScriptGuid)" = $script | ForEach-Object {
                [PSCustomObject]@{
                    ApprovalState = $SCRIPT_APPROVAL_STATE["$($_.ApprovalState)"]
                    Approver = $_.Approver
                    Author = $_.Author
                    Comment = $_.Comment
                    LastUpdateTime = ParseDateTimeObjectToIso $_.LastUpdateTime
                    Parameterlist = $_.Parameterlist
                    Script = [System.Text.Encoding]::UTF8.GetString(([System.Convert]::FromBase64String("$($_.Script)")|?{$_})).Substring(2)
                    ScriptGuid = $_.ScriptGuid
                    ScriptHash = $_.ScriptHash
                    ScriptHashAlgorithm = $_.ScriptHashAlgorithm
                    ScriptName = $_.ScriptName
                    ScriptType = $_.ScriptType
                    ScriptVersion = $_.ScriptVersion
                }
            }
        }
        $MDOutput = $output."MicrosoftECM.Scripts(val.ScriptGuid && val.ScriptGuid === obj.ScriptGuid)" | TableToMarkdown -Name "Scripts List"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $output -RawResponse $Softwares | Out-Null
    }
    else
    {
        $output = @()
        $MDOutput = $output | TableToMarkdown -Name "Scripts List"
        ReturnOutputs $MDOutput | Out-Null
    }
}

Function InvokeScript($script_guid, $collection_id, $collection_name, $device_name){
    AssertNoMoreThenOneParameterGiven "Can only use one of the following parameters: collection_id, collection_name, device_name" $collection_id $collection_name $device_name
    If (!($collection_id -Or $collection_name -Or $device_name)){
        throw "Must use one of the following parameters: collection_id, collection_name, device_name"
    }
    $InvokedScript = Invoke-Command $global:Session -ArgumentList $global:SiteCode, $script_guid, $collection_id, $collection_name, $device_name -ErrorAction Stop -ScriptBlock {
        param($SiteCode, $script_guid, $collection_id, $collection_name, $device_name)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        $CMPSSuppressFastNotUsedCheck = $true
        if ($collection_id){
            Invoke-CMScript -ScriptGuid $script_guid -CollectionId $collection_id -PassThru
        }
        elseif ($collection_name){
            Invoke-CMScript -ScriptGuid $script_guid -CollectionName $collection_name -PassThru
        }
        elseif ($device_name){
            $Device = Get-CMDevice -Name $device_name
            Invoke-CMScript -ScriptGuid $script_guid -Device $Device -PassThru
        }
    }
    if ($InvokedScript)
        {
        $output = [PSCustomObject]@{
            "MicrosoftECM.ScriptsInvocation(val.OperationID && val.OperationID === obj.OperationID)" = [PSCustomObject]@{
                    OperationID = $InvokedScript.OperationID
                    ReturnValue = "$($InvokedScript.ReturnValue)"
                }
            }
        $MDOutput = $output."MicrosoftECM.ScriptsInvocation(val.OperationID && val.OperationID === obj.OperationID)" | TableToMarkdown -Name "Script Invocation Result"
        ReturnOutputs -ReadableOutput $MDOutput -Outputs $output -RawResponse $Softwares | Out-Null
    }
    else
    {
        $output = @()
        $MDOutput = $output | TableToMarkdown -Name "Script Invocation Result"
        ReturnOutputs $MDOutput | Out-Null
    }
}

Function ApproveScript($script_guid, $comment){
    Invoke-Command $global:Session -ArgumentList $global:SiteCode, $script_guid, $comment -ErrorAction Stop -ScriptBlock {
        param($SiteCode, $script_guid, $comment)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        $CMPSSuppressFastNotUsedCheck = $true
        Approve-CMScript -ScriptGuid $script_guid -Comment $comment
    }
    $MDOutput = @() | TableToMarkdown -Name "Script Approved"
    ReturnOutputs $MDOutput | Out-Null
}

Function TestModule()
{
    Invoke-Command $global:Session -ArgumentList $global:SiteCode, $global:Creds -ErrorAction Stop -ScriptBlock {
        param($SiteCode, $Creds)
        Set-Location $env:SMS_ADMIN_UI_PATH\..\
        Import-Module .\ConfigurationManager.psd1
        Set-Location "$( $SiteCode ):"
        if ((Get-Module -Name ConfigurationManager).Version -eq $null)
        {
            throw "Could not find SCCM modules in the SCCM machine"
        }
        $Devices = Get-CMResource -ResourceType System -Fast|Where-Object { $_.Name -ne $env:computername } | ForEach-Object { $_.Name }
        # Checking Creds
        if ($Devices)
        {
            $SecurePassword = ConvertTo-SecureString -AsPlainText -Force -String $Creds.Password
            $Creds = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($Creds.UserName)", $SecurePassword
            $progressPreference = 'silentlyContinue'
            # $CheckCreds =
            Get-WmiObject -Class Win32_Product -ComputerName $Devices[0] -credential $Creds | Out-Null
        }
    }
}

function Main
{
    # Parse Params
    $computerName = $demisto.Params()['ComputerName']
    $userName = $demisto.Params()['UserName']
    $password = $demisto.Params()['password']
    $global:SiteCode = $demisto.Params()['SiteCode']
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securePassword
    $global:Session = New-PSSession -ComputerName $computerName -Authentication Negotiate -Credential $Creds -ErrorAction Stop
    $global:Creds = @{Password = $password; UserName = $userName }
    try
    {
        Switch ( $Demisto.GetCommand())
        {
            "test-module" {
                # $Demisto.Debug("Running test-module")
                TestModule | Out-Null
                ReturnOutputs "ok" | Out-Null
            }
            "ms-ecm-last-log-on-user" {
                $deviceName = $demisto.Args()['device_name']
                GetLastLogOnUser $deviceName | Out-Null
            }
            "ms-ecm-get-primary-user" {
                $deviceName = $demisto.Args()['device_name']
                GetPrimaryUser $deviceName | Out-Null
            }
            "ms-ecm-get-installed-softwares" {
                $deviceName = $demisto.Args()['device_name']
                ListInstalledSoftwares $deviceName | Out-Null
            }
            "ms-ecm-collection-list" {
                $collection_type = $demisto.Args()['collection_type']
                $collection_ID = $demisto.Args()['collection_id']
                $collection_name = $demisto.Args()['collection_name']
                $distribution_point_group_id = $demisto.Args()['distribution_point_group_id']
                $distribution_point_group_name = $demisto.Args()['distribution_point_group_name']
                GetCollectionList $collection_type $collection_ID $collection_name $distribution_point_group_id $distribution_point_group_name| Out-Null
            }
            "ms-ecm-device-list" {
                $collection_ID = $demisto.Args()['collection_id']
                $collection_name = $demisto.Args()['collection_name']
                $device_name = $demisto.Args()['device_name']
                $resource_id = $demisto.Args()['resource_id']
                $threat_id = $demisto.Args()['threat_id']
                $threat_name = $demisto.Args()['threat_name']
                GetDeviceList $collection_ID $collection_name $device_name $resource_id $threat_id $threat_name
            }
            "ms-ecm-scripts-list" {
                $author = $demisto.Args()['author']
                $script_name = $demisto.Args()['script_name']
                GetScriptList $author $script_name
            }
            "ms-ecm-script-create" {
                $script_file_entry_id = $demisto.Args()['script_file_entry_id']
                $script_text = $demisto.Args()['script_text']
                $script_name = $demisto.Args()['script_name']
                CreateScript $script_file_entry_id $script_text $script_name
            }
            "ms-ecm-script-invoke" {
                $script_guid = $demisto.Args()['script_guid']
                $collection_id = $demisto.Args()['collection_id']
                $collection_name = $demisto.Args()['collection_name']
                $device_name = $demisto.Args()['device_name']
                InvokeScript $script_guid $collection_id $collection_name $device_name
            }
            "ms-ecm-script-approve" {
                $script_guid = $demisto.Args()['script_guid']
                $comment = $demisto.Args()['comment']
                ApproveScript $script_guid $comment
            }
        }
    }
    catch
    {
        ReturnError -Message "Something has gone wrong in MicrosoftECM.ps1:Main() [$( $_.Exception.Message )]" -Err $_ | Out-Null
        return
    }
}

# Execute Main when not in Tests
if ($MyInvocation.ScriptName -notlike "*.tests.ps1" -AND -NOT$Test)
{
    Main
}
