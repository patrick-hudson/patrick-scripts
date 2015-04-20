#!/bin/bash
cyan=$(tput setaf 6)
normal=$(tput sgr0)
printf "${cyan}Enter the path of the file you want to upload : ${normal}"
read -r FILE
curl -d title="$(date '+%m-%W-%Y-%X')" -d private=1 -d expire=45 --data-urlencode text@$FILE http://racker@rackspace:txtsnip.com/api/create