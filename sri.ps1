<# Create SRI hashes for specified files or directory contents #>

<#
.SYNOPSIS
Create Sub-Resource Integrity (SRI) SHA hashes for specified files or directory contents.

.\sri.ps1 -files file1[, file2, ...] -directory /path/to/directory [-filter filter] [-hashAlgo sha256|sha384|sha512]

.DESCRIPTION
Create Sub-Resource Integrity (SRI) SHA-256, SHA-384 or SHA-512 hashes for a specified list of files, a subset of files within a directory, or all files within a directory.

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
# SIG # Begin signature block
# MIIk2wYJKoZIhvcNAQcCoIIkzDCCJMgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUz/tNLlv26HwojyzKyOfjSe/g
# XBqggh7EMIIFSDCCBDCgAwIBAgIQRduQy1A51HbZRmvQO0KlRjANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAi
# BgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQTAeFw0yMDA2MjIwMDAw
# MDBaFw0yMTA2MjIyMzU5NTlaMIGQMQswCQYDVQQGEwJDQTEQMA4GA1UEEQwHVDND
# IDNONzEQMA4GA1UECAwHQWxiZXJ0YTEQMA4GA1UEBwwHQ2FsZ2FyeTEdMBsGA1UE
# CQwUNzA3IDEzMzAgMTV0aCBBdmUgU1cxFTATBgNVBAoMDEFzaWYgQmFjY2h1czEV
# MBMGA1UEAwwMQXNpZiBCYWNjaHVzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEA4d4DbjI7zVixGBDKe/wJORs0Ve0u263F4bunao1DNyZYfoUu20YEMeF6
# LGJNWNTrd33OyerMI/dPzNwo2e6KnIVJcTCo2e4yIgFvjf6LL50VRZchhhKaljtn
# NzJwJRhSqArLuJ46sQSvrm6XlfCmBvKPPp7Lyg+INVWNhVK7smUpwVziD8km3jdr
# fSu9+9biog/+G5H9y3zydDrhZGz4a6xGU5OtwwuQimc7uBevemWJLBVkW2YkEzZK
# U3CCym2vTQbz5ASgMCkkCDW5YCCHHir1oNE+UN/3iIBWI32T5XJHDC+3ZjqTObTa
# h8+pQoRM5qiQMYLSr1jk5TosLWyr/QIDAQABo4IBrzCCAaswHwYDVR0jBBgwFoAU
# DuE6qFM6MdWKvsG7rWcaA4WtNA4wHQYDVR0OBBYEFAA3Y3wP9e9BUI0qkkyo9DKT
# X0k2MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBKBgNVHSAEQzBBMDUGDCsGAQQBsjEB
# AgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzAIBgZn
# gQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5zZWN0aWdvLmNvbS9T
# ZWN0aWdvUlNBQ29kZVNpZ25pbmdDQS5jcmwwcwYIKwYBBQUHAQEEZzBlMD4GCCsG
# AQUFBzAChjJodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29SU0FDb2RlU2ln
# bmluZ0NBLmNydDAjBggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20w
# HQYDVR0RBBYwFIESYXNpZkBiYWNjaHVzLmNsb3VkMA0GCSqGSIb3DQEBCwUAA4IB
# AQBXdfNWS6HyD+GV3w8KJlgKybQSf3pRABySi5BaTc665CDFrKPAH6ZnG7b9DFCj
# hq7W8epXJpOr2BodIDLp3YHZGg3OCU0Sb31I3ZC+6wyyEBgva0DogY7jDIjxX4E+
# 7mXwS1UG92huxcK0kPZHkB3BMfNOVQMGRtDIxEUHs/JqHK5WA0VPVkfTF2Zosicr
# q9UmQteSUpoTTUgDana8Ipa3StiuEHe2VJ9pfK/Wm6Pwl/HiFw1jskNkhLAL/ZC1
# 8mDRZ8aG+A0+Wro8ntouhO7pq01FNVm36Y/z1syG7kk57LhwLxMxq1lPitH46njM
# fnDT6Diei89FdxhV2Vg9dhomMIIFgTCCBGmgAwIBAgIQOXJEOvkit1HX02wQ3TE1
# lTANBgkqhkiG9w0BAQwFADB7MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRl
# ciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8g
# Q0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4X
# DTE5MDMxMjAwMDAwMFoXDTI4MTIzMTIzNTk1OVowgYgxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UE
# ChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNB
# IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAgBJlFzYOw9sIs9CsVw127c0n00ytUINh4qogTQktZAnczomfzD2p
# 7PbPwdzx07HWezcoEStH2jnGvDoZtF+mvX2do2NCtnbyqTsrkfjib9DsFiCQCT7i
# 6HTJGLSR1GJk23+jBvGIGGqQIjy8/hPwhxR79uQfjtTkUcYRZ0YIUcuGFFQ/vDP+
# fmyc/xadGL1RjjWmp2bIcmfbIWax1Jt4A8BQOujM8Ny8nkz+rwWWNR9XWrf/zvk9
# tyy29lTdyOcSOk2uTIq3XJq0tyA9yn8iNK5+O2hmAUTnAU5GU5szYPeUvlM3kHND
# 8zLDU+/bqv50TmnHa4xgk97Exwzf4TKuzJM7UXiVZ4vuPVb+DNBpDxsP8yUmazNt
# 925H+nND5X4OpWaxKXwyhGNVicQNwZNUMBkTrNN9N6frXTpsNVzbQdcS2qlJC9/Y
# gIoJk2KOtWbPJYjNhLixP6Q5D9kCnusSTJV882sFqV4Wg8y4Z+LoE53MW4LTTLPt
# W//e5XOsIzstAL81VXQJSdhJWBp/kjbmUZIO8yZ9HE0XvMnsQybQv0FfQKlERPSZ
# 51eHnlAfV1SoPv10Yy+xUGUJ5lhCLkMaTLTwJUdZ+gQek9QmRkpQgbLevni3/GcV
# 4clXhB4PY9bpYrrWX1Uu6lzGKAgEJTm4Diup8kyXHAc/DVL17e8vgg8CAwEAAaOB
# 8jCB7zAfBgNVHSMEGDAWgBSgEQojPpbxB+zirynvgqV/0DCktDAdBgNVHQ4EFgQU
# U3m/WqorSs9UgOHYm8Cd8rIDZsswDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQF
# MAMBAf8wEQYDVR0gBAowCDAGBgRVHSAAMEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6
# Ly9jcmwuY29tb2RvY2EuY29tL0FBQUNlcnRpZmljYXRlU2VydmljZXMuY3JsMDQG
# CCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuY29tb2RvY2Eu
# Y29tMA0GCSqGSIb3DQEBDAUAA4IBAQAYh1HcdCE9nIrgJ7cz0C7M7PDmy14R3iJv
# m3WOnnL+5Nb+qh+cli3vA0p+rvSNb3I8QzvAP+u431yqqcau8vzY7qN7Q/aGNnwU
# 4M309z/+3ri0ivCRlv79Q2R+/czSAaF9ffgZGclCKxO/WIu6pKJmBHaIkU4MiRTO
# ok3JMrO66BQavHHxW/BBC5gACiIDEOUMsfnNkjcZ7Tvx5Dq2+UUTJnWvu6rvP3t3
# O9LEApE9GQDTF1w52z97GA1FzZOFli9d31kWTz9RvdVFGD/tSo7oBmF0Ixa1DVBz
# J0RHfxBdiSprhTEUxOipakyAvGp4z7h/jnZymQyd/teRCBaho1+VMIIF9TCCA92g
# AwIBAgIQHaJIMG+bJhjQguCWfTPTajANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5
# MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJU
# cnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgxMTAyMDAwMDAw
# WhcNMzAxMjMxMjM1OTU5WjB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRl
# ciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdv
# IExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAIYijTKFehifSfCWL2MIHi3c
# fJ8Uz+MmtiVmKUCGVEZ0MWLFEO2yhyemmcuVMMBW9aR1xqkOUGKlUZEQauBLYq79
# 8PgYrKf/7i4zIPoMGYmobHutAMNhodxpZW0fbieW15dRhqb0J+V8aouVHltg1X7X
# FpKcAC9o95ftanK+ODtj3o+/bkxBXRIgCFnoOc2P0tbPBrRXBbZOoT5Xax+YvMRi
# 1hsLjcdmG0qfnYHEckC14l/vC0X/o84Xpi1VsLewvFRqnbyNVlPG8Lp5UEks9wO5
# /i9lNfIi6iwHr0bZ+UYc3Ix8cSjz/qfGFN1VkW6KEQ3fBiSVfQ+noXw62oY1YdMC
# AwEAAaOCAWQwggFgMB8GA1UdIwQYMBaAFFN5v1qqK0rPVIDh2JvAnfKyA2bLMB0G
# A1UdDgQWBBQO4TqoUzox1Yq+wbutZxoDha00DjAOBgNVHQ8BAf8EBAMCAYYwEgYD
# VR0TAQH/BAgwBgEB/wIBADAdBgNVHSUEFjAUBggrBgEFBQcDAwYIKwYBBQUHAwgw
# EQYDVR0gBAowCDAGBgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwu
# dXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5
# LmNybDB2BggrBgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNl
# cnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcw
# AYYZaHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEA
# TWNQ7Uc0SmGk295qKoyb8QAAHh1iezrXMsL2s+Bjs/thAIiaG20QBwRPvrjqiXgi
# 6w9G7PNGXkBGiRL0C3danCpBOvzW9Ovn9xWVM8Ohgyi33i/klPeFM4MtSkBIv5rC
# T0qxjyT0s4E307dksKYjalloUkJf/wTr4XRleQj1qZPea3FAmZa6ePG5yOLDCBax
# q2NayBWAbXReSnV+pbjDbLXP30p5h1zHQE1jNfYw08+1Cg4LBH+gS667o6XQhACT
# PlNdNKUANWlsvp8gJRANGftQkGG+OY96jk32nw4e/gdREmaDJhlIlc5KycF/8zoF
# m/lv34h/wCOe0h5DekUxwZxNqfBZslkZ6GqNKQQCd3xLS81wvjqyVVp4Pry7bwMQ
# JXcVNIr5NsxDkuS6T/FikyglVyn7URnHoSVAaoRXxrKdsbwcCtp8Z359LukoTBh+
# xHsxQXGaSynsCz1XUNLK3f2eBVHlRHjdAd6xdZgNVCT98E7j4viDvXK6yz067vBe
# F5Jobchh+abxKgoLpbn0nu6YMgWFnuv5gynTxix9vTp3Los3QqBqgu07SqqUEKTh
# DfgXxbZaeTMYkuO1dfih6Y4KJR7kHvGfWocj/5+kUZ77OYARzdu1xKeogG/lU9Tg
# 46LC0lsa+jImLWpXcBw8pFguo/NbSwfcMlnzh6cabVgwggbsMIIE1KADAgECAhAw
# D2+s3WaYdHypRjaneC25MA0GCSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNV
# BAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJT
# QSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xOTA1MDIwMDAwMDBaFw0zODAx
# MTgyMzU5NTlaMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNo
# ZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRl
# ZDElMCMGA1UEAxMcU2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQTCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAMgbAa/ZLH6ImX0BmD8gkL2cgCFUk7nP
# oD5T77NawHbWGgSlzkeDtevEzEk0y/NFZbn5p2QWJgn71TJSeS7JY8ITm7aGPwEF
# kmZvIavVcRB5h/RGKs3EWsnb111JTXJWD9zJ41OYOioe/M5YSdO/8zm7uaQjQqzQ
# FcN/nqJc1zjxFrJw06PE37PFcqwuCnf8DZRSt/wflXMkPQEovA8NT7ORAY5unSd1
# VdEXOzQhe5cBlK9/gM/REQpXhMl/VuC9RpyCvpSdv7QgsGB+uE31DT/b0OqFjIpW
# cdEtlEzIjDzTFKKcvSb/01Mgx2Bpm1gKVPQF5/0xrPnIhRfHuCkZpCkvRuPd25Ff
# nz82Pg4wZytGtzWvlr7aTGDMqLufDRTUGMQwmHSCIc9iVrUhcxIe/arKCFiHd6QV
# 6xlV/9A5VC0m7kUaOm/N14Tw1/AoxU9kgwLU++Le8bwCKPRt2ieKBtKWh97oaw7w
# W33pdmmTIBxKlyx3GSuTlZicl57rjsF4VsZEJd8GEpoGLZ8DXv2DolNnyrH6jaFk
# yYiSWcuoRsDJ8qb/fVfbEnb6ikEk1Bv8cqUUotStQxykSYtBORQDHin6G6UirqXD
# TYLQjdprt9v3GEBXc/Bxo/tKfUU2wfeNgvq5yQ1TgH36tjlYMu9vGFCJ10+dM70a
# tZ2h3pVBeqeDAgMBAAGjggFaMIIBVjAfBgNVHSMEGDAWgBRTeb9aqitKz1SA4dib
# wJ3ysgNmyzAdBgNVHQ4EFgQUGqH4YRkgD8NBd0UojtE1XwYSBFUwDgYDVR0PAQH/
# BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# EQYDVR0gBAowCDAGBgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwu
# dXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5
# LmNybDB2BggrBgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNl
# cnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcw
# AYYZaHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEA
# bVSBpTNdFuG1U4GRdd8DejILLSWEEbKw2yp9KgX1vDsn9FqguUlZkClsYcu1UNvi
# ffmfAO9Aw63T4uRW+VhBz/FC5RB9/7B0H4/GXAn5M17qoBwmWFzztBEP1dXD4rzV
# WHi/SHbhRGdtj7BDEA+N5Pk4Yr8TAcWFo0zFzLJTMJWk1vSWVgi4zVx/AZa+clJq
# O0I3fBZ4OZOTlJux3LJtQW1nzclvkD1/RXLBGyPWwlWEZuSzxWYG9vPWS16toytC
# iiGS/qhvWiVwYoFzY16gu9jc10rTPa+DBjgSHSSHLeT8AtY+dwS8BDa153fLnC6N
# Ixi5o8JHHfBd1qFzVwVomqfJN2Udvuq82EKDQwWli6YJ/9GhlKZOqj0J9QVst9Jk
# WtgqIsJLnfE5XkzeSD2bNJaaCV+O/fexUpHOP4n2HKG1qXUfcb9bQ11lPVCBbqvw
# 0NP8srMftpmWJvQ8eYtcZMzN7iea5aDADHKHwW5NWtMe6vBE5jJvHOsXTpTDeGUg
# Ow9Bqh/poUGd/rG4oGUqNODeqPk85sEwu8CgYyz8XBYAqNDEf+oRnR4GxqZtMl20
# OAkrSQeq/eww2vGnL8+3/frQo4TZJ577AWZ3uVYQ4SBuxq6x+ba6yDVdM3aO8Xwg
# DCp3rrWiAoa6Ke60WgCxjKvj+QrJVF3UuWp0nr1IrpgwggcGMIIE7qADAgECAhA9
# GjVyMBWCYzDQE3F+gkEIMA0GCSqGSIb3DQEBDAUAMH0xCzAJBgNVBAYTAkdCMRsw
# GQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAW
# BgNVBAoTD1NlY3RpZ28gTGltaXRlZDElMCMGA1UEAxMcU2VjdGlnbyBSU0EgVGlt
# ZSBTdGFtcGluZyBDQTAeFw0xOTA1MDIwMDAwMDBaFw0zMDA4MDEyMzU5NTlaMIGE
# MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
# VQQHDAdTYWxmb3JkMRgwFgYDVQQKDA9TZWN0aWdvIExpbWl0ZWQxLDAqBgNVBAMM
# I1NlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgU2lnbmVyICMxMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAy1FQ/1b+/HhjcAGTWp4Y9DtT9gevIWz1og99
# HXAthHRIi5yKlQU9WYT5kYB5USzZirfBC5q6CorNZk8DiwG7MMqrvdvATxJe/ArM
# 4kWwATiKu03n1BxUmO05WM9bwi9FmDEK+TU4uDEubbQeOXLhuCq+n4yMGqVGrgsr
# TJn+LEv8KLkiOmYX0KpWiiHA85YktNCFJmu68G9kmHmmrb1c2FNrKwrWcoqFRuMN
# GAbaxntBVjabFT7xahGg92b1GNCAVWOHaGbrDnlVglyj7Um4cYaekzewa6PqYmyj
# rpbouf2Lq8b2WVsAPFcgGC1wA6ec75LreaHHXex8tI9L3+td/KMg3ZI45WpROmuF
# nEygmAhpWwbnKhnQlZOLO2uKBQkp2Nba2+Ny+lxKL3sVVoYyv38FCZ0tKs9Q4eZh
# INvHBoBcThRGvq5XcaKqbDCTHH53ywbpV82R9dUzchzh2spu6/MP7Hlbuyee6B7+
# L/K7f+nl0GfruA18pCtZA4uV7SIozfosO8cWEa/j1rFQZ2nFjvV50K3/h8z4f6r5
# ou1h+MiNadqx9FGR62dX0WQR62TLA71JVTpFQxgsJWzRLwwtb/VBNSSg8mNZFl/Z
# pOksTtu7MRLGbfhbbgPcyxWPG41y7NsPFZDWEk7u4gAxJZM1b2pbpRJjQAGKuWmI
# Ooi4DxkCAwEAAaOCAXgwggF0MB8GA1UdIwQYMBaAFBqh+GEZIA/DQXdFKI7RNV8G
# EgRVMB0GA1UdDgQWBBRvTYYH2DInniwp0tATA4CB3QWDKTAOBgNVHQ8BAf8EBAMC
# BsAwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBABgNVHSAE
# OTA3MDUGDCsGAQQBsjEBAgEDCDAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3Rp
# Z28uY29tL0NQUzBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3JsLnNlY3RpZ28u
# Y29tL1NlY3RpZ29SU0FUaW1lU3RhbXBpbmdDQS5jcmwwdAYIKwYBBQUHAQEEaDBm
# MD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29SU0FU
# aW1lU3RhbXBpbmdDQS5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNlY3Rp
# Z28uY29tMA0GCSqGSIb3DQEBDAUAA4ICAQDAaO2z2NRQm+/TdcsPO/ck03o3RY0s
# 7xb7UaksH7UltYqfXQvCGyB0jWYPNsuq9jYND36PS0p0Q2WsDSr2Cu1rbcUJOO0A
# G/jl3KYKQAVH74TKCbxDZoO/n+3bjj3RQWSxcAItA1dbGG8cLMsesgDougkvW4EE
# NbmpY22OCMUY0eEhrPkSChTAEtt+JZ2sHRDAWqWD0h8aZlX8myri7DdXjuXfljD4
# wJMLQxj5Am+pUa+4VwrzHAdpOY83nG3Xka6lLknpSt6z0Iy/OZANwIHO8CoHOgym
# LVHScvNTxvm97+8MaUl3nyxWxOmhCD0HrsUe1oQix7x9QxtYOGJO0QUlhMVC+B8v
# 9tv6q4xU7EWKbBJNMFpS5aQXCSLm72/1X4ZD36EtvUpGkqCBlixhl39Ab9g/jDVa
# q9HGoDuFZlSA7x8a9fGbsKEnfbLnC8/2LZxYE5SphvxFUqIobX90D1KRSXrpEvip
# O7CS/X2RFOlbbUiU8siW7gU4s8XsMD/hByAEsdiLvP2zPm/yAlMG9KDtyZpyo5df
# APvLY9DozXT9dcnUNkW6exJZcu3n8npQAHj4Q5pG2N+/VNRescfRvBuD9CvnC+hH
# yFOezBqs9vqKdVNsIIWp1bhquiSOiisIkZ83BBz2b6LdNKqR/8YVLh5CGgkpT/TG
# zeKRotNADI544zGCBYEwggV9AgEBMIGQMHwxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# ExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoT
# D1NlY3RpZ28gTGltaXRlZDEkMCIGA1UEAxMbU2VjdGlnbyBSU0EgQ29kZSBTaWdu
# aW5nIENBAhBF25DLUDnUdtlGa9A7QqVGMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3
# AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSZUsAGSJg6
# gHhcpVCa+DE1rm/iqDANBgkqhkiG9w0BAQEFAASCAQBvYtDC0ohQOyHECaHJlj22
# KsjBmab3vhFC3YQGZ0p67CiWwF6cQaJPJXg8ytOTqLqOhMG/060Ii5MjQbfkzGl4
# 6RK7SBIwCyaA2cHaTTDoOD2oWRYrCj/oN/e9KGhBY8iyHwwXY4+Hmhz4XgmdCW0p
# fm5TiYt5KTidli5odlXLNAy5qZrtL8kH/m1JXhtxrocc2F4dAQKRQ4VehlCEHkMc
# kQRgpUkNVxQAYmKUoq+lpQmUQQAbEOn5unjdCOQkOgx1j1wDvUG6GgQTKg6JuPNc
# A++aSijTz4GzkArFTIZ/UosV360AU1NSMaalbJWr8gld0jV9c/JFXcK75FRULzwi
# oYIDSzCCA0cGCSqGSIb3DQEJBjGCAzgwggM0AgEBMIGRMH0xCzAJBgNVBAYTAkdC
# MRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQx
# GDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDElMCMGA1UEAxMcU2VjdGlnbyBSU0Eg
# VGltZSBTdGFtcGluZyBDQQIQPRo1cjAVgmMw0BNxfoJBCDANBglghkgBZQMEAgIF
# AKB5MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIw
# MDYyMjA2MjE0OVowPwYJKoZIhvcNAQkEMTIEMH0HfMaPkzobNz0F8aQ7TkvP7Xrj
# uA/mpyPyVOjDaix5jiq1ahWm21MKU4UslFyAkDANBgkqhkiG9w0BAQEFAASCAgCZ
# Xy61UwrGWYuQql5zeD96Yh4z+NfnlZvduf+dMI1Sd7vDR6anmg9sOOdQpc5mQ7Ns
# 4ZzroOFQtzzaxzy/WpkdM0frRZgZvLYQVpI2/PTWS3gv+04ryo9HB0gPZ8OiSzNO
# 5fOMU2i9a8lJRteXvbc5tNttBKyC6lZuxMlBkDyzrW2yBjBzP5H4MxrNOfO9t7hP
# RaN8jtfEemjUEpIdITLQZAnAxGc891alInxgWrvMps2rZcjHMnEWS1J1fU9m/GDz
# AS9e/MoE3qd5KDWgQGdPr8wJnzYrEchbJSj74KTuJ2irw1fQSFv0kA/GDHxxVIIO
# KzXSOwDrJYzUjfZkMcOk3mRVZxPOW1L2le422dKxC7rYpaiNi5ZX8c998eNnLQAp
# l3K7T8lnZBA8J9saRDRTiDwyq6+vzGDdEfXGsvnxNMW+6BrSqOwk9/NDb9umIz8N
# G43+3Hy1I8q6DJOCPXxKtZcIvFHAKZnCn+aLxpVu//my5ZcGA2IiIYDSA7euluzs
# hjY8ouNmV5khBSy5IcQpBci+ooc+9Zwacix3IdIl553ecHKRCaXlBvMgxlop4ld/
# aSZqeT2FQ4xBnoOsGsDDTmlrBADLOqZvE+6F+AQZUuZBfOHRcLT1sXmM2hHWkvxq
# vA+y5PtsjOvq/YsyTfeEPt7dRmwlF6k2yE4wOpA+/w==
# SIG # End signature block
