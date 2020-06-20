# Sub-Resource Integrity Generator Scripts

Basic scripts to generate SRI hashes for a given file. POSIX-compliant shell script for use on *nix and PowerShell for use on Windows.

## linux script

- This script *requires* openssl be installed and will exit if it cannot find openssl.
- You can rename *sri* to anything you like.
- I suggest copying *sri* somewhere like */usr/local/bin* or */usr/bin* so it can be run easier and from anywhere
- Complete help is included in the script. Simply run without any parameters or run with '*--help*'

### examples

Assuming you have *not* copied the script to your path and it is located in your home directory:

```bash
cd ~
./sri -f /var/www/css/style.css
```

If copied to a directory in your path like */usr/local/bin*, then you can simplify things by running it directly from where the file you want to hash is located:

```bash
cd /var/www/css
sri -f style.css
```

### troubleshooting

About the only thing that can go wrong is the script not being marked executable. In that case, simply make it executable:

```bash
# make executable
chmod +x /path/to/sri
# verify
ls -lA /path/to/sri
# output something like:
# -rwxr-xr-x 1 user user 3622 Jun 20 01:18 sri
# note the x's --> -rwXr-Xr-X (capitals for emphasis)
```
