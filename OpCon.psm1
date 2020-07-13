function Ignore-SelfSignedCerts {
    add-type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}






function Get-OpConApiToken {
[cmdletbinding()]
param(
    [string] $Url,
    [string] $User,
    [string] $Password
    )
$tokensUri = -join($Url, "api/tokens")
Write-Host ("Retrieving authorization token...")
Write-Host ("Uri: " + $tokensUri)
Write-Host ("User: " + $User)
$tokenObject = @{
    user = @{
        loginName = $User
        password = $Password
    }
    tokenType = @{
        type = "User"
    }
}
try
{
    Ignore-SelfSignedCerts
    $token = Invoke-RestMethod -Method Post -Uri $tokensUri -Body (ConvertTo-Json $tokenObject) -ContentType "application/json"
}
catch
{
    $error = ConvertFrom-Json $_.ErrorDetails.Message
    Write-Host ("Unable to fetch token for user '" + $user + "'")
    Write-Host ("Error Code: " + $error.code)
    Write-Host ("Message: " + $error.message)
    ##Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    ##Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##Write-Host ("Message: " + $_[0].message)
    ##$Global:OpConRESTAPIException = $_
    throw
    ##exit $_.Exception.Response.StatusCode.value__
}
Write-Host ("Token retrieved successfully, Id: " + $token.id + ", Valid Until: " + $token.validUntil)
return $token
}
<# 
 .Synopsis
  Logs in to an OpCon REST API instance and stores a token for 
  future usage in the session.
 .Description
  Logs in to an OpCon REST API instance.  Stores values so
  subsequent calls can be made in the session without having
  to retrieve a token on each call.
 .Parameter Url
  The base path of the OpCon REST API to authenticate to.
 .Parameter User
  The OpCon username to authenticate with.
 .Parameter Password
  The Opcon application password for the provided user.
 .Example
   # Show a default display of this month.
   Show-Calendar
 .Example
   # Display a date range.
   Show-Calendar -Start "March, 2010" -End "May, 2010"\
 .Example
   # Highlight a range of days.
   Show-Calendar -HighlightDay (1..10 + 22) -HighlightDate "December 25, 2008"
#>


function Get-OpConApiAuthHeader {
param(
    [string] $Token
    )
    $authHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $authHeader.Add("Authorization", ("Token " + $Token))
    return $authHeader
}


function Login-OpConApi {






param(
    [string] $ApiUrl,
    [string] $OpConUser,
    [string] $OpConPassword
    )
    $Global:OpconRESTApiUrl = $ApiUrl
    $Global:OpconRESTApiUser = $OpConUser
    $Global:OpConRESTApiPassword = $OpConPassword
    $token = Get-OpConApiToken -Url $ApiUrl -User $OpConUser -Password $OpConPassword
    $Global:OpconRESTApiToken = $token.id

    $authHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $authHeader.Add("Authorization", ("Token " + $Global:OpconRESTApiToken))
    $Global:OpconRESTApiAuthHeader = Get-OpConApiAuthHeader -Token $token.id
    Write-Host 'Token successfully stored for future calls in session.'
}

<# 
 .Synopsis
  Logs in to an OpCon REST API instance and stores a token for 
  future usage in the session.
 .Description
  Logs in to an OpCon REST API instance.  Stores values so
  subsequent calls can be made in the session without having
  to retrieve a token on each call.
 .Parameter Url
  The base path of the OpCon REST API to authenticate to.
 .Parameter User
  The OpCon username to authenticate with.
 .Parameter Password
  The Opcon application password for the provided user.
 .Example
   # Show a default display of this month.
   Show-Calendar
 .Example
   # Display a date range.
   Show-Calendar -Start "March, 2010" -End "May, 2010"
 .Example
   # Highlight a range of days.
   Show-Calendar -HighlightDay (1..10 + 22) -HighlightDate "December 25, 2008"
#>





