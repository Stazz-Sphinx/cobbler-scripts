#!/bin/bash
# This script  should help  to working with Cobbler server. It can add, dell , edit VMs.


#set -x
# Function show default help information
function usage(){
	  echo -e "Usage:\n"
	  echo "Show information from Cobler, by name server  or ip adress."
	  echo "./cobbler.sh show [server name] or [ip address] - it show information by name"
	  echo "./cobbler.sh add  [server name] [ip address] [mac address] [profile name]"
	  echo "./cobbler.sh remove  [server name]"
}

# Function check valid IP adress in 32-bit format (IP v4)
function valid_ip(){

    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    if [[ "$stat" -eq 0 ]]; then return $stat;  else echo  -e "\nThe ip adress is not valid."; return $stat; fi
}

# Function check MAC adress
function valid_mac(){

    local mac=$1
    
    if [[ $mac =~ ^([0-9a-f][0-9a-f]:){5}[0-9a-f][0-9a-f]$ ]]; then
	return 0
	else
	     echo -e "\nMAC $mac address is not valid. Please check!\n"
	     return 1
    fi
}

# Function check server name in format *.stazz-sphinx.net
function valid_server_name(){

	local server=$1
	if [[ $server =~ .*\.stazz\-sphinx\.net$ ]];  then  
	    return 0 
	else 
	    echo -e "\nThe server name $server is not walid. Please check."
	    echo -e "It should be like [hostname].stazz-sphinx.net"
	    return 1
	fi
}

# Function check profile name for new server. It should be like RHEL-Server-5.9-x86_64
function valid_server_profile(){
      local profile=$1
      
	if [[ "$profile" =~ ^(RHEL-Server-|CentOS).* ]]; then
	      return 0
	 else
	      sudo cobbler repo list;
	      echo -e "\nChoose correct OS profile from list below to install."
	      return 1
	fi  
}

CASE=$1
case $CASE in 
# Show info aboout server by name or ip.
	show)
	if [[ "$2" = "" ]]; then 
	  echo -e "\nThis command show infromation about server by provided padameters. For example:\n"
  	  echo -e "./cobbler.sh show [server name] or [ip address] - it show information by name"
	  echo -e "./cobbler.sh show hostname.example.com \treturn to you information about this server."
	  echo -e "./cobbler.sh show 192.168.110.26 \t\t return to you server name by provided ip."
	  exit 
	fi
	
	SERVER=$2 
	IP=$2
	if  valid_ip $IP; then  
	  sudo cobbler system report | grep  -B44 $IP  | grep -E 'Hostname|IP Address|DNS Name'
	  else 
	    echo -e "Showing information about $SERVER\n" ;
	    sudo cobbler system report --name=$SERVER ;
	fi
	
	exit;;
# Add server in to Cobbler
	add) 
	if [[ "$2" = "" ]]; then 
	  echo -e "\nThis command add server by provided parameters to the Cobbler. For example:\n"
	  echo "./cobbler.sh add  [server name] [ip address] [mac address] [profile name]"	  
	  exit 
	fi
	echo -e "Adding server in to Cobbler ... \n";
	SERVER=$2
	IP=$3
	MAC=$4
	PROFILE=$5
	if valid_mac "$MAC"  &&  valid_ip $IP  && valid_server_name $SERVER && valid_server_profile $PROFILE; then 
	    sudo cobbler system add --name=$SERVER --mac-address=$MAC --ip-address=$IP  --interface=ens160 --profile=$PROFILE --hostname=$SERVER --dns-name=$SERVER
	      else 
		  echo "Please check parameters. ";
	fi
	exit;;
# Remove server from Cobbler
	remove)
	if [[ "$2" = "" ]]; then 
	  echo -e "\nThis command remove server Cobbler. For example:\n"
	  echo "./cobbler.sh remove hostname.example.com"
	  exit
	fi
	
	SERVER=$2;

		if valid_server_name $SERVER;  then
		echo -e "\n Removing server from Cobbler ... "
		sudo cobbler system remove --name=$SERVER;
		    else
			echo "Please check parameters. ";
		fi	
	exit;;
	
# Default parameters
	*) 
	usage
	exit;;
esac	
 
