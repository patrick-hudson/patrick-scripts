auth() {
    read -p "Whats your username: " username    
    read -p "Whats your APIkey: " APIkey
}

copycontainer(){
    read -p "What container do you want to copy from? " ogcontainer
    read -p "What container do you want to copy to? " newcontainer
    for file in $(swiftly --auth-user=$username --auth-key=$APIkey --auth-url="https://identity.api.rackspacecloud.com/v2.0" get $ogcontainer| sed 's/ /_-_/g'); do
        file=$(echo $file |  sed 's/_-_/ /g')
        swiftly --auth-user=$username --auth-key=$APIkey --auth-url="https://identity.api.rackspacecloud.com/v2.0" put -e -H "X-Copy-From:/$ogcontainer/$file" "$newcontainer/$file"
        echo "Copied $file from $ogcontainer to $newcontainer"
    done
}

auth
copycontainer