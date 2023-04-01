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