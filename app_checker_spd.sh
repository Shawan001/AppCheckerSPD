#!/bin/bash

# The purpose of the script is to monitor therap applications on real time. 
# Application status and response time can be monitored.

if [[ $# = 3 ]] # Parameters validation
then
	if [[ $(echo $1 | grep -E "^(secure|beta|help|demo|alpha0[1-3])\.therap(services|global)\.net$") ]] && [[ $(echo $2 | grep -E "^[0-9]{1,2}$") ]] && [[ $(echo $3 | grep -E "^[0-9]{1,2}$") ]]
	then
		echo "[+] Parameter validation :  OK"
	else
		echo "[-] Parameter validation : Failed"
		echo "[+] Usage : $0<space>url<space>sleeptime<space>max_waiting_time"
		echo "[+] Exiting..."
		exit
	fi
else
	echo "[-] Exactly 3 parameters expected"
	echo "[+] Usage : $0<space>url<space>sleeptime<space>max_connection_waiting_time"
	echo "[+] Exting..."
	exit
fi


site_url=$1
sleeptime=$2 # Interval(in seconds) between checks   
max_time=$3  # Maximum metric for response time

echo "### Secure checking started at $(date) ###" >> downtime.log.$site_url

spd-say -w "Secure site checking is starting now" # The purpose of spd-say is to send a message through speech dispatcher (speakers in general)


while true
do
	
	site_status=($(curl -s --max-time $max_time -w '\t%{time_total}\t%{remote_ip}\n' https://$site_url/auth/appStatus)) #Getting application status through provided url
	
	#site_ip=$(dig +short secure.therapservices.net)
	#site_ip=${site_status[2]}
	#total_time=${site_status[1]}
	
	if [[ $(echo ${site_status[0]} | grep '^OK$') ]] # Checking OK string
	then 
		echo -e "\e[92m[+] Secure Status [UP] [$(date)] [${site_status[2]}] [${site_status[1]}]"
		#spd-say "Secure site, up"
		sleep $sleeptime
	
	elif [[ $(echo ${site_status[0]} | grep '^[0-9].*') ]]  # Resolving connection time-out issue. If connection timed out then 1st index of the array will be filled up by provided max-time value 
        then
                echo -e "\e[31m[-] High latency detected on secure site [Time-${site_status[0]}]"
                spd-say -w "High latency detected on secure site"
                sleep $sleeptime

	elif [[ $(echo ${site_status[0]} | grep -o 'DOCTYPE') ]] # if application is not OK then the url returns sorry page. It is been just checked if returned eliments are part of the sorry page.
	then
		spd-say -w "Be alert, Check application please"
		sleep 5
		spd-say -w "Be alert, Check application please"
		#sleep 5
		#echo  "[-] Down at [$(date)] [IP-${site_status[2]}]" >> downtime.log.$site_url
		while true
		do
			site_status_re=($(curl -s -w '\t%{time_total}\t%{remote_ip}\n' https://$site_url/auth/appStatus)) # Double checking
			
			if [[ $(echo ${site_status_re[0]} | grep -o 'DOCTYPE') ]]
			then
				echo  "[-]Down at [$(date)] [IP-${site_status[-1]}] [Final_check]" >> downtime.log.$site_url.$(date "+[%d-%m-%y]")
				echo -e "\e[31m[-] Secure Status [Down] [$(date)] [${site_status[-1]}]"
				spd-say "Secure site, down"
				sleep 2
			elif [[ $(echo ${site_status_re[0]} | grep '^OK$') ]]
			then
				echo -e "\e[92m[+] Secure Status [UP] [$(date)] [${site_status[2]}] [${site_status[1]}]"
				spd-say "Secure site, up"
				echo "[+] Back up at [$(date)] [IP-${site_status[2]}}]" >> downtime.log.$site_url.$(date "+[%d-%m-%y]")
				break
			fi			
		done
	fi
done
