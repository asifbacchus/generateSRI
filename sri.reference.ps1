param (
    # Specifies a path to one or more locations.
    [Parameter(Mandatory=$true,
               HelpMessage="Path to resource for which to generate integrity hash.")]
    [Alias("path", "resource")]
    [ValidateNotNullOrEmpty()]
    [string]
    $filename,

    [Parameter(HelpMessage="Desired hash algorithm.")]
    [Alias("algorithm")]
    [ValidateSet('sha256', 'sha384', 'sha512')]
    [string]
    $hashAlgo='sha384'
)

function hashSHA($type) {
    switch($type) {
        'sha256' { return [System.Security.Cryptography.SHA256]::Create() }
        'sha384' { return [System.Security.Cryptography.SHA384]::Create() }
        'sha512' { return [System.Security.Cryptography.SHA512]::Create() }
        default {
            Write-Host "`rUnknown hash algorithm.`r"
            exit 2
        }
    }
}

$fileContents = Get-Content $filename -Raw
$hashAlgo = $hashAlgo.ToLower()
$hashValue = hashSHA $hashAlgo

try {
    $hashBytes = $hashValue.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($fileContents))
    $hashBase64 = [System.Convert]::ToBase64String($hashBytes)
    Write-Host "`r$hashAlgo-$hashBase64`r"
}
catch {
    Write-Host "There was a problem generating a hash value."
    exit 1
}
finally {
    $hashValue.Dispose()
}

exit 0

#EOF