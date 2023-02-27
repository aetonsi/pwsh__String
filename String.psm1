
function Get-TokenizedCommandLine(
    # TODO check out https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-commandlinetoargvw
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
        $tokens = [string[]]($tokens.foreach({ Get-UnquotedString $_ }))
    }
    # chose what to return
    switch ($returnContent) {
        'ProgramOnly' { $result = $tokens[0] ; break }
        'ArgumentsOnly' { $result = [string[]]($tokens | Select-Object -Skip 1) ; break }
        'Everything' { $result = $tokens }
    }
    if ($returnType -eq 'String') { $result = $tokens -join ' ' }
    return , $result # the comma avoids array enumeration if there's only 1 element
}


function Get-UnquotedString (
    [parameter(ValueFromPipeline)][string] $str
) {
    if ($str -like '"*"') { return $str.Substring(1, $str.Length - 2) } else { return $str }
}

function Get-QuotedString (
    [parameter(ValueFromPipeline)][string] $str,
    [switch] $force = $false
) {
    if ($force -or ($str.Contains(' '))) { return '"' + $str + '"' } else { return $str }
}



Export-ModuleMember -Function *-*