function Set-OpConGlobalProperty {





param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Value,
        [string]$ApiUrl = $Global:OpconRESTApiUrl,
        [string]$ApiToken = $Global:OpconRESTApiToken
    )
    $globalProperty = Get-OpConGlobalProperty -Name $Name

if ($globalProperty -ne $null)

{

    # Update global property
    $globalProperty = @{
	    id = $globalProperty.id
        name = $Name
        value = $Value
    }
      $globalPropertyUri = ($ApiUrl + "/api/globalproperties/" + $globalProperty.id)
	try
	{
        $globalProperty = Invoke-RestMethod -Method Put -Uri $globalPropertyUri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $globalProperty) -ContentType "application/json"
	}
	catch
	{
        Write-Host ("Unable to update property " + $propertyName)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Global property with id " + $globalProperty.id + " updated")
 
        return $globalProperty
}
else
{
    Write-Host ("Global property " + $propertyName + " does not exist. Creating...")

    
}

}

<#
.SYNOPSIS

Logs into the OpCon RESTapi and sets the value of a Global Property.

.DESCRIPTION

Logs into the OpCon RESTapi and sets the value of a Global Property.

.PARAMETER Name
Specifies the name of the property to be updated.

.PARAMETER Value
Specifies the value to be stored for Global Property.

.EXAMPLE

C:\PS> Set-OpConGlobalProperty -Name PropertyName -Value ValueToBeStored


#>


function Get-OpConGlobalProperty {



param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [string]$ApiUrl = $Global:OpconRESTApiUrl,
        [string]$ApiToken = $Global:OpconRESTApiToken
    )
$globalPropertiesUri = -join($Global:OpconRESTApiUrl, "api/globalproperties?name=", $Name)
Write-Host ("")
Write-Host ("Connecting to: " + $globalPropertiesUri)
try
{
    $globalProperties = Invoke-RestMethod -Method Get -Uri $globalPropertiesUri -Headers $Global:OpconRESTApiAuthHeader
     if($globalProperties.Count -gt 0)
    {
        $property = $globalProperties
        return $property
    }
    else
    {
        Write-Host("global property '" + $Name + "' not found")
        return $null
    }
}
catch
{
    Write-Host ("Unable to fetch property " + $propertyName)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}
}
function Get-OpConThreshold

{
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
    )

$Uri = -join($Global:OpconRESTApiUrl, "api/thresholds?name=", $Name)

Write-Host ("Connecting to: " + $Uri)
try
{
    $thresholds = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
     if($thresholds.Count -gt 0)
    {
        $threshold = $thresholds[0]
        return $threshold
    }
    else
    {
        Write-Host("Threshold '" + $Name + "' not found")
        return $null
    }
}
catch
{
    Write-Host ("Unable to fetch threshold " + $name)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}





}

function Create-OpConThreshold

{
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Value
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

        
    

    # add Threshold
    $Threshold = @{
	    
        name = $Name
        value = $Value
        id = 0
   }
      $Uri = ($Global:OpconRESTApiUrl + "/api/thresholds")
	try
	{
        $threshold = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $Threshold) -ContentType "application/json"
	}
	catch
	{
        Write-Host ("Unable to add threshold " + $Name)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Threshold with id " + $threshold.id + " created.")
    
        return $threshold 

    



}

function Set-OpconThreshold {





param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Value,
        [string]$ApiUrl = $Global:OpconRESTApiUrl,
        [string]$ApiToken = $Global:OpconRESTApiToken
    )
    $threshold = Get-OpConThreshold -Name $Name

if ($threshold -ne $null)

{

    # Update threshold
    $threshold = @{
	    id = $threshold.id
        name = $Name
        value = $Value
    }
      $Uri = ($ApiUrl + "/api/thresholds/" + $threshold.id)
	try
	{
        $threshold = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $threshold) -ContentType "application/json"
	}
	catch
	{
        Write-Host ("Unable to update threshold " + $propertyName)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Threshold with id " + $threshold.id + " updated")
 
        return $threshold
}
else
{
    Write-Host ("Threshold " + $Name + " does not exist. Creating...")

    
}

}


