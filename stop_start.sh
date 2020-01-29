#!/bin/bash
date1=`date +%d%m%Y%H%M`
if [ $# -lt 1 ]
then
        echo "Usage : $0 Signalnumber PID"
        exit
fi


echo "Going to down $1 servers mention in list"

case "$1" in

HYBRIS|Hybris|hybris)  echo "Stoping $1 Servers"
    for server in $(cat /home/dinesh.a.patel/EU_PRD_Restart/hybris_PRD_list)
    do
    echo "Going to stop node $server"
    ssh appuser@"$server" '/app/hmonline/scripts/hybrisctl stop'
    echo "$date1 Node $server is down">>/home/dinesh.a.patel/EU_PRD_Restart/log/PRD_server_stop.log_"$date1"
    done

    ;;
ADOBE|Adobe|adobe)  echo  "Stopping $1 Servers"
     for server in $(cat /home/dinesh.a.patel/EU_PRD_Restart/adobe_PRD_list)
     do
     echo "Going to stop node $server"
     ssh appuser@"$server" '/app/hmonline/scripts/cqctl stop'
     echo "$date1 Node $server is down">>/home/dinesh.a.patel/EU_PRD_Restart/log/PRD_server_stop.log_"$date1"
     done

    ;;
JBOSS|Jboss|jboss)  echo  "Stopping $1 Servers"
    for server in $(cat /home/dinesh.a.patel/EU_PRD_Restart/jboss_PRD_list)
    do
    
 if [[ $server == *"01" ]]
then
    echo "Going to stop node $server"
    ssh appuser@"$server" '/app/hmonline/scripts/amqctl amq1m stop'
    ssh appuser@"$server" '/app/hmonline/scripts/amqctl amq2s stop'
    ssh appuser@"$server" '/app/hmonline/scripts/jbossctl files1 stop'
    ssh appuser@"$server" '/app/hmonline/scripts/jbossctl service1  stop'
    echo "$date1 Node $server is down">>/home/dinesh.a.patel/EU_PRD_Restart/log/PRD_server_stop.log_"$date1"
else
   
     echo "Going to stop node $server"
    ssh appuser@"$server" '/app/hmonline/scripts/amqctl amq2m stop'
    ssh appuser@"$server" '/app/hmonline/scripts/jbossctl service2 stop'
fi
    done
   ;;

SOLR|Solr|solr)  echo  "Stopping $1 Servers"
     for server in $(cat /home/dinesh.a.patel/EU_PRD_Restart/solr_PRD_list)
     do
     echo "Going to stop node $server"
     ssh appuser@"$server" '/app/hmonline/scripts/solrctl-slave stop'
     echo "$date1 Node $server is down">>/home/dinesh.a.patel/EU_PRD_Restart/log/PRD_server_stop.log_"$date1"
     done

    ;;



*) echo "Server $1 is not in our list"
   ;;
esac
