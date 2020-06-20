#!/bin/sh

#
## generate SRI checksums
#

### text formatting presets
if command -v tput > /dev/null; then
    cyan=$(tput setaf 6)
    err=$(tput bold)$(tput setaf 1)
    magenta=$(tput setaf 5)
    norm=$(tput sgr0)
    ok=$(tput setaf 2)
else
    cyan=''
    err=''
    magenta=''
    norm=''
    ok=''
fi

### trap
trap trapExit 1 2 3 6

### functions
displayError (){
    printf "\n%sERROR: %s\n" "$err" "$2"
    printf "Exiting now.%s\n\n" "$norm"
    exit "$1"
}

scriptHelp (){
    printf "\n%sUsage: %s%s %s[--help] [--sha256|--sha384|--sha512] --file /file/to/hash%s\n\n" "$magenta" "$norm" "$scriptName" "$cyan" "$norm"
    printf "%s---parameters---%s\n" "$magenta" "$norm"
    printf "%s-h|-?|--help%s: show this help page\n" "$cyan" "$norm"
    printf "%s-2|--sha256%s: generate SHA256 SRI hash\n" "$cyan" "$norm"
    printf "%s-3|--sha384%s: generate SHA384 SRI hash (default)\n" "$cyan" "$norm"
    printf "%s-5|--sha512%s: generate SHA512 SRI hash\n" "$cyan" "$norm"
    printf "%s-f|--file%s: full path to the file for which you wish the SRI hash generated (required)\n\n" "$cyan" "$norm"
    printf "%s---examples---%s\n" "$magenta" "$norm"
    printf "Generate default SHA384 hash for styles.css located in the current directory:\n"
    printf "%s%s -f styles.css%s\n\n" "$cyan" "$scriptName" "$norm"
    printf "Generate SHA512 hash for /var/www/js/script.js:\n"
    printf "%s%s -5 --file /var/www/js/script.js%s\n\n" "$cyan" "$scriptName" "$norm"
    exit 0;
}

trapExit (){
    printf "\n%sERROR: Caught signal. Exiting.%s\n\n" "$err" "$norm"
    exit 99
}

### default variables
scriptName="$( basename "$0" )"
algo='sha384'
unset filename

### check pre-requisites
if ! command -v openssl > /dev/null; then
    displayError 2 'openSSL is not installed'
fi

### process startup parameters
if [ -z "$1" ]; then scriptHelp; fi
while [ $# -gt 0 ]; do
    case "$1" in
        -h|-\?|--help)
            # display script help
            scriptHelp
            exit 0
            ;;
        -2|--sha256)
            # generate SRI using sha256
            algo='sha256'
            ;;
        -3|--sha384)
            # generate SRI using sha384 (default)
            algo='sha384'
            ;;
        -5|--sha512)
            # generate SRI using sha512
            algo='sha512'
            ;;
        -f|--file)
            # file for which to generate SRI hash
            if [ -n "$2" ]; then
                if [ -f "$2" ]; then
                    filename="$2"
                    shift
                else
                    displayError 3 "Cannot find file '${2}'."
                fi
            else
                displayError 3 'No filename specified.'
            fi
            ;;
        *)
            # unknown option
            printf "\n%sUnknown option: %s.\n" "$err" "$1"
            printf "%sUse '--help' for valid options.%s\n\n" "$cyan" "$norm"
            exit 1
            ;;
    esac
    shift
done

printf "\n%sselected algo: %s%s\n" "$magenta" "$norm" "$algo"
printf "%sselected file: %s%s%s\n\n" "$magenta" "$norm" "$filename" "$norm"

### do SRI generation
hash=$( openssl dgst -${algo} -binary "${filename}" | openssl base64 -A) > /dev/null 2>&1
if [ -z "$hash" ]; then
    displayError 4 'An error occurred while generating SRI hash.'
else
    printf "%sSRI hash: %s%s-%s%s\n\n" "$magenta" "$ok" "$algo" "$hash" "$norm"
fi

exit 0


### error codes
# 0:    no errors, normal execution
# 1:    parameter error
# 2:    cannot find openSSL binary
# 3:    cannot find specified file for which to generate hash
# 4:    error occured while executing openssl

#EOF