function Add-OpconProperty {





param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Value
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
    )
    $globalProperty = Get-OpConGlobalProperty -Name $Name

if ($globalProperty -ne $null)

{

    # Update global property
    $globalProperty = @{
	    id = $globalProperty.id
        name = $Name
        value = $Value
    }
      $globalPropertyUri = ($Global:OpconRESTApiUrl + "/api/globalproperties/" + $globalProperty.id)
	try
	{
        $globalProperty = Invoke-RestMethod -Method Put -Uri $globalPropertyUri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $globalProperty) -ContentType "application/json"
	}
	catch
	{
        Write-Host ("Unable to update property " + $propertyName)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Global property with id " + $globalProperty.id + " updated")
    
        return $globalProperty
}
else
{
    

    # add Global Property
    $globalProperty = @{
	    
        name = $Name
        value = $Value
   }
      $globalPropertyUri = ($Global:OpconRESTApiUrl + "/api/globalproperties")
	try
	{
        $globalProperty = Invoke-RestMethod -Method Post -Uri $globalPropertyUri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $globalProperty) -ContentType "application/json"
	}
	catch
	{
        Write-Host ("Unable to add property " + $propertyName)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Global property with id " + $globalProperty.id + " created.")
    
        return $globalProperty 

    
}
}


function Get-OpConResource

{
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
    )

$Uri = -join($Global:OpconRESTApiUrl, "api/resources?name=", $Name)

Write-Host ("Connecting to: " + $Uri)
try
{
    $resources = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
     if($resources.Count -gt 0)
    {
        $resource = $resources[0]
        return $resource
    }
    else
    {
        Write-Host("Resource '" + $Name + "' not found")
        return $null
    }
}
catch
{
    Write-Host ("Unable to fetch resource " + $name)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}





}

function Create-OpConResource

{
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Value
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

        
    

    # add Resource
    $Resource = @{
	    
        name = $Name
        value = $Value
        id = 0
   }
      $Uri = ($Global:OpconRESTApiUrl + "/api/resources")
	try
	{
        $resource = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $Resource) -ContentType "application/json"
	}
	catch
	{
        Write-Host ("Unable to add resource " + $Name)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Resource with id " + $resource.id + " created.")
    
        return $resource 

    



}

function Set-OpconResource {





param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Value,
        [string]$ApiUrl = $Global:OpconRESTApiUrl,
        [string]$ApiToken = $Global:OpconRESTApiToken
    )
    $resource = Get-OpConResource -Name $Name

if ($resource -ne $null)

{

    # Update resource
    $resource = @{
	    id = $resource.id
        name = $Name
        value = $Value
    }
      $Uri = ($ApiUrl + "/api/resources/" + $resource.id)
	try
	{
        $resource = Invoke-RestMethod -Method Put -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $resource) -ContentType "application/json"
	}
	catch
	{
        Write-Host ("Unable to update resource " + $resource)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Resource with id " + $resource.id + " updated")
 
        return $resource
}
else
{
    Write-Host ("Resource " + $Name + " does not exist. Creating...")

    
}
}


function Get-OpConVersion

{


$Uri = -join($Global:OpconRESTApiUrl, "api/version")

Write-Host ("Connecting to: " + $Uri)
try
{
    $version = Invoke-RestMethod -Method Get -Uri $Uri
    
   if ($version -eq $null)
        {
            Write-Host ("Error retrieving version")
        }
    else
    {
        $v = Get-OpConVersion
        Write-Host ($v.opConRestApiProductVersion)
    }

   return $version
}
catch
{
    Write-Host ("Unable to fetch version " + $Name)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}
}

function Get-OpConMachine

{



param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name
        #[string]$ApiUrl = $Global:OpconRESTApiUrl,
        #[string]$ApiToken = $Global:OpconRESTApiToken
    )
        $Uri = -join($Global:OpconRESTApiUrl, "api/machines?name=", $Name)
