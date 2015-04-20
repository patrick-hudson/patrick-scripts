#!/bin/bash
cyan=$(tput setaf 6)
normal=$(tput sgr0)
read -e -p "${cyan}Enter the path of the file you want to upload : ${normal}" FILE
curl -d title="$(date '+%m-%W-%Y-%X')" -d private=1 -d expire=45 --data-urlencode text@$FILE -u racker:rackspace http://txtsnip.com/api/create