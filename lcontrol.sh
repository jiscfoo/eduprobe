#!/bin/bash
# This script can be used to start|stop the nc listening processes for every port listed in monitored_tcp or monitored_udp
# Please edit the arrays below to configure the monitored ports, ranges are acceptable e.g. 20-24 will expand to 20 21 22 23 24
# port 22 exluded in testing
monitored_tcp=(21 80 110 143 220 389 406 443 465 587 636 993 995 1194 1494 3128 3389 5900 8080)
monitored_udp=(123 1194 4500 5000-5110 7000-7007)

# run with either 'up' or 'down' as a parameter 
updown=$1

# function starting the listeners
function up {
  ### Expand ranges in config array into an array of single ports
  local allports=''
  local index=0
  for dat in $@
    do
    if [[ $dat =~ [tcp|udp] ]]
    then
      proto=$dat
      continue
    fi
    # check for ranges in array and expand them
    if [[ $dat =~ ([0-9]+)-([0-9]+) ]] ;
    then
      range_start="${BASH_REMATCH[1]}"
      range_end="${BASH_REMATCH[2]}"
      if [[ $range_start -lt $range_end ]] ;
      then
        for ((i=$range_start; i <= $range_end; i++))
        do
          #echo "added $i at $index"
          allports[$index]=$i
          ((index++))
        done
      else
        echo "Range starts with value larger than the one it ends with"
        exit 1
      fi
    # if not a range just add it
    elif [[ $dat =~ ^[0-9]+$ ]]
    then
      #echo "added $dat at $index"
      allports[$index]=$dat
      ((index++))
    else
      echo "Please check monitored ports configuration, $dat doesn't look right"
      exit 1
    fi
  done
  
  for port in ${allports[@]}
  do
    /bin/bash ./listener $proto $port &
    echo "started listener for $proto/$port"
  done
}

function check_used_ports {
  local j=0
  local unique_open_ports=''
  local add=1
  while read openport
  do
    if [[ ${#unique_open_ports[@]} -gt -1 ]]
    then
      for seen in ${unique_open_ports[@]}
      do
        if [[ $openport -eq $seen ]]
	then
	  add=0
          continue
        fi
      done
      if [[ $add -eq 1 ]]
      then
        echo "port $openport is open"
	unique_open_ports[$i]=$openport
	((i++))
      fi
    else
      unique_open_ports[$i]=$openport
      ((i++))
    fi
  done < <(/bin/netstat -nlpt |awk '{print $4}' |sed -n -e 's/.*:\([0-9]\+\)$/\1/p')
  for openport in ${unique_open_ports[@]}
  do
    for monitored_port in 
    if [[ $openport -eq 
  done
}

check_used_ports

exit

# check the command and kick things off
if [[ $updown == 'up' ]] 
then
  up "udp" "${monitored_udp[@]}"
  up "tcp" "${monitored_tcp[@]}"
elif [[ $updown == 'down' ]]
then
  # kill all control instances
  while read ps
  do
    kill $ps > /dev/null
    if [[ ! $? -eq 0 ]]
    then
      echo "Failed to kill listener PID $ps, exit status $?"
    fi
  done < <(/bin/ps aux |grep -e 'listener [tcp|udp]' |awk '{print $2}')
  # kill all netcat instances
  while read ps
  do
    kill $ps > /dev/null
    if [[ ! $? -eq 0 ]]
    then
      echo "Failed to kill nc PID $ps, exit status $?"
    fi
  done < <(/bin/ps aux |grep nc |grep responder |awk '{print $2}')

  if [[ ! $err -eq 1 ]]
  then
    echo "All done, or nothing to stop"
  fi
else
  echo "This script can be used to start and stop the nc listening processes targeted by the eduroam probes"
  echo "Usage: 'lcontrol up' to start, 'lcontrol down' to kill"
  exit 1
fi
