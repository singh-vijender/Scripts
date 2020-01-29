root@su583aos # cat /srvappli/wasadm/fmo_start_stop.sh
# script: fmo_weekend_check.sh                                               #
# Author: Vijender for Accenture                                             #
# Modified by : Sudip Kumar Mondal for Accenture
# Version: v1.0                                                              #
# Requirement: check MQ_INSTALL_ROOT for FMO on sunday                       #
#########################################################e####################

set -x

mail_KO_alert()
{
/usr/sbin/sendmail -t << EOM
To: IO.RN.MIDDLEWARE.Midrange@accenture.com,sandipan.roy@accenture.com,sayak.mukherjee@accenture.com
Subject: FMO weekend check

Hi,

We found below errors in the SystemOut.log

`cat /tmp/fmo_script/temp.log`

Thanks & Regards,
Accenture Middleware Team

EOM
}

mail_OK_alert()
{
/usr/sbin/sendmail -t << EOM
To: IO.RN.MIDDLEWARE.Midrange@accenture.com,sandipan.roy@accenture.com,sayak.mukherjee@accenture.com
Subject: FMO weekend check

Hi,

There is no error found in the logs. Application server is OK

Thanks & Regards,
Accenture Middleware Team

EOM
}

year=`date +%Y`
month=`date +%b`
date=`date +%d`
time=`date +%T`


log_file=/srvappli/was60/was/profiles/wacope6E/logs/w6EAS3/SystemOut.log
#log_file_bkp=/srvappli/was60/was/profiles/wacope6E/logs/w6EAS3/SystemOut.log.bkupByScript_`date | awk '{print $1,$2,$3,$4}' | sed 's/ /_/g'`

while true
do
        grep WMSG0902E $log_file | grep "MQ_INSTALL_ROOT variable has not been set" > /tmp/fmo_script/temp.log
        RC=$?
        if [ $RC = 0 ]
                then
                ######Take a backup of the old log file########
                log_file_bkp=/srvappli/was60/was/profiles/wacope6E/logs/w6EAS3/SystemOut.log.bkupByScript_$date.$month.$year.$time
                cp $log_file $log_file_bkp
                cat /dev/null > $log_file

                ######stop#####
                echo "So we stopped the application server as below" >> /tmp/fmo_script/temp.log
                /srvappli/was60/was/profiles/wacope6E/bin/stopServer.sh w6EAS3 >> /tmp/fmo_script/temp.log
                sleep 30

                #####start#####
                echo "And restarted as below" >> /tmp/fmo_script/temp.log
                /srvappli/was60/was/profiles/wacope6E/bin/startServer.sh w6EAS3 >> /tmp/fmo_script/temp.log
                sleep 30


        mail_KO_alert

        else
        echo "Error Not Found. No restart required" >> /tmp/fmo_script/temp.log
        mail_OK_alert
                exit 0

fi
done
