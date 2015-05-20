#!/bin/bash
# 	Copyright (c) 2014 Patrick Hudson
# 	Author: Patrick Hudson
# 	Email: patrick.hudson@rackspace.com
# 	
# 		Permission is hereby granted, free of charge, to any person obtaining a copy
# 		of this software and associated documentation files (the "Software"), to deal
# 		in the Software without restriction, including without limitation the rights
# 		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# 		copies of the Software, and to permit persons to whom the Software is
# 		furnished to do so, subject to the following conditions:
# 	
# 		The above copyright notice and this permission notice shall be included in all
# 		copies or substantial portions of the Software.
# 		
# 		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# 		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# 		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# 		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# 		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# 		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# 		SOFTWARE.
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
blue=$(tput setaf 4)
red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)
userPassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

addGroup()
{
	printf "Checking to see if sftponly group exists\n"
	alreadyGroup=false
	getent group sftponly >/dev/null 2>&1 && alreadyGroup=true
	if $alreadyGroup; then
		printf "${green}Group Already Exists${normal}\n"
		addUser
	else
		printf "${green}Group Doesn't Exist, adding sftponly group${normal}\n"
		groupadd sftponly
		addUser
	fi
}

addUser() 
{
	printf "Enter the Username you want to add : "
	read -r username
	alreadyUser=false
	getent passwd $username >/dev/null 2>&1 && alreadyUser=true
	if $alreadyUser; then
		printf "${red}User Already Exists, exiting${normal}\n"
		exit 1
	else
		useradd -d /home/$username/ -s /bin/false -G sftponly $username
		if [ $? -eq 0 ]
		then
		    printf "${green}User $username Added!${normal}\n"
		    echo -e "$userPassword\n$userPassword\n" | (passwd $username) >/dev/null 2>&1
		    createHome $username

		else
		    echo "${red}User $username failed to add${normal}"
		fi
	fi

}
createHome()
{
	username=$1
	mkdir /home/$username
	if [ $? -eq 0 ]
	then
	    printf "${green}Home Directory /home/$1 created! ${normal}\n"
	    bindMountHome $username
	else
	    echo "${red}Home failed to create (Probably exists){normal}"
	fi
}
bindMountHome()
{
	username=$1
	printf "Enter the name of the site are you mounting (example: google.com): "
	read -r sitename
	mkdir /home/$username/$sitename
	read -e -p "Enter the directory to bind mount location (example /var/www/vhosts/mydomain.com) : " bindLoc
	printInfo $username $bindLoc $sitename

}
printInfo()
{
	username=$1
	bindLoc=$2
	sitename=$3
	printf "${green}$username's password is $userPassword${normal}\n"
	printf "${green}$username's home folder is /home/$username${normal}\n\n"
	printf "${green}Run the following command to change the ownership of $bindLoc to User: apache and Group: sftponly\n${normal}"
	printf "${cyan}chown -R apache:sftponly $bindLoc\n\n${normal}"
	printf "${green}Run the following to update the permissions for $bindLoc to 0775 (read/write for user and group + sticky)\n${normal}"
	printf "${cyan}chmod -R 0775 $bindLoc\n\n${normal}"
	printf "${green}Insert the following into /etc/fstab and then run mount -a\n${normal}"
	printf "${cyan}$bindLoc              /home/$username/$sitename                 none    bind    0 0\n\n${normal}"
	printf "Change the following into /etc/ssh/sshd_config\n"
	printf "Comment Out ${green}Subsystem sftp /usr/lib/openssh/sftp-server \n${normal}"
	printf "Insert ${green}Subsystem sftp internal-sftp${normal}\n\n"
	printf "Insert the following into /etc/ssh/sshd_config at the VERY BOTTOM!\n"
	printf "${green}Match Group sftponly\n"
	echo -e "     ChrootDirectory /var/www/vhosts/%h"
	printf "     X11Forwarding no\n"
	printf "     AllowTCPForwarding no\n"
	printf "     ForceCommand internal-sftp\n${normal}"
	printf "Restart SSH\n\n"


}
addGroup