Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function GetAccesToken([string]$identityserverUrl, [string]$clientid, [string]$clientsecret)
{
    $granttype = "client_credentials" 
    $scope = "IdentityServerApi identityserverapi.trustedsubsystem"

    $body = @{
        grant_type = $granttype
        scope = $scope
        client_id = $clientid
        client_secret = $clientsecret    
    }

    # username = $username
    # password = $password

    $contentType = 'application/x-www-form-urlencoded' 
    $tokenendpointurl = $identityserverUrl + "/connect/token"    

    $resp = Invoke-RestMethod -Method Post -Body $body -Uri $tokenendpointurl -ContentType $contentType
    # $parts = $resp.access_token.Split('.');

    # $baseDecoded = Convert-FromBase64StringWithNoPadding($parts[1])
    # $decoded = [System.Text.Encoding]::UTF8.GetString($baseDecoded)

    Write-Host "`***** SUCCESSFULLY FETCHED TOKENACCESS ***** `n" -foreground Green

    return $resp.access_token
}

function CreateOrUpdateApiResource([string]$identityserverUrl, [string]$body, [string]$accesToken)
{
    $apiurl = $identityserverUrl + '/api/apiresource'
    # -proxy "http://127.0.0.1:8888"
    $resp = Invoke-WebRequest -Method PUT -Body $body -Headers @{'Authorization' = 'Bearer ' + $accesToken; 'Content-Type' = 'application/json' } -Uri $apiurl -SkipHttpErrorCheck

    LogInfoAndThrowIf2($resp);
}


function ClientExits([string]$identityserverUrl, [string]$clientid, [string]$accesToken)
{
    $apiurl = $identityserverUrl + '/api/client' +'?clientId=' + $clientid

    $resp = Invoke-WebRequest -Method Get -Headers @{'Authorization' = 'Bearer ' + $accesToken; } -Uri $apiurl -SkipHttpErrorCheck

    return CheckStatusCodeBoolean($resp)
}


function UpdateClient([string]$identityserverUrl, [string]$body, [string]$accesToken)
{
    $apiurl = $identityserverUrl + '/api/client'

    $resp = Invoke-WebRequest -Method PUT -Body $body -Headers @{'Authorization' = 'Bearer ' + $accesToken; 'Content-Type' = 'application/json' } -Uri $apiurl -SkipHttpErrorCheck

    LogInfoAndThrowIf($resp);
}

function CreateClient([string]$identityserverUrl, [string]$body, [string]$accesToken)
{
    $apiurl = $identityserverUrl + '/api/client'

    $resp = Invoke-WebRequest -Method POST -Body $body -Headers @{'Authorization' = 'Bearer ' + $accesToken; 'Content-Type' = 'application/json' } -Uri $apiurl -SkipHttpErrorCheck

    LogInfoAndThrowIf($resp);
}


function CreateClientSecret([string]$identityserverUrl, [string]$body, [string]$accesToken)
{
    $apiurl = $identityserverUrl + '/api/clientsecret'

    $resp = Invoke-WebRequest -Method POST -Body $body -Headers @{'Authorization' = 'Bearer ' + $accesToken; 'Content-Type' = 'application/json' } -Uri $apiurl -SkipHttpErrorCheck

    LogInfoAndThrowIf($resp);
}


function Convert-FromBase64StringWithNoPadding([string]$data)
{
    $data = $data.Replace('-', '+').Replace('_', '/')
    switch ($data.Length % 4)
    {
        0 { break }
        2 { $data += '==' }
        3 { $data += '=' }
        default { throw New-Object ArgumentException('data') }
    }
    return [System.Convert]::FromBase64String($data)
}


function Get-NotNullVariable($name)
{
    $var = Get-Variable $name -ErrorAction SilentlyContinue
    if ($null -eq $var)
    {
        throw "$(remove_prefix $name) must be a not-null variable"
    }
    return $var
}

function Get-AllowNullVariable($name)
{
    $var = Get-Variable $name -ErrorAction SilentlyContinue
    if ($null -eq $var)
    {
        return $null
    }
    return $var.Value
}

