#!/usr/bin/bash
# Adapted from Mike's example from https://guides.wp-bullet.com/
clear   
bold=`tput bold`
normal=`tput sgr0`

red='\033[1;31m'
green='\033[1;32m'        
blue='\033[1;34m'        
NC='\033[0m' # No Color   

# NOTE: This setup is for DirectAdmin based servers.  
#       Other servers may have different paths
#
#       Initial version to run as site user,not root
#       Must be run in web root. 
#
#       Very rough start.  
#
#       TODO: 
#
#       * Better check for web root path
#       * Able to specify plugins, themes individuall for backup and upgrade
#       * Better datetime for file sorting
#       * Auto delete backups older than x days defined in config? Maybe show list and prompt y/n for delete?
#       * Flag to send backup offsite via s3
#       * Checks for filenames, folder names etc. 
#       * export sql directly to backups folder
#       * rollback command to roll back the backup just made?

#Define permissions for servers that need it
#PERMS="www-data:www-data"

#Webroot
#WEBROOT=[figure this out!]
# Note - we can use wp config path to identify the web root assuming that wp-config.php is stored there: 
# wp config path
# /home/example/domains/example.com/public_html/wp-config.php

WEBROOT=$(dirname `wp config path` )

#Current datetime
DATE=`date +%Y-%m-%d.%H.%M`

#where you want to store backups
BACKUPPATH=~/backups

#get the current dir path
cd $WEBROOT
DIR=`pwd`
echo "Current directory is: " $DIR

#Test for wp-config.php to make sure we're in web root [UGLY: How do we detect actual web root via wp-cli?]
if [ -f "wp-config.php" ]
then
    echo "wp-config found. Let's back it up..."
else
    echo "wp-config not found - please change to web root for the site you wish to backup"
    exit
fi

#make sure the backup folder exists
mkdir -p $BACKUPPATH


echo "Backing up plugins to $BACKUPPATH/plugins_$DATE.tar.gz ..."
tar -czf $BACKUPPATH/plugins_$DATE.tar.gz ./wp-content/plugins/ 
echo "Backing up themes to $BACKUPPATH/themes_$DATE.tar.gz ..."
tar -czf $BACKUPPATH/themes_$DATE.tar.gz ./wp-content/themes/

echo "Backing up database to $BACKUPPATH/db.$DATE.sql ..."
#back up the WordPress database
wp db export $BACKUPPATH/db.$DATE.sql --allow-root
echo "Compress db to " $BACKUPPATH
tar -czf $BACKUPPATH/db.$DATE.sql.gz $BACKUPPATH/db.$DATE.sql
echo "delete local db export $BACKUPPATH/db.$DATE.sql..."
rm $BACKUPPATH/db.$DATE.sql

# Now we can update plugins
echo "Displaying list of plugins with available updates..."
wp plugin list --update=available

read -r -p "Update the above plugins? [y/N]" response
response=${response,,}    # tolower
if [[ $response =~ ^(yes|y)$ ]]  
then 
    wp plugin update --all --allow-root;
fi

# Now we can update plugins
echo "Displaying list of themes with available updates..."
wp theme list --update=available

read -r -p "Update the above plugins? [y/N]" response
response=${response,,}    # tolower
if [[ $response =~ ^(yes|y)$ ]]  
then 
    
wp theme update --all --allow-root;
fi


# Now we can update plugins

echo "Checking for Core update..."
wp core check-update
read -r -p "Update Core? [y/N]" response
response=${response,,}    # tolower
if [[ $response =~ ^(yes|y)$ ]]  
then 
    
wp core update --allow-root;
fi

#Fix permissions
#sudo chown -R www-data:www-data $SITESTORE
#sudo find $SITESTORE -type f -exec chmod 644 {} +
#sudo find $SITESTORE -type d -exec chmod 755 {} +

