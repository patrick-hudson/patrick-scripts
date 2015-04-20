#!/bin/bash
# Author: Patrick Hudson
# Email: patrick.hudson@rackspace.com
#
# Reset all variables that might be set
DOMAIN=
VHOST=
WEB_DIR=
REQSSL=
BUNDLE=
CERT=
KEY=
OPTS=
PHPFPM=
CONTYPE=
CONPORT=
ACTIVATEVHOST=
VHOSTPATH=
ENABLEDPATH=
DBNAME=
DBUSER=
DBHOST=
DBREMOTE=
DBPASS=
DBREMOTETRUE=
DBREMOTEPASSWORD=
MYSQL=
RELOADERROR=
verbose=0
NGINX=`which nginx`
CURPATH=$(pwd)
#Colors
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
blue=$(tput setaf 4)
red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

#Added Padding
createtemplate()
{
(
cat << EOF 
server  {
    listen  80;
    root ROOT;
    index index.php index.html index.htm;
    server_name  www.DOMAIN DOMAIN;
    error_log  /var/log/nginx/DOMAIN-error.log warn;
    access_log  /var/log/nginx/DOMAIN.com-access.log combined;
        location ~* \.(jpg|jpeg|gif|css|png|js|ico|html)$ {
          access_log off;
          expires max;
        }
        location ~ /\.ht {
          deny  all;
        }
        ####PHPlocation ~ \.php$ {
        ####PHP    fastcgi_split_path_info ^(.+\.php)(/.+)$;
        ####PHP    fastcgi_pass PORTSOCKET;
        ####PHP    fastcgi_index index.php;
        ####PHP    include fastcgi_params;
        ####PHP}
}
#server  {
#    listen  443;
#    root  ROOT;
#    index index.php index.html index.htm;
#    server_name  www.DOMAIN DOMAIN;
#    error_log  /var/log/nginx/DOMAIN-ssl-error.log warn;
#    access_log  /var/log/nginx/DOMAIN-ssl-access.log combined;
#    ssl  on;
#    ssl_client_certificate  CAPATH;
#    ssl_certificate  CERTPATH;
#    ssl_certificate_key  KEYPATH;
#        location ~* \.(jpg|jpeg|gif|css|png|js|ico|html)$ {
#          access_log off;
#          expires max;
#        }
#        location ~ /\.ht {
#          deny  all;
#        }
#        ####PHPlocation ~ \.php$ {
#        ####PHP    fastcgi_split_path_info ^(.+\.php)(/.+)$;
#        ####PHP    fastcgi_pass PORTSOCKET;
#        ####PHP    fastcgi_index index.php;
#        ####PHP    include fastcgi_params;
#        ####PHP}
#}
EOF
) > nginx_virtual_host.template
}