Write-Host ("")
Write-Host ("Connecting to: " + $Uri)
try
{
    $machines = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
     if($machines.Count -gt 0)
    {
        $machine = $machines
        return $machine
    }
    else
    {
        Write-Host("Machine '" + $Name + "' not found")
        return $null
    }
}
catch
{
    Write-Host ("Unable to fetch machine " + $Name)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}
}





function Create-OpConMachine
{
param(
           [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [int]$MachineType,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [int]$SocketNumber,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [boolean]$AllowJobKill = $false,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$fileTransferRole,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [int]$jorsPortNumber,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$fileTransferPortNumberForNonTLS,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$fileTransferPortNumberForTLS
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiTo
        )

        
    

    # add Machine
    $Machine = @{
	    
        name = $Name
        type = @{id = $MachineType
        }
        id = 0
        socket = $SocketNumber
        allowKillJob = $AllowJobKill
        fileTransferRole = $fileTransferRole
        jorsPortNumber = $jorsPortNumber
        fileTransferPortNumberForNonTLS = $fileTransferPortNumberForNonTLS
        fileTransferPortNumberForTLS = $fileTransferPortNumberForTLS

   }
      $Uri = ($Global:OpconRESTApiUrl + "/api/machines")
	try
	{
        $Machine = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $Machine) -ContentType "application/json"
	}
	catch
	{
        Write-Host ("Unable to add machine " + $Name)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Machine with id " + $Machine.id + " created.")
    
        return $Machine 




}


function Get-OpConMachineList

{


$Uri = -join($Global:OpconRESTApiUrl, "api/machines")

Write-Host ("Connecting to: " + $Uri)
try
{
    $machines = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
    
   if ($machines -eq $null)
        {
            Write-Host ("Error retrieving machines")
        }
    

   return $machines
}
catch
{
    Write-Host ("Unable to fetch machine list")
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}
}


function Get-OpConServiceRequestList

{
param(
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [Boolean]$includeRoles = $false
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
    )

$Uri = -join($Global:OpconRESTApiUrl, "api/ServiceRequests")

if ($includeRoles)
{
    $Uri = -join($Uri,"?includeRoles=true")
}
Write-Host ("Connecting to: " + $Uri)
try
{
    $serviceRequests = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
    
   if ($serviceRequests -eq $null)
        {
            Write-Host ("Error retrieving service requests")
        }
    

   return $serviceRequests
}
catch
{
    Write-Host ("Unable to fetch service requests")
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}
}


function Get-OpConServiceRequest

{
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
    )

$Uri = -join($Global:OpconRESTApiUrl, "api/ServiceRequests?name=", $Name)

Write-Host ("Connecting to: " + $Uri)
try
{
    $serviceRequest = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
     if($serviceRequest.Count -gt 0)
    {
        $serviceRequest = $serviceRequest[0]
        return $serviceRequest
    }
    else
    {
        Write-Host("Service Request '" + $Name + "' not found")
        return $null
    }
}
catch
{
    Write-Host ("Unable to fetch servie request " + $name)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}

}

