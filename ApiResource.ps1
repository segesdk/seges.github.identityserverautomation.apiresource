[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $ClientId,
    [Parameter(Mandatory=$true)]
    [string]
    $ClientSecret,
    [Parameter(Mandatory=$true)]
    [string]
    $IdentityServerUrl,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceName,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceReferenceName,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceDisplayName,
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceEnvironment,
    [Parameter(Mandatory=$true)]
    [string]
    $ScopeNames,
    [Parameter(Mandatory=$true)]
    [string]
    $ScopeDisplayNames,
    [Parameter(Mandatory=$false)]
    [string]
    $UserClaims,
    [Parameter(Mandatory=$false)]
    [string]
    $RoleFilter
    

)

#requires -PSEdition Core


Set-StrictMode -Off
$here = Split-Path -Parent $MyInvocation.MyCommand.Path


. "$here\_IdentityServerCommon.ps1"

Write-Host "here: $here"

# Mandatory parameters
Confirm-NotEmptyString ($ClientId)
write-host "sovs1"
Confirm-NotEmptyString ($ClientSecret)
write-host "sovs1"
Confirm-AbsoluteUrl ($IdentityserverUrl)
write-host "sovs1"
Confirm-NotEmptyString ($ResourceEnvironment)
write-host "sovs1"
Confirm-AbsoluteUrl ($ResourceName)
write-host "sovs1"
Confirm-LowerCase ($ResourceName)
write-host "sovs1"
Write-Host "ResourceName: $ResourceName"

if (!$ResourceName.EndsWith("/"))
{
    throw "IdsrvResourceName must end with '/'"
}

Confirm-NotEmptyString ($ResourceReferenceName)

Confirm-NotEmptyString ($ResourceDisplayName)

# Optional parameters
if(-not [string]::IsNullOrEmpty($UserClaims))
{
    Confirm-LowerCase ($UserClaims)
}

Confirm-LowerCase ($ResourceEnvironment)
Confirm-NotEmptyString ($ResourceEnvironment)

Confirm-NotEmptyString ($ScopeNames)

Confirm-NotEmptyString ($ScopeDisplayNames)

$scopeNamesArray = $ScopeNames.Split(",")
$scopeDisplayNamesArray = $ScopeDisplayNames.Split(",")

if ($scopeNamesArray.count -ne $scopeDisplayNamesArray.count)
{
    throw "Count of elements in APIScopeNames and APIScopeDisplayNames must be the same"
}


$name = "$($ResourceEnvironment.ToUpper()) $ResourceName - $ResourceReferenceName";

Write-Host "Running ApiResource.ps1:"
Write-Host "Name: $name"

$accesToken = GetAccesToken $IdentityserverUrl $ClientId $ClientSecret

$apiResource = @{Name = $ResourceName; LogicalName = $ResourceReferenceName; Environment = $ResourceEnvironment; DisplayName = $ResourceDisplayName; RoleFilter = $RoleFilter}

$apiScopeArray = [System.Collections.ArrayList]::new()

for ($index = 0; $index -lt $scopeNamesArray.count; $index++)
{
    [void]$apiScopeArray.Add(@{Name = $scopeNamesArray[$index].Trim(); DisplayName = $scopeDisplayNamesArray[$index].Trim();})
}

$apiResource | add-member -Name "Scopes" -value $apiScopeArray -MemberType NoteProperty

$apiUserClaimsArray = [System.Collections.ArrayList]::new()

if ($null -ne $UserClaims)
{
    $userClaimsArray = $UserClaims.Split(",")
    
    for ($index = 0; $index -lt $userClaimsArray.count; $index++)
    {
        [void]$apiUserClaimsArray.Add($userClaimsArray[$index].Trim())
    }
}

$apiResource | add-member -Name "UserClaims" -value $apiUserClaimsArray -MemberType NoteProperty

$requestJson = $apiResource | ConvertTo-Json -Compress

Write-Host $requestJson

Write-Host "Creating/Updating API Resource:"
CreateOrUpdateApiResource $IdentityserverUrl $requestJson $accesToken

Write-Host "Done"


