#! /bin/bash
#
# Execute this script as root (sudo) like
#
#   % sudo ./renamepi.sh newuser
#
# replacing newuser with the name you want to replace the default pi user.
# Your Raspberry Pi will then reboot twice, and the pi user should be replaced.
# The new user has the same password as the original pi user.
#
# Greatly inspired by (well actually most of it is stolen from)
#   http://unixetc.co.uk/2016/01/07/how-to-rename-the-default-raspberry-pi-user/

# The script must run as root in order to replace the /etc/rc.local file
if [ $EUID -ne 0 ]
then
   echo This script must run as root
   exit 1
fi

# The new username must be supplied as first parameter
if [ $# -lt 1 ]
then
  /bin/echo Usage: $0 \<new default user name\>
  exit 1
fi

NEWDEFAULT=$1
/bin/echo Renaming default user pi to $NEWDEFAULT...

# Refuse to rename to an existing username
/usr/bin/id $NEWDEFAULT > /dev/null 2>&1
retval=$?
if [ $retval -eq 0 ]
then
  /bin/echo User $NEWDEFAULT already exists. Bye bye...
  exit 1
fi

RCLOCAL=/etc/rc.local
BACKUPNAME=$RCLOCAL.renamepi.bak
REALPATH=`/usr/bin/realpath $0`

if [ $# -lt 2 ]
then
  # This is the user initiated case.
  # Install the script in /etc/rc.local and reboot
  /bin/mv $RCLOCAL $BACKUPNAME
  cat > $RCLOCAL <<_EOF
#! /bin/sh -e
# This is a temporary /etc/rc.local file.
# The original is backed up in /etc/rc.local.renamepi.bak,
# should be restored automatically after a reboot.
$REALPATH $NEWDEFAULT FROMRCLOCAL
_EOF
  chmod +x $RCLOCAL
  /sbin/reboot
fi

# The magic word "FROMRCLOCAL" indicates that the script is now being called
# from /etc/rc.local, and we can now rename the user before any pi owned processes are started. 
if [ "$2" -ne "FROMRCLOCAL"]
then
  /bin/echo I\'m not sure what to do about that...
  exit 1
fi

/bin/echo Backing up files...
cd /etc
/bin/tar -cvf authfiles.tar passwd group shadow gshadow sudoers lightdm/lightdm.conf systemd/system/autologin@.service sudoers.d/* polkit-1/localauthority.conf.d/60-desktop-policy.conf

/bin/echo Renaming user in files...
/bin/sed -i.$(date +'%y%m%d_%H%M%S') "s/\bpi\b/$NEWDEFAULT/g" passwd group shadow gshadow sudoers systemd/system/autologin@.service sudoers.d/* polkit-1/localauthority.conf.d/60-desktop-policy.conf
/bin/sed -i.$(date +'%y%m%d_%H%M%S') "s/user=pi/user=$NEWDEFAULT/" lightdm/lightdm.conf

/bin/echo Renaming home dir...
/bin/mv /home/pi /home/$NEWDEFAULT
/bin/ln -s /home/$NEWDEFAULT /home/pi

/bin/echo Renaming crontab and mail \(they probably don\'t exist\)
if [ -f /var/spool/cron/crontabs/pi ]
then
  mv -v /var/spool/cron/crontabs/pi /var/spool/cron/crontabs/$NEWDEFAULT
fi
if [ -f /var/spool/mail/pi ]
then
  mv -v /var/spool/mail/pi /var/spool/mail/$NEWDEFAULT
fi

/bin/echo Removing this script from rc.local and restoring backup...
/bin/rm /etc/rc.local
/bin/mv $BACKUPNAME $RCLOCAL 

/bin/echo Rebooting...
/sbin/reboot