function Create-OpconServiceRequest 
{
param(
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$documentation,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$html,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [object]$disabled,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$disableRule,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [object]$hidden,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$hiddenRule,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [object]$serviceRequestCategory,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [object[]]$roles,
                [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$confirmationMessage = 'true',
                [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string[]]$events = 'true',
                [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$trackExecutions = 'false',
                        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$useOcadm = 'false',
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [object]$serviceRequest 
                
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )
        
    if ($serviceRequest-ne $null)
    {
        $serviceRequest.id = 0
    }
    else
    {
        
    
    $events = $events -join "</event><event>"
    $details = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><request><xml_version>1</xml_version><confirmed>' + $confirmationMessage + '</confirmed><send_as_ocadm>' + $useOcadm + '</send_as_ocadm><events><event>' + $events + '</event></events><track_event_executions>' + $trackExecutions + '</track_event_executions><variables/></request>'
    # add Service Request
    $serviceRequest = @{
        
        name = $Name
        documentation = $documentation
        html = $html
        details = $details
        disableRule = $disableRule
        hiddenRule = $hiddenRule
        id = 0
        roles = @( @{ id = 0 })
   }
   if ($disabled -ne $null)
   {
     $serviceRequest.disabled = $disabled
   }
   if ($hidden -ne $null)
   {
    $serviceRequest.hidden = $hidden
   }
   if ($serviceRequestCategory -ne $null)
   {
    $serviceRequest.serviceRequestCategory = $serviceRequestCategory
   }
   if ($roles -ne $null)
   {
    $serviceRequest.roles = $roles 
   }

   }
      
    $Uri = ($Global:OpconRESTApiUrl + "/api/serviceRequests")
    
try
    {
        $body = convertto-json $serviceRequest
        write-verbose $body
        $serviceRequest = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader -Body $body -ContentType "application/json"
        
    }
    catch
    {
        Write-Host ("Unable to add Service Request " + $Name)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
        Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        Write-Host ($_.Exception.InnerMessage | Format-Table | Out-String)
        ##exit $_.Exception.Response.StatusCode.value__
    }
    
    
        return $serviceRequest
            
}
 


function Get-OpConServiceRequestCategoryList

{


$Uri = -join($Global:OpconRESTApiUrl, "api/ServiceRequestCategories")

Write-Host ("Connecting to: " + $Uri)
try
{
    $serviceRequestCategories = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
    
   if ($serviceRequestCategories -eq $null)
        {
            Write-Host ("Error retrieving service request categories")
        }
    

   return $serviceRequestCategories
      
}
catch
{
    Write-Host ("Unable to fetch service request categories")
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}
}


function Get-OpConServiceRequestCategory

{
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
    )

$Uri = -join($Global:OpconRESTApiUrl, "api/ServiceRequestCategories?name=", $Name)

Write-Host ("Connecting to: " + $Uri)
try
{
    $serviceRequestCategory = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
     if($serviceRequestCategory.Count -gt 0)
    {
        $serviceRequestCategory = $serviceRequestCategory[0]
        return $serviceRequestCategory
    }
    else
    {
        Write-Host("Service Request Category'" + $Name + "' not found")
        return $null
    }
}
catch
{
    Write-Host ("Unable to fetch servie request category " + $name)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}

}

function Create-OpconServiceRequestCategory 

{
param(
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Color        
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

        
    

    # add Category
    $serviceRequestCategory = @{
	    
        name = $Name
        color = $Color
        id = 0
   }
      $Uri = ($Global:OpconRESTApiUrl + "/api/ServiceRequestCategories")
	try
	{
        $serviceRequestCategory = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $serviceRequestCategory) -ContentType "application/json"
	}
	catch
	{
        Write-Host ("Unable to add Service Request Category " + $Name)
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Serivce Request Category with id " + $serviceRequestCategory.id + " created.")
    
        return $serviceRequestCategory
            
}


function Get-OpConRoleList

{


$Uri = -join($Global:OpconRESTApiUrl, "api/Roles")

Write-Host ("Connecting to: " + $Uri)
try
{
    $roleList = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
    
   if ($roleList -eq $null)
        {
            Write-Host ("Error retrieving role list")
        }
    

   return $roleList
}
catch
{
    Write-Host ("Unable to fetch role list")
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}
}

function Get-OpConRole

{
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
    )

$Uri = -join($Global:OpconRESTApiUrl, "api/Roles?name=", $Name)

Write-Host ("Connecting to: " + $Uri)
try
{
    $role = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
     if($role.Count -gt 0)
    {
        $role = $role[0]
        return $role
    }
    else
    {
        Write-Host("Role '" + $Name + "' not found")
        return $null
    }
}
catch
{
    Write-Host ("Unable to fetch role " + $name)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}

}

function Get-OpConUserList

{


$Uri = -join($Global:OpconRESTApiUrl, "api/Users")

Write-Host ("Connecting to: " + $Uri)
try
{
    $userList = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
    
   if ($userList -eq $null)
        {
            Write-Host ("Error retrieving user list")
        }
    

   return $userList
}
catch
{
    Write-Host ("Unable to fetch user list")
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}
}

function Get-OpConUser

{
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
    )

$Uri = -join($Global:OpconRESTApiUrl, "api/Users?name=", $Name)

Write-Host ("Connecting to: " + $Uri)
try
{
    $user = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
     if($user.Count -gt 0)
    {
        $user = $user[0]
        return $user
    }
    else
    {
        Write-Host("User '" + $Name + "' not found")
        return $null
    }
}
catch
{
    Write-Host ("Unable to fetch user " + $name)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}

}

