function sanitize_encoding ([AllowEmptyString()] $StringOrArray) {
    # TODO remove??
    $StringOrArray = $(if ($StringOrArray -is [array]) { , $StringOrArray }else { $StringOrArray })
    if ($StringOrArray -is [array]) {
        $result = @()
        for ($i = 0; $i -lt $strArr.Length; $i++) {
            $result += Convert-Encoding($strArr[$i])
        }
        return , $result
    } else {
        return Convert-Encoding($str)
    }
}

function Convert-Encoding(
    [string] $Str,
    [System.Text.Encoding] $Encoding = (New-Object -TypeName System.Text.UTF8Encoding -ArgumentList @($false, $true))
) {
    return $Encoding.GetString($Encoding.GetBytes($Str))
}

function ConvertTo-Base64String([parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)][string] $Str) {
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Str)
    return [Convert]::ToBase64String($bytes)
}

function ConvertFrom-Base64String([parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)][string] $Str) {
    $bytes = [Convert]::FromBase64String($Str)
    return [System.Text.Encoding]::Unicode.GetString($bytes)
}

function ConvertFrom-CliXml {
    [CmdletBinding(DefaultParameterSetName = 'CliXmlString')]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'CliXmlString')][string] $CliXmlString,
        [Parameter(Mandatory, ParameterSetName = 'Recurse')][object] $XmlObject
    )
    # ADAPTED from https://stackoverflow.com/a/44852653

    $result = $null
    # load xml root element OR sub element
    if ($XmlObject) {
        $Object = $XmlObject
    } else {
        $xml = New-Object System.Xml.XmlDocument
        $xml.LoadXml($CliXmlString)
        $Object = $xml.DocumentElement
    }

    # parses a powershell XML object or string into a PSObject
    $result = New-Object PSObject
    foreach ($property in $Object.PSObject.Properties) {
        if ($property -and $property.TypeNameOfValue -eq 'System.Xml.XmlElement') {
            $nestedObject = ConvertFrom-CliXml -XmlObject $property.Value
            $result | Add-Member -MemberType NoteProperty -Name $property.Name -Value $nestedObject
        } elseif ($property) {
            $value = $property.InnerText
            if ($property.Name -eq 'Type') {
                # handle special case where property name is 'Type'
                $value = $property.InnerText.Replace('System.', '')
            }
            $result | Add-Member -MemberType NoteProperty -Name $property.Name -Value $value
        }
    }
return $result
}

function Get-TokenizedCommandLine(
    # TODO check out
    #       param([parameter(ValueFromPipeline, ValueFromRemainingArguments,Mandatory)][string[]] $a)
    #       https://stackoverflow.com/questions/197233/
    #       https://github.com/beatcracker/Powershell-Misc/blob/master/Split-CommandLine.ps1
    #       https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-commandlinetoargvw
    #       https://learn.microsoft.com/en-us/dotnet/api/system.commandline.parsing?view=system-commandline
    [parameter(ValueFromPipeline)][string] $commandLine,
    [switch] $removeQuotes = $false,
    [ValidateSet('Everything', 'ProgramOnly', 'ArgumentsOnly')][string] $returnContent = 'Everything',
    [ValidateSet('Array', 'String')][string] $returnType = 'Array'
) {
    # tokenize
    $tokens = [regex]::Split($commandLine, ' (?=(?:[^"]|"[^"]*")+$)')
    $tokens[0] = $tokens[0].Trim() # removes trailing space # TODO check if always correct?
    # remove quotes if requested
    if ($removeQuotes) {
        $tokens = $tokens | ForEach-Object { Get-UnquotedString $_ }
    }
    # chose what to return
    switch ($returnContent) {
        'ProgramOnly' { $result = $tokens[0] ; break } # returns string
        'ArgumentsOnly' { $result = @($tokens | Select-Object -Skip 1) ; break } # returns array (stop array enumeration with @())
        'Everything' { $result = @($tokens) } # returns array (stop array enumeration with @())
    }
    if ($returnType -eq 'String') { $result = $tokens -join ' ' }

    # $result = sanitize_encoding @result
    return , $result
}


function Get-UnquotedString (
    [parameter(ValueFromPipeline)][string] $str
) {
    if ($str -like '"*"') { $result = $str.Substring(1, $str.Length - 2) } else { $result = $str }
    #$result = sanitize_encoding $result
    return $result
}

function Get-QuotedString (
    [parameter(ValueFromPipeline)][string] $str,
    [switch] $force = $false
) {
    if ($force -or ($str.Contains(' '))) { $result = '"' + $str + '"' } else { $result = $str }
    #$result = sanitize_encoding $result
    return $result
}



Export-ModuleMember -Function *-*
