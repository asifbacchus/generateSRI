<# Create SRI hashes for specified files or directory contents #>

<#
.SYNOPSIS
Create Sub-Resource Integrity (SRI) SHA hashes for specified files or directory contents.
.\sri.ps1 -files file1[, file2, ...] -directory /path/to/directory [-filter filter] [-hashAlgo sha256|sha384|sha512]

.DESCRIPTION
Create Sub-Resource Integrity (SRI) SHA-256, SHA-384 or SHA-512 hashes for a specified list of files, a sub-set of files within a directory, or all files within a directory.

.PARAMETER files
A comma-separated list of files (full path suggested) for which to generate SRI hashes.
EXAMPLE: style.css
EXAMPLE: /some/path/style.css
EXAMPLE: style.css, /some/other/path/menu.css
ALIAS: file, list

.PARAMETER directory
Directory containing files for which to generate SRI hashes. Can be filtered using the 'filter' parameter.
EXAMPLE: $env:userprofile\myWebSite\css
EXAMPLE: C:\Websites\Website1\js

.PARAMETER filter
Process only files matching this criteria. Only relevant for directory operations.
DEFAULT: * (all files)
EXAMPLE: *.css
EXAMPLE: script-site1*.js
ALIAS: only, include

.PARAMETER hashAlgo
Use the specified algorithm to generate SRI hashes. Accepts sha256, sha384 (default), sha512.
DEFAULT: sha384
ALIAS: algorithm

.EXAMPLE
.\sri.ps1 style.css
Generate default SHA384 hash for 'style.css' located in the current directory.

.EXAMPLE
.\sri.ps1 style.css, c:\websites\css\menu.css, $env:userprofile\Documents\website\script.js
Generate default SHA384 hashes for 'style.css' in the current directory along with the other two files as specified by their full paths.

.EXAMPLE
.\sri.ps1 -directory c:\website\css -hashAlgo sha256
Generate SHA256 hashes for all files in the 'C:\Website\css' directory

.EXAMPLE
.\sri.ps1 -dir c:\website\includes -filter *.js -algo sha512
Generate SHA512 hashes (partial alias used for '-hashAlgo') for all files matching '*.js' in directory 'C:\website\includes'

.EXAMPLE
.\sri.ps1 -files img\logo.svg, media\video.mp4 -directory css
Generate default SHA384 hashes for 'logo.svg' and 'video.mp4' in sub-folders 'img' and 'media', respectively, of the current folder. Then also generate hashes for all files in folder 'css', also a sub-folder of the current folder.
#>


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

    # File filter to apply to directory operations
    [Parameter(HelpMessage="Only hash files of this type, relevant only when processing a directory.")]
    [Alias("only", "include")]
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
    try{
        $fileContents = Get-Content $file -Raw -ErrorAction SilentlyContinue
        $hashBytes = $hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($fileContents))
        return [System.Convert]::ToBase64String($hashBytes)
    }
    catch{
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
        Write-Host "Processing directory: $directory" -ForegroundColor Cyan
        Get-ChildItem -Path $directory -Filter $filter | ForEach-Object({
            $hashValue = doHash $directory\$_ $hash
            if ($hashValue -ne 1){
                Write-Host "$_ --> $hashAlgo-$hashValue" -ForegroundColor Green
            }
            else{
                Write-Host "$_ --> unable to hash file" -ForegroundColor Red
            }
        })
    }
    else{
        displayError 1 "Directory '$directory' does not exist."
    }
}

# process file list, if specified
if ($files) {
    Write-Host "Processing files:" -ForegroundColor Cyan
    foreach ($file in $files) {
        if (Test-Path -Path $file){
            $hashValue = doHash $file $hash
            if ($hashValue -ne 1){
                Write-Host "$file --> $hashAlgo-$hashValue" -ForegroundColor Green
            }
            else {
                Write-Host "$file --> unable to hash file" -ForegroundColor Red
            }
        }
        else{
            Write-Host "$file --> cannot find file" -ForegroundColor Red
        }
    }
}

# clean up and exit
Write-Host
$hash.Dispose()
exit 0

#EOF