# renamepi
Rename default pi user on Raspberry Pi

The standard installation of Raspbian on a Raspberry Pi comes with a standard default user called pi, with a standard wellknown password. This has never made much sense to me, and every time I installed a new Pi I found myself struggling to rename the standard user.

Yes - I could just create a new user and disable the pi user, but I want userid 1000. I really do.

Finally I found this - http://unixetc.co.uk/2016/01/07/how-to-rename-the-default-raspberry-pi-user/ - the most complete guide for renaming the default user I have found.

After following the guide step by step many times, I decided to automate the task. This is the result.

A single file - renamepi.sh - that you download and execute.

```
sudo ./renamepi.sh <newname>
```

The Raspberry Pi will reboot twice and the default user should be renamed to the new name.

### Guarantee
I guarantee that I believe that I have seen this work at least once and that I do not intend for it to do anything else than what is described here. That's all.

If you decide to use this script, you should only execute is on a fresh Raspbian install. That way you will not loose much time if the script fails to do what it is supposed to do. At worst you'll need to write a new microSD card.

### Acknowledgements
Really all thanks go to Jim McDonnell (http://unixetc.co.uk/about-2/) who has done all the hard work of figuring out what files need to be updated for this to work.

### So I should download a script from github and execute it? With sudo?
Yes. Sorry. Please inspect the script. And while you're at it - please suggest changes.

### A short explanation of what the script does
The problem with renaming the pi user is explained in detail by Jim McDonnell in http://unixetc.co.uk/2016/01/07/how-to-rename-the-default-raspberry-pi-user/. Read it. 

The renamepi.sh script eliminates (some of) these problems by installing itself to be run very early in the boot process - it temporarily replaces /etc/rc.local.

Initially the are some sanity checks. It checks that the script is running as root, and that the new username doesn't exist already.

Then the script splits in two. The first part replaces the /etc/rc.local script with a small script that just calls renamepi.sh (with an extra parameter) and then it reboots the Raspberry Pi.

When the Raspberry Pi reboots, it will execute the new /etc/rc.local script. Now - because of the extra parameter - the script executes the second part. This is done before any processes owned by the pi user are started. At this point the script follows the guide from Jim McDonnells page, backing up files and renaming and editing them. Finally the original /etc/rc.local is restored, and the system is rebooted once more. Just to be sure.

You should now be able to login using the new username and the old default password. Change the password manually immediately after this.