usage()
{
cat << EOF
usage: $0 options

This script creates a vhost for nginx. You can either pass it options, or simply provide a domain and interactively enter the info

Interactive Example: ./nginxvhostgenerator.sh mydomain.com
	./nginxvhostgenerator.sh mydomain.com
	> Enter the root web directory for mydomain.com
		mydomain.com
	> Enable SSL? [Y/N]
		Y
	> Enter the CA Bundle Path (Example: /etc/ssl/certs/year-sitename.ca.crt)
		/etc/ssl/certs/year-sitename.ca.crt
	> Enter the Cert Path (Example: /etc/ssl/certs/year-sitename.crt)
		/etc/ssl/certs/year-sitename.crt
	> Enter the Private Key Path (Example: /etc/ssl/private/year-sitename.key)
		/etc/ssl/private/year-sitename.key
	Creating hosting for: mydomain.com

	Site Created for mydomain.com


Options Example: ./nginxvhostgenerator.sh --use-opts --domain mydomain.com --root-path /var/www/vhosts/domain.com --ssl --ca-path /etc/ssl/certs/year-sitename.ca.crt --cert-path /etc/ssl/certs/year-sitename.crt --key-path /etc/ssl/private/year-sitename.key --php-fpm --php-fpm-port 9000
OPTIONS:
	--use-opts 
		This option is required if you want to utilize the non-interactive vhost generator
	--domain
		Domain name without www (Example: mydomain.com)
	--root-path
		Document root of the website (Example: /var/www/vhosts/domain.com)
	--ssl
		Use this option to setup an SSL vhost
	--ca-path
		CA Bundle Path (Example: /etc/ssl/certs/year-sitename.ca.crt)
	--cert-path
		Cert Path (Example: /etc/ssl/certs/year-sitename.crt)
	--key-path
		Private Key Path (Example: /etc/ssl/private/year-sitename.key)
	--php-fpm
		Pass this option to enable PHP-FPM in the vhost
	--php-fpm-socket
		Pass this option to utilize a socket connection to PHP-FPM. Uses the default location (unix:/var/run/php5-fpm.sock;)
	--php-fpm-port
		Pass this option with a port number to utilize a port based connection to PHP-FPM


EOF
}
reload_nginx()
{
	now=$(date +"%m_%d_%Y")
	unlink $ENABLEDPATH/$DOMAIN.conf > /dev/null 2>&1
	if [ -f $VHOSTPATH/$DOMAIN.conf ]; then
		printf "${red}${red}ERROR:${normal} ${normal}$VHOSTPATH/$DOMAIN.conf already exists\n\n"
		printf "${yellow}Would you like to delete it? [Y/N] : ${normal}"
		read -r REMOVECONF
		if [[ "$REMOVECONF" =~ ^[Yy]$ ]]; then
			mv $VHOSTPATH/$DOMAIN.conf $VHOSTPATH/$DOMAIN.conf.bkup-$now
			printf "\n$VHOSTPATH/$DOMAIN.conf ${yellow}backed up to ${normal}$VHOSTPATH/$DOMAIN.conf.bkup-$now\n\n"
			printf "You can safely delete it by running\n\n${yellow}rm $VHOSTPATH/$DOMAIN.conf.bkup-$now${normal}\n\n"
			reload_nginx
		else
			exit 1
		fi
	else
		# Create symlink
		cp $DOMAIN.conf $VHOSTPATH/$DOMAIN.conf
		ln -s $VHOSTPATH/$DOMAIN.conf $ENABLEDPATH/$DOMAIN.conf
		nginx -t > /dev/null 2>&1
		if [ $? -eq 0 ];then
			TMP=$(mktemp)
			service nginx reload &>> $TMP
			if [ $? -eq 0 ];then
				printf "${green}SUCCESS: ${normal}NGINX reloaded with and $DOMAIN is now active\n\n"
				RELOADERROR="N"
			else
				OUTPUT=$(cat $TMP)
				printf "\n${red}ERROR:${normal} Could not create new vhost as there appears to be a problem with the newly created nginx config file: $VHOSTPATH/$DOMAIN.conf\n\n";
				printf "${cyan}INFO: ${normal}Output of NGINX Configuration Test\n\n"
				printf "$OUTPUT\n"
				RELOADERROR="Y"
				rm $TMP
				exit 1;
			fi
			rm $TMP
		else
			printf "${red}ERROR:${normal} Could not create new vhost as there appears to be a problem with the newly created nginx config file: $VHOSTPATH/$DOMAIN.conf\n\n";
			printf "${cyan}INFO: ${normal}Output of NGINX Configuration Test\n\n"
			nginx -t
		fi
	fi
	if [ "$RELOADERROR" = "N" ]; then
		printresults
	fi
}
mysql_create()
{
	db="create database $DBNAME;
	GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER@'$DBHOST' IDENTIFIED BY '$DBPASS';FLUSH PRIVILEGES;"
	if [[ "$DBREMOTETRUE" = "Y" ]]; then
		if ! mysql -u -h $DBREMOTE root -e 'show processlist' > /dev/null 2>&1; then
			mysql -u root -p$DBREMOTEPASSWORD -h $DBREMOTE -e "$db"
		else
			mysql -u root -h $DBREMOTE -e "$db"
		fi
	else
		mysql -u root -e "$db"
	fi
			
	
}
interactivemysql()
{
	printf "Enter the Database Name you want to create : "
	read -r DBNAME
	printf "Enter the Database Username you want to create : "
	read -r DBUSER
	DEFAULT="localhost"
	printf "Enter the Host that will be connecting to $DBNAME [localhost] : "
	read -r DBHOST
	[ -z "$DBHOST" ] && DBHOST=$DEFAULT
	read -s -p "Enter a Database User Password for $DBUSER : " DBPASS
	echo
	printf "Will this database be created on a remote MySQL Server? [Y/N] : "
	read -r DBREMOTETRUE
	if [[ "$DBREMOTETRUE" =~ ^[Yy]$ ]]; then
		printf "Enter the Remote MySQL IP Address : "
		read -r DBREMOTE
		if ! mysql -u -h $DBREMOTE root -e 'show processlist' > /dev/null 2>&1; then
			printf "${red}ERROR:${normal} Connection to MySQL failed using the default root password\n" >&2
			read -s -p "Enter the remote MySQL Root Password : " DBREMOTEPASSWORD
			if ! mysql -u root -h $DBREMOTE -p$DBREMOTEPASSWORD -e 'show processlist' > /dev/null 2>&1; then
				printf "${red}ERROR:${normal} Connection to MySQL failed using the provided root password\n" >&2
				exit 1;
			fi
		fi
	else
		if ! mysql -u root -e 'show processlist' > /dev/null 2>&1; then
			printf "${red}ERROR:${normal} Connection to MySQL on localhost failed. Please make sure this user has a .my.cnf in home folder with valid root credentials \n" >&2
			exit 1
		fi
	fi
	mysql_create

}
editconfig()
{
# check the domain is valid!
PATTERN="^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
	DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
else
	echo "${red}${red}ERROR:${normal} ${normal}invalid domain name"
	exit 1
fi
 
# Now we need to copy the virtual host template
CONFIG=$DOMAIN.conf
cp nginx_virtual_host.template $CONFIG

$SED -i.bak "s#DOMAIN#$DOMAIN#g" $CONFIG
$SED -i.bak "s!ROOT!$WEB_DIR!g" $CONFIG
if [ "$REQSSL" = "Y" ]; then
	$SED -i.bak 's/^#*//' $CONFIG
	$SED -i.bak "s#CAPATH#$BUNDLE#g" $CONFIG
	$SED -i.bak "s#CERTPATH#$CERT#g" $CONFIG
	$SED -i.bak "s#KEYPATH#$KEY#g" $CONFIG
fi
if [ "$PHPFPM" = "Y" ]; then
$SED -i.bak 's/####PHP//' $CONFIG
	if [ "$CONTYPE" = "PORT" ]; then
		ipport="127.0.0.1:$CONPORT"
		$SED -i.bak "s#PORTSOCKET#$ipport#g" $CONFIG
	fi
	if [ "$CONTYPE" = "SOCKET" ]; then
		sock="unix:/var/run/php5-fpm.sock"
		$SED -i.bak "s#PORTSOCKET#$sock#g" $CONFIG
	fi
fi
if [[ "$CREATEDB" =~ ^[Yy]$ ]]; then
		interactivemysql
fi
rm $DOMAIN.conf.bak
if [[ $ACTIVATEVHOST = "Y" ]]; then
	reload_nginx
else
	printresults
fi

}
printresults() 
{

echo -e "\nCreating hosting for:" $DOMAIN
echo -e "\nSite Created for $DOMAIN"
echo "--------------------------"
echo "Domain: $DOMAIN"
echo "Document Root $WEB_DIR"
if [ "$REQSSL" = "Y" ]; then
	echo "SSL Enabled: Yes"
	echo "Certificate Bundle Path: $BUNDLE"
	echo "Certificate Path: $CERT"
	echo "Private Key Path: $KEY"
else
	echo "SSL Enabled: No"
fi
if [ "$PHPFPM" = "Y" ]; then
	echo "PHP-FPM Enabled: Yes"
	echo "PHP-FPM Connection Type: $CONTYPE"
	if [ "$CONTYPE" = "PORT" ]; then
		echo "PHP-FPM Port Number: $CONPORT"
	fi
else
	echo "PHP-FPM Enabled: No"
fi
if [[ "$ACTIVATEVHOST" =~ ^[Yy]$ ]] && [[ "$RELOADERROR" = "N" ]]; then
	echo "VHOST Enabled: Yes"
	echo "VHOST Location: $VHOSTPATH/$DOMAIN.conf"
elif [[ "$RELOADERROR" = "Y" ]]; then
	echo "VHOST Enabled: ${red}ERROR${normal}"
	echo "VHOST Location: $CURPATH/$DOMAIN.conf"
else
	echo "VHOST Enabled: No, user declined prompt"
	echo "VHOST Location: $CURPATH/$DOMAIN.conf"
fi
if [[ "$CREATEDB" =~ ^[Yy]$ ]]; then
	echo "Database created"
	echo "Database Name: $DBNAME"
	echo "Database User: $DBUSER"
	echo "Database Password: $DBPASS"
	echo "Database Host: $DBHOST"
fi
echo "# --------------------------" >> $DOMAIN.conf.tmp
echo "# Domain: $DOMAIN" >> $DOMAIN.conf.tmp
echo "# Document Root $WEB_DIR" >> $DOMAIN.conf.tmp
if [ "$REQSSL" = "Y" ]; then
	echo "# SSL Enabled: Yes" >> $DOMAIN.conf.tmp
	echo "# Certificate Bundle Path: $BUNDLE" >> $DOMAIN.conf.tmp
	echo "# Certificate Path: $CERT" >> $DOMAIN.conf.tmp
	echo "# Private Key Path: $KEY" >> $DOMAIN.conf.tmp
else
	echo "# SSL Enabled: No" >> $DOMAIN.conf.tmp
fi
if [ "$PHPFPM" = "Y" ]; then
	echo "# PHP-FPM Enabled: Yes" >> $DOMAIN.conf.tmp
	echo "# PHP-FPM Connection Type: $CONTYPE" >> $DOMAIN.conf.tmp
	if [ "$CONTYPE" = "PORT" ]; then
		echo "# PHP-FPM Port Number: $CONPORT" >> $DOMAIN.conf.tmp
	fi
else
	echo "# PHP-FPM Enabled: No" >> $DOMAIN.conf.tmp
fi
if [[ "$CREATEDB" =~ ^[Yy]$ ]]; then
	echo "# Database created" >> $DOMAIN.conf.tmp
	echo "# Database Name: $DBNAME" >> $DOMAIN.conf.tmp
	echo "# Database User: $DBUSER" >> $DOMAIN.conf.tmp
	echo "# Database Password: $DBPASS" >> $DOMAIN.conf.tmp
	echo "# Database Host: $DBHOST" >> $DOMAIN.conf.tmp
fi
echo "# --------------------------" >> $DOMAIN.conf.tmp
cat $DOMAIN.conf >> $DOMAIN.conf.tmp
if [[ "$ACTIVATEVHOST" =~ ^[Yy]$ ]]; then
	mv $DOMAIN.conf.tmp $VHOSTPATH/$DOMAIN.conf
else
	mv $DOMAIN.conf.tmp $DOMAIN.conf
fi
rm nginx_virtual_host.template
exit 0;
}
useopts()
{
	echo -e "\n\n\n"
	if [ "$VHOST" = "Y" ]; then
		if [ -z "$DOMAIN" ]; then
	    	printf '${red}ERROR:${normal} option "--domain domain.com" not given. See --help.\n' >&2
	    	exit 1
		fi
		if [ -z "$WEB_DIR" ]; then
	    	printf '${red}ERROR:${normal} option "--root-path /var/www/vhosts/domain.com" not given. See --help.\n' >&2
	    	exit 1
		fi
		if [ "$REQSSL" = "Y" ]; then
			if [ -z "$BUNDLE" ]; then
		    	printf '${red}ERROR:${normal} option "--ca-path /etc/ssl/certs/year-sitename.ca.crt" not given. See --help.\n' >&2
		    	exit 1
			fi
			if [ -z "$CERT" ]; then
		    	printf '${red}ERROR:${normal} option "--cert-path /etc/ssl/certs/year-sitename.crt" not given. See --help.\n' >&2
		    	exit 1
			fi
			if [ -z "$KEY" ]; then
		    	printf '${red}ERROR:${normal} option "--key-path /etc/ssl/private/year-sitename.key" not given. See --help.\n' >&2
		    	exit 1
			fi
		fi
		if [ "$PHPFPM" = "Y" ]; then
			if [ -z "$CONTYPE" ]; then
				printf '${red}ERROR:${normal} option "--php-fpm requires either --php-fpm-socket or --php-fpm-port PORTNUMBER to be passed. See --help.\n' >&2
				exit 1
			fi
			if [ "$CONTYPE" = "PORT" ]; then
				if [ -z "$CONPORT" ]; then
					printf '${red}ERROR:${normal} option "--php-fpm-port requires a PORT number passed. See --help.\n' >&2
					exit 1
				fi
			fi
		fi
		editconfig
	fi
	if [ "$MYSQL" = "Y" ]; then
		if [ -z "$DBNAME" ]; then
			printf '${red}ERROR:${normal} option "--mysql-dbname requires a name to passed. See --help.\n' >&2
			exit 1
		fi
		if [ -z "$DBUSER" ]; then
			printf '${red}ERROR:${normal} option "--mysql-username requires a user name to passed. See --help.\n' >&2
			exit 1
		fi
		if [ -z "$DBPASS" ]; then
			printf '${red}ERROR:${normal} option "--mysql-user-password requires a password to passed. See --help.\n' >&2
			exit 1
		fi
		if [ -z "$DBHOST" ]; then
			printf '${red}ERROR:${normal} option "--mysql-userhost requires a host to passed. See --help.\n' >&2
			exit 1
		fi
		if [ ! -z "$DBREMOTE" ]; then
			if ! mysql -u -h $DBREMOTE root -e 'show processlist'; then
				printf '${red}ERROR:${normal} Connection to MySQL failed use option "--mysql-remote-password to send the remote MySQL root password. See --help.\n' >&2
				exit 1
			fi
		fi
		mysql_create
	fi
	
	
}
interactive()
{
	if [ -z $1 ]; then
		echo "No domain name given"
		exit 1
	fi
	DOMAIN=$1
	HOST=$(echo $DOMAIN | cut -d "." -f1)
	YEAR=$(date +"%Y")
	DEFAULT="/var/www/vhosts/$DOMAIN"
	printf "Enter the root web directory for $DOMAIN [$DEFAULT] : "
	read -r WEB_DIR
	[ -z "$WEB_DIR" ] && WEB_DIR=$DEFAULT
	if [ ! -d "$WEB_DIR" ]; then
		DEFAULT="Y"
		printf "${yellow}WARNING:${normal} $WEB_DIR doesn't exist! Create it? [$DEFAULT] : "
		read -r CREATEDIR
		if [[ "$CREATEDIR" =~ ^[Yy]$ ]]; then
			mkdir -p $WEB_DIR
		else
			printf "${yellow}WARNING:${normal} $WEB_DIR NOT created. You must manually create it"
		fi

	fi
	DEFAULT="Y"
	printf "\nEnable SSL? [Y/N] : "
	read -r REQSSL
	[ -z "$REQSSL" ] && REQSSL=$DEFAULT
	if [[ "$REQSSL" =~ ^[Yy]$ ]]; then
		DEFAULT="/etc/ssl/certs/$YEAR-$HOST.ca.crt"
		printf  "Enter the CA Bundle Path [$DEFAULT]: "
		read -r BUNDLE
		[ -z "$BUNDLE" ] && BUNDLE=$DEFAULT
		DEFAULT="/etc/ssl/certs/$YEAR-$HOST.crt"
		printf  "Enter the Cert Path [$DEFAULT] : "
		read -r CERT
		[ -z "$CERT" ] && CERT=$DEFAULT
		DEFAULT="/etc/ssl/private/$YEAR-$HOST.key"
		printf  "Enter the Private Key Path [$DEFAULT] : "
		read -r KEY
		[ -z "$KEY" ] && KEY=$DEFAULT

	fi
	DEFAULT="Y"
	printf "Enable PHP-FPM? [Y/N]"
	read -r PHPFPM
	[ -z "$PHPFPM" ] && PHPFPM=$DEFAULT
	if [[ "$PHPFPM" =~ ^[Yy]$ ]]; then
		DEFAULT="SOCKET"
		printf "Connect to PHP-FPM using a Socket or a Port? [$DEFAULT]: "
		read -r CONTYPE
		[ -z "$CONTYPE" ] && CONTYPE=$DEFAULT
		CONTYPE=$(echo $CONTYPE | awk '{print tolower($0)}')
		if [[ "$CONTYPE" = "socket" ]]; then
			CONTYPE="SOCKET"
		else
			CONTYPE="PORT"
			DEFAULT="9000"
			printf "What port is PHP-FPM Listening on? [$DEFAULT] : "
			read -r CONPORT
			[ -z "$CONPORT" ] && CONPORT=$DEFAULT
		fi

	fi

	DEFAULT="Y"
	printf "Activate VHOST? [Y/N] : "
	read -r ACTIVATEVHOST
	[ -z "$ACTIVATEVHOST" ] && ACTIVATEVHOST=$DEFAULT
	if [[ "$ACTIVATEVHOST" =~ ^[Yy]$ ]]; then
		DEFAULT="/etc/nginx/sites-available"
		printf "Where are the NGINX VHOST configuration files located? [$DEFAULT] : "
		read -r $VHOSTPATH
		[ -z "$VHOSTPATH" ] && VHOSTPATH=$DEFAULT
		DEFAULT="/etc/nginx/sites-enabled"
		printf "Where are the NGINX VHOST *enabled* configuration files located? [$DEFAULT] : "
		read -r $ENABLEDPATH
		[ -z "$ENABLEDPATH" ] && ENABLEDPATH=$DEFAULT
	fi
	DEFAULT="Y"
	printf "Create MySQL Database for site? [Y/N] : "
	read -r CREATEDB
	[ -z "$CREATEDB" ] && CREATEDB=$DEFAULT
	editconfig


}
 # Variables to be evaluated as shell arithmetic should be initialized to a default or validated beforehand.