function Confirm-NotEmptyString($var, $name)
{
    $value = $var;

    if ($var.GetType() -eq [System.Management.Automation.PSVariable])
    {
        $name = $var.Name
        $value = $var.Value
    }

    if([string]::IsNullOrEmpty($value))
    {
        throw "$(remove_prefix $name) (value: $($value)) must contain at least a single char which is not whitespace"
    }
}

function Confirm-NotEmptyString($value)
{
    
    if([string]::IsNullOrEmpty($value)) 
    {
        throw "Variable must contain at least a single char which is not whitespace"
    }
}

function Confirm-Bool($var)
{
    $out = $null
    if ([bool]::TryParse($var.Value, [ref]$out)) {
        return $out;
    } else {
        throw "$(remove_prefix $var.Name) (value: $($var.Value)) must be true or false"
    }
}

function Confirm-Bool($var, $default)
{
    if ([string]::IsNullOrEmpty($var))
    {
        return $default
    }

    $out = $null
    if ([bool]::TryParse($var, [ref]$out)) {
        return $out;
    } else {
        throw "$(remove_prefix $var.Name) (value: $($var.Value)) must be true or false"
    }
}

function Confirm-AbsoluteUrl($var, $name)
{
    Confirm-NotEmptyString $var, $name

    $value = $var;

    if ($var.GetType() -eq [System.Management.Automation.PSVariable])
    {
        $name = $var.Name
        $value = $var.Value
    }

    if (-not ([system.uri]::IsWellFormedUriString($value,[System.UriKind]::Absolute)))
    {
        throw "$(remove_prefix $name) (value: $value) must be an absolute Uri"
    }
}

function Confirm-LowerCase($var)
{
    Confirm-NotEmptyString $var

    if (Get-Member -InputObject $var -Name Value -MemberType Properties)
    {
        if ($var.Value -cmatch "[A-Z]")
        {
            throw "$(remove_prefix $var.Name) (value: $($var.Value)) must be lowercased"
        }
    }
    elseif ($var -cmatch "[A-Z]") {
        throw "$(remove_prefix $var.Name) (value: $($var.Value)) must be lowercased"
    }
}

function Confirm-Endswith($var, $end)
{
    Confirm-NotEmptyString $var

    if (!$var.Value.EndsWith("/"))
    {
        throw "$(remove_prefix $var.Name) (value: $($var.Value)) must end with '$end'"
    }
}

function remove_prefix($var)
{
    return $var.Replace("idsrv","")
}

function LogInfoAndThrowIf2($resp) {
    Write-Host $([string]$resp.RawContent);    
    Write-Host ""
    $statusCodeFamily = [int]( $resp.StatusCode / 100 )
    if ($statusCodeFamily -eq 2)
    {
        return
    }
    if ($statusCodeFamily -eq 4)
    {
        Write-Host "Client error, check request and try again"
    }
    if ($statusCodeFamily -eq 5)
    {
        Write-Host "Server error, try again later"
    }
    throw "Request unsuccessful. Check IdentityServer log for details."
}

function LogInfoAndThrowIf($resp) {
    Write-Host "Respons from identityserver :"
    $resp|ft
    Write-Host "$($resp.StatusCode) - $($resp.StatusDescription)" ;

    if (($resp.StatusCode -eq 200) -or ($resp.StatusCode -eq 201) -or ($resp.StatusCode -eq 404))
    {
        return
    }

    if ($resp.RawContentLength -gt 0)
    {
        Write-Host $resp.Content;    
    }
    $resp|ft
    throw "Request error check log"
}

function CheckStatusCodeBoolean($resp) {
    if ($resp.StatusCode -eq 200)
    {
        return $true
    }
    elseif ($resp.StatusCode -eq 404)
    {
        return $false
    }
    throw "Request error check log"
}


function SplitToArray($var ,$delimiter) {

    $list = $var.Split($delimiter)

    $array = [System.Collections.ArrayList]::new()

    for ($index = 0; $index -lt $list.count; $index++)
    {
        if(![string]::IsNullOrEmpty($list[$index]))
        {  
              [void]$array.Add($list[$index].Trim())
        }
    }

    return ,$array
}