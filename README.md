# Sub-Resource Integrity Generator Scripts

Basic scripts to generate SRI hashes. POSIX-compliant shell script for use on *nix and PowerShell for use on Windows.

## common features

- Hash individual files or a quoted space-delimited list of files.
- Hash all files within a specified directory with one command.
- Hash a filtered-list of files within a directory with one command.
- Process a list of files and a directory (filtered or not) at the same time, saving you typing!

## linux script

- This script *requires* openssl be installed and will exit if it cannot find openssl.
- You can rename *sri* to anything you like.
- I suggest copying *sri* somewhere like */usr/local/bin* or */usr/bin* so it can be run easier and from anywhere (see note below).
- Complete help is included in the script. Simply run without any parameters or run with '*--help*'.

  ```bash
  ./sri --help
  ```

### copy to path location

Copying the script to a location within your path makes running it more convenient. For example:

Assuming you store it in your home directory /Downloads and need to hash files in your webroot (eg: /var/www/css/...)

```bash
~/SRIhelper/sri -f /var/www/css/style.css
```

Whereas, if it's in your path, you can omit the source path and just run

```bash
sri -f /var/www/css/style.css
```

To make this work, just copy the file to a location in your path. There are no dependencies or anything to worry about, the file is self-contained and POSIX compliant.

```bash
# copy to local/bin
cp ~/SRIhelper/sri /usr/local/bin/sri
# copy and rename to something else
cp ~/SRIhelper/sri /usr/local/bin/hashSRI
# copy to your global bin directory (usually local is preferred!)
cp ~/SRIhelper/sri /usr/bin/sri
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