function Get-OpConBatchUserList

{


$Uri = -join($Global:OpconRESTApiUrl, "api/batchusers")

Write-Host ("Connecting to: " + $Uri)
try
{
    $batchUserList = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
    
   if ($BatchUserList -eq $null)
        {
            Write-Host ("Error retrieving user list")
        }
    

   return $BatchUserList
}
catch
{
    Write-Host ("Unable to fetch Batch User list")
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}
}

function Get-OpConBatchUser

{
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
    )

$Uri = -join($Global:OpconRESTApiUrl, "api/batchusers?name=", $Name)

Write-Host ("Connecting to: " + $Uri)
try
{
    $BatchUser = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader
     if($BatchUser.Count -gt 0)
    {
        $BatchUser = $BatchUser[0]
        return $BatchUser
    }
    else
    {
        Write-Host("Batch User '" + $Name + "' not found")
        return $null
    }
}
catch
{
    Write-Host ("Unable to fetch Batch user " + $name)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    ##exit $_.Exception.Response.StatusCode.value__

}

}


function Post-OpConJobAction 

{
param(
          
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason,  
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [object]$jobAction  
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

        
    

    # add Category

    $jobArray = New-Object System.Collections.ArrayList
    $jobs | ForEach-Object -Process {$jobArray.Add(@{id = $_})}

    $jobAction = @{
	    
        action = $jobAction
        jobs = $jobArray 
        reason = $reason 
   }
        Write-Verbose (ConvertTo-Json $jobAction)
      $Uri = ($Global:OpconRESTApiUrl + "/api/jobactions")
	try
	{
        $jobAction = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $jobAction) -ContentType "application/json"
	}
	catch
	{
        Write-Warning ("Error")
        Write-Warning ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
        Write-Warning ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        $opconApiError = ConvertFrom-Json $_.ErrorDetails.Message
        Write-Warning ("ErrorCode: " + $opconApiError.code)
        Write-Warning ("ErrorMessage: " + $opconApiError.message)
        ##exit $_.Exception.Response.StatusCode.value__
	}
    Write-Host ("Job Action " + $jobAction + " created.")
    
        return $jobAction
            
}
Function Hold-OpConJob

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "hold"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}

Function Release-OpConJob 

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "release"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}

Function Cancel-OpConJob 

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "cancel"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}

Function Skip-OpConJob 

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "skip"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}

Function Kill-OpConJob 

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "kill"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}
Function Start-OpConJob 

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "start"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}

Function ForceRestart-OpConJob 

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "forceRestart"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}

Function RestartOnHold-OpConJob 

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "restartOnHold"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}

Function MarkFinishedOK-OpConJob 

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "markFinishedOK"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}

Function MarkFailed-OpConJob 

{
param(
          
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String[]]$jobs,
        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$reason         
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )

$jobAction = "markFailed"
$result = Post-OpConJobAction -jobAction $jobAction -jobs $jobs -reason $reason
return $result


}



