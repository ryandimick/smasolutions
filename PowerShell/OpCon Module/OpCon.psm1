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

Write-Verbose (ConvertTo-Json $tokenObject)

try
{
    Ignore-SelfSignedCerts
    $token = Invoke-RestMethod -Method Post -Uri $tokensUri -Body (ConvertTo-Json $tokenObject) -ContentType "application/json"
}
catch
{
    Write-Host ("Unable to fetch token for user '" + $user + "'")
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
	exit $_.Exception.Response.StatusCode.value__
}

Write-Host ("Token retrieved successfully, Id: " + $token.id + ", Valid Until: " + $token.validUntil)
return $token
}

function Get-OpConApiAuthHeader {
param(
    [string] $Token
    )
    $authHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $authHeader.Add("Authorization", ("Token " + $Token))
    return $authHeader
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
function Login-OpConApi {
[cmdletbinding()]
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
    function Set-OpconProperty {
       param(
            [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
            [ValidateNotNullorEmpty()]
            [String]$Name,
            [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
            [ValidateNotNullorEmpty()]
            [String]$Value
        )
    $globalProperty = Get-OpConProperty -Name $Name
    if ($globalProperty -ne $null)
    {
        $globalProperty = Update-OpConProperty -Id $globalProperty.id -Name $Name -Value $Value
    }
    else
    {
        ##exit 1
    }
    return $globalProperty
}

function Get-OpConProperty {
param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name
    )

$uri = "api/globalproperties?name=" + $Name

Write-Host ("`n")
Write-Host ("Fetching Global Property '" + $Name + "'...") 

$globalProperties = Invoke-OpConRestMethod -Method Get -Uri $uri

if ($globalProperties -ne $null)
{
    return $globalProperties
}           
else
{
    Write-Host ("Global property '" + $Name + "' not found")
    return $null
}
}

function Add-OpConProperty {
    param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Value
    )
    $globalProperty = Get-OpConProperty -Name $Name
    if ($globalProperty -ne $null)
    {
        Write-Host("`n")
        Write-Host("Global Property '" + $globalProperty.name + "' exists.")
        $globalProperty = Update-OpConProperty -Id $globalProperty.id -Name $Name -Value $Value
    }
    else
    {
        $globalProperty = Create-OpConProperty -Name $Name -Value $Value
    }
    return $globalProperty
}

function Update-OpConProperty {
    param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Id,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Value
    )
    $uri = "api/globalproperties/" + $Id
    Write-Host("`n")
    Write-Host ("Updating Global Property with Id '" + $Id + "' to Name of '" + $Name + "' and Value of '" + $Value + "'")
    $globalProperty = @{
        id = $Id
        name = $Name
        value = $Value
    }
    $globalProperty = Invoke-OpConRestMethod -Method Put -Uri $uri -Body $globalProperty
    return $globalProperty
}

function Create-OpConProperty {
    param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Value
    )
    $uri = "api/globalproperties"
    Write-Host("`n")
    Write-Host("Creating Global Property '" + $Name + "' with value of '" + $Value + "'")
    $globalProperty = @{
        name = $Name
        value = $Value
    }
    Write-Host ($globalProperty.GetType())
    $globalProperty = Invoke-OpConRestMethod -Method Post -Uri $uri -Body $globalProperty
    return $globalProperty
}

function Invoke-OpConRestMethod {
    param(
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Uri,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [String]$Method,
        [object]$Body = $null
    )

    $uri = $Global:OpconRESTApiUrl + $Uri
    
    Write-Verbose("Sending Web Request...")
    try
    {
        if ($Body -eq $null)
        {
            $response = Invoke-RestMethod -Method $Method -Uri $uri -Headers $Global:OpconRESTApiAuthHeader 
        }
        else
        {
            $Body = ConvertTo-Json $Body
            Write-Verbose $Body
            $response = Invoke-RestMethod -Method $Method -Uri $uri -Headers $Global:OpconRESTApiAuthHeader -Body $Body -ContentType "application/json"
        }
        Write-Verbose ("`n")
        Write-Verbose("RESPONSE:")
        Write-Verbose(ConvertTo-Json $response)
        return $response
    }
    catch
    {
        Write-Host ("Error")
        Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
	    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
	    ##exit $_.Exception.Response.StatusCode.value__
    }
}

function Create-OpconServiceRequest 
{
param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'Complete Service Request object to create', ValueFromPipeLine = $true)]
        [object]$serviceRequest,
        [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Name of the property',ValueFromPipeline = $true)]
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
                [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$event = 'true',
                [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$trackExecutions = 'false',
                        [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$useOcadm = 'false',
                                [Parameter(Mandatory = $false,Position = 0,HelpMessage = 'Value to set the property equal to',ValueFromPipeline = $true)]
        [ValidateNotNullorEmpty()]
        [string]$roleIds = $null
                
        ##[string]$ApiUrl = $Global:OpconRESTApiUrl,
        ##[string]$ApiToken = $Global:OpconRESTApiToken
        )
        
        if ($serviceRequest -ne $null)
        {
        Write-Host ('Overwriting ID')
            $serviceRequest.id = 0
        }
        else
        {
    
    $details = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><request><xml_version>1</xml_version><confirmed>' + $confirmationMessage + '</confirmed><send_as_ocadm>' + $useOcadm + '</send_as_ocadm><events><event>' + $event + '</event></events><track_event_executions>' + $trackExecutions + '</track_event_executions><variables/></request>'

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
   elseif ($roleIds -ne $null)
   {
    $roleslArray = New-Object System.Collections.ArrayList
    $roleIds.Split(",") | ForEach-Object -Process { $rolesArray.Add( @{id = [int]$_})} 
    Write-Host $rolesArray
    Write-Host (ConvertTo-Json $rolesArray)
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

Export-ModuleMember -Function Login-OpConApi
Export-ModuleMember -Function Set-OpconProperty
Export-ModuleMember -Function Get-OpConProperty
Export-ModuleMember -Function Add-OpConProperty
Export-ModuleMember -Function Create-OpConServiceRequest