while :; do
    case $1 in
        --help)   # Call a "show_help" function to display a synopsis, then exit.
            usage
            exit
            ;;
        --use-opts)       # Takes an option argument, ensuring it has been specified.
            OPTS=1
            ;;
        --domain)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                DOMAIN=$2
                VHOST="Y"
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--domain" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --root-path)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                WEB_DIR=$2
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--root-path" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --ssl)       # Takes an option argument, ensuring it has been specified.
                REQSSL="Y"
            ;;
        --ca-path)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ "$REQSSL" = "Y" ]; then
                BUNDLE=$2
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--ca-path" requires a non-empty option argument and --ssl must be YES\n' >&2
                exit 1
            fi
            ;;
        --cert-path)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ "$REQSSL" = "Y" ]; then
                CERT=$2
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--cert-path" requires a non-empty option argument and --ssl must be YES\n' >&2
                exit 1
            fi
            ;;
        --key-path)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ "$REQSSL" = "Y" ]; then
                KEY=$2
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--key-path" requires a non-empty option argument and --ssl must be passed\n' >&2
                exit 1
            fi
            ;;
        --php-fpm)       # Takes an option argument, ensuring it has been specified.
                PHPFPM="Y"
            ;;     
        --php-fpm-socket)       # Takes an option argument, ensuring it has been specified.
				if [ "$PHPFPM" = "Y" ]; then
                	CONTYPE="SOCKET"
                else
                	printf '${red}ERROR:${normal} "--php-fpm-socket" requires --php-fpm to be passed\n' >&2
                	exit 1
                fi
            ;;      
        --php-fpm-port)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ "$PHPFPM" = "Y" ]; then
                CONTYPE="PORT"
                CONPORT=$2
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--php-fpm-port" requires a non-empty option argument and --php-fpm must be passed\n' >&2
                exit 1
            fi
            ;;
        --activate-vhost)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ -n "$3" ]; then
                ACTIVATEVHOST="Y"
                VHOSTPATH=$2
                ENABLEDPATH=$3
                shift 2
                reload_nginx
                continue
            else
                ACTIVATEVHOST="Y"
                VHOSTPATH="/etc/nginx/sites-available"
                ENABLEDPATH="/etc/nginx/sites-enabled"
                printf "${yellow}WARNING:${normal} sites-available and sites-enabled folder not passed with --activate-vhost. \nUsing default /etc/nginx/sites-available and /etc/nginx/sites-enabled\n\n"
                reload_nginx
            fi
            ;;
        --mysql-dbname)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                DBNAME=$2
                MYSQL="Y"
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--mysql-dbname" requires a non-empty option argument' >&2
                exit 1
            fi
            ;;
        --mysql-username)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ "$MYSQL" = "Y" ]; then
                DBUSER=$2
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--mysql-username" requires a non-empty option argument and --mysql-dbname must be passed\n' >&2
                exit 1
            fi
            ;;
        --mysql-user-password)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ "$MYSQL" = "Y" ]; then
                DBPASS=$2
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--mysql-user-password requires a non-empty option argument and --mysql-dbname must be passed\n' >&2
                exit 1
            fi
            ;;
        --mysql-userhost)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ "$MYSQL" = "Y" ]; then
                DBHOST=$2
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--mysql-userhost" requires a non-empty option argument and --mysql-dbname must be passed\n' >&2
                exit 1
            fi
            ;;
        --mysql-remoteip)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ "$MYSQL" = "Y" ]; then
                DBREMOTE=$2
                DBREMOTETRUE="Y"
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--mysql-remote" requires a non-empty option argument and --mysql-dbname must be passed\n' >&2
                exit 1
            fi
            ;;
        --mysql-remote-password)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ] && [ "$MYSQL" = "Y" ]; then
                DBREMOTEPASSWORD=$2
                shift 2
                continue
            else
                printf '${red}ERROR:${normal} "--mysql-remote-password" requires a non-empty option argument and --mysql-dbname must be passed\n' >&2
                exit 1
            fi
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf "${yellow}WARNING:${normal} Unknown option (ignored): %s\n" "$1" >&2
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    command shift        # "command" reduces the chance of fatal errors in many shells.
done

# Suppose --file is a required option. Ensure the variable "file" has been set and exit if not.


SED=`which sed`
CURRENT_DIR=`dirname $0`
if [ "$OPTS" = "1" ]; then
	if [ ! -f nginx_virtual_host.template ]; then
		echo "${yellow}WARNING: ${normal}nginx_virtual_host.template not found, creating in current working directory\n\n"
		createtemplate
	fi
	useopts
else
	parameter=$(echo $1 | awk '{print tolower($0)}')
	if [ -z $parameter ]; then
		echo "${red}ERROR:${normal} No parameter given"
		echo "${cyan}INFO: Use ./nginxvhostgenerator.sh --help"
		exit 1
	elif [[ $parameter = "mysql" ]]; then
		interactivemysql
	else
		if [ ! -f nginx_virtual_host.template ]; then
			echo "${yellow}WARNING: ${normal}nginx_virtual_host.template not found, creating in current working directory\n\n"
			createtemplate
		fi
		interactive $parameter

	fi
	
fi