function Post-OpConScheduleAction 
{
param(
         
       [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
       [ValidateNotNullorEmpty()]
       [String]$schedule,       
       [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
       [String[]]$jobs,
       [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
       [ValidateNotNullorEmpty()]
       [String]$reason,  
       [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
       [ValidateNotNullorEmpty()]
       [string]$scheduleAction  
       )
       
   
   # add Category
   $jobArray = New-Object System.Collections.ArrayList
   $jobs | ForEach-Object -Process {$jobArray.Add(@{id = $_})}
   $body = @{
       scheduleActionItems = @( @{
            id = $schedule
            }
        )
       action = $scheduleAction
       reason = $reason 
  }
       Write-Verbose (ConvertTo-Json $body)
     $Uri = ($Global:OpconRESTApiUrl + "/api/scheduleActions")
try
{
       $scheduleAction = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Global:OpconRESTApiAuthHeader -Body (ConvertTo-Json $body) -ContentType "application/json"
}
catch
{
       Write-Warning ("Error")
       Write-Warning ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
       Write-Warning ("StatusDescription: " + $_.Exception.Response.StatusDescription)
       $opconApiError = ConvertFrom-Json $_.ErrorDetails.Message
       Write-Warning ("ErrorCode: " + $opconApiError.code)
       Write-Warning ("ErrorMessage: " + $opconApiError.message)
       ##exit $_.Exception.Response.StatusCode.value__
}
   Write-Host ("Schedule Action " + $scheduleAction + " created.")
   
       return $scheduleAction
           
}         


function Hold-OpConSchedule 
{
param(
         
       [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
       [ValidateNotNullorEmpty()]
       [String]$schedule, 
       [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
       [ValidateNotNullorEmpty()]
       [String]$reason         
       )
$scheduleAction = "hold"
$result = Post-OpConScheduleAction -scheduleAction $scheduleAction -schedule $schedule -reason $reason
return $result

}


Export-ModuleMember -Function Get-Token ##this should be removed, just doing for testing
Export-ModuleMember -Function Login-OpConApi
Export-ModuleMember -Function Set-OpConGlobalProperty
Export-ModuleMember -Function Get-OpConGlobalProperty
Export-ModuleMember -Function Add-OpConProperty
Export-ModuleMember -Function Get-OpConThreshold
Export-ModuleMember -Function Create-OpConThreshold
Export-ModuleMember -Function Set-OpConThreshold
Export-ModuleMember -Function Get-OpConResource
Export-ModuleMember -Function Create-OpConResource
Export-ModuleMember -Function Set-OpConResource
Export-ModuleMember -Function Get-OpConVersion
Export-ModuleMember -Function Get-OpConMachine
Export-ModuleMember -Function Create-OpConMachine
Export-ModuleMember -Function Get-OpConMachineList
Export-ModuleMember -Function Get-OpConServiceRequestList
Export-ModuleMember -Function Get-OpConServiceRequest
Export-ModuleMember -Function Get-OpConServiceRequestCategoryList
Export-ModuleMember -Function Get-OpConServiceRequestCategoryget
Export-ModuleMember -Function Create-OpconServiceRequestCategory
Export-ModuleMember -Function Create-OpconServiceRequest
Export-ModuleMember -Function Get-OpConRoleList
Export-ModuleMember -Function Get-OpConRole
Export-ModuleMember -Function Get-OpConUserList
Export-ModuleMember -Function Get-OpConUser
Export-ModuleMember -Function Get-OpConBatchUserList
Export-ModuleMember -Function Get-OpConBatchUser
Export-ModuleMember -Function Hold-OpConJob
Export-ModuleMember -Function Release-OpConJob
Export-ModuleMember -Function Hold-OpConJob
Export-ModuleMember -Function Cancel-OpConJob
Export-ModuleMember -Function Skip-OpConJob
Export-ModuleMember -Function Kill-OpConJob
Export-ModuleMember -Function Start-OpConJob
Export-ModuleMember -Function ForceRestart-OpConJob
Export-ModuleMember -Function RestartOnHold-OpConJob
Export-ModuleMember -Function MarkFinishedOK-OpConJob
Export-ModuleMember -Function MarkFailed-OpConJob
Export-ModuleMember -Function PostOpConScheduleAction
Export-ModuleMember -Function Hold-OpConSchedule




















