param (
    # List of files to hash
    [Parameter(HelpMessage="Comma-separated list of files to hash.")]
    [Alias("file", "list")]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $files,

    # Directory of files to hash
    [Parameter(HelpMessage="Hash all files within this directory.")]
    [ValidateNotNullOrEmpty()]
    [string]
    $directory,

    # File filter
    [Parameter(HelpMessage="Only hash files of this type, relevant only when processing a directory.")]
    [Alias("only")]
    [ValidateNotNullOrEmpty()]
    [string]
    $filter = '*',

    # Hash algorithm to use
    [Parameter(HelpMessage="Hash algorithm to use (SHA256, SHA384, SHA512).")]
    [Alias("algorithm")]
    [ValidateSet('sha256', 'sha384', 'sha512')]
    [string]
    $hashAlgo = 'sha384'
)

function displayError($returnCode, $eMsg){
    Write-Host "`nERROR: $eMsg" -ForegroundColor Red
    Write-Host "Exiting.`n" -ForegroundColor Red
    exit $returnCode
}

function hashSHA($type){
    switch($type){
        'sha256' { return [System.Security.Cryptography.SHA256]::Create() }
        'sha384' { return [System.Security.Cryptography.SHA384]::Create() }
        'sha512' { return [System.Security.Cryptography.SHA512]::Create() }
        default{
            displayError 2 'Unknown hash algorithm.'
        }
    }
}

function doHash($file, $hash){
    $fileContents = Get-Content $file -Raw
        $fileContents = Get-Content $file -Raw -ErrorAction SilentlyContinue
    try {
        $hashBytes = $hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($fileContents))
        return [System.Convert]::ToBase64String($hashBytes)
    }
    catch {
        return 1
    }
}


# instantiate hash provider
$hashAlgo = $hashAlgo.ToLower()
$hash = hashSHA $hashAlgo

# process directory, if specified
if ($directory){
    # continue only if directory exists, otherwise exit with error
    if (Test-Path -Path $directory){
        Write-Host "`nProcessing directory: $directory" -ForegroundColor Cyan
        Get-ChildItem -Path $directory -Filter $filter | ForEach-Object({
            $hashValue = doHash $directory\$_ $hash
            if ($hashValue -ne 1){
                Write-Host "$_ --> $hashAlgo-$hashValue" -ForegroundColor Green
            }
            else {
                Write-Host "$_ --> unable to hash file" -ForegroundColor Red
            }
        })
    }
    else {
        displayError 1 "Directory '$directory' does not exist."
    }
}

# process file list, if specified
if ($files) {
    Write-Host
    foreach ($file in $files) {
        Write-Host "Processing $file"
    }
    Write-Host
}

# clean up and exit
$hash.Dispose()
exit 0

#EOF