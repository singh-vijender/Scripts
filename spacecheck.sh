#############################################################
# This script is to check space utilization of /app partion #
# on all production servers                                 #
# Note: ssh password less login is required                 #
#############################################################
#set -x
#scripts=/home/vijender.palsingh/scripts/
alert=75
date=`date +"%d/%m/%y"`
time=`date +"%H:%M:%S"`

cat /dev/null > crossed.txt
#cat /dev/null > sorted.txt
cat /dev/null > mail.txt
cat /dev/null > good.txt
cat /dev/null > good_sorted.txt
cat /dev/null > crossed_sorted.txt

echo "Hi Team," >> mail.txt
echo  >> mail.txt
echo "Server check started on $date at $time CET" >> mail.txt
echo  >> mail.txt
#echo "/app partition is high for below servers. Please take immediate action" >> mail.txt
#echo  >> mail.txt

echo >> good_sorted.txt
echo "Utilization of /app on all Prod servers at `date +"%H:%M:%S"` CET" >> good_sorted.txt
echo >> good_sorted.txt

remote_server1=(`cat /home/vijender.palsingh/scripts/list1_hosts`)        #Put all the servers you want to check `in the file /home/vijender.palsingh/hosts
remote_server2=(`cat /home/vijender.palsingh/scripts/list2_hosts`)       #Put all the servers you want to check `in the file /home/vijender.palsingh/hosts

login() {
        ssh $server "$@"
        echo -e
}

space_check_list1_crossed() {

        server=${remote_server1[$i]}
        login df -h /app | awk '{print $5}' | sed -ne 2p | cut -d"%" -f1 | while read output;
        do
                df1=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
                if [ $df1 -ge $alert ]; then
		echo "${remote_server1[$i]}"
                echo "$server - $df1" >> crossed.txt
                #cat /home/vijender.palsingh/crossed.txt | sort -r >> sorted.txt
                #echo "${remote_server[$i]} - Utlization of /app is $df1" >> crossed.txt
                else
			echo "${remote_server1[$i]}"
                        echo "$server - $df1" >> good.txt
                fi
        done
}

space_check_list2_crossed() {

        server=${remote_server2[$i]}
                login "df -h /app" | awk '{print $4}' | grep -vE "Avail" | cut -d"%" -f1 | sed -n '2p' | while read output;
	        do
                df2=$(echo $output)
                if [ $df2 -ge $alert ]; then
		echo "${remote_server2[$i]}"
                echo "$server - $df2" >> crossed.txt
                else
			echo "${remote_server2[$i]}"
                        echo "$server - $df2" >> good.txt
                fi
        done
}

number1=${#remote_server1[@]}

for (( i=0;i<$number1;i++)); do
        space_check_list1_crossed
done

number2=${#remote_server2[@]}

for (( i=0;i<$number2;i++)); do
        space_check_list2_crossed
done

cat crossed.txt | sort -rn -k3 >> crossed_sorted.txt
cat good.txt | sort -rn -k3 >> good_sorted.txt

if [ -s crossed.txt ]
then
	echo "/app partition is high for below servers. Please take immediate action" >> mail.txt
	echo  >> mail.txt
        cat crossed_sorted.txt >> mail.txt
        #echo "All servers are below threshold"
else
        echo "All servers are below threshold" >> mail.txt
        #cat crossed_sorted.txt >> mail.txt
fi

#echo "/app partition is high for below servers. Please take immediate action" >> mail.txt
#echo  >> mail.txt

#cat crossed_sorted.txt >> mail.txt

echo >> good_sorted.txt
cat good_sorted.txt >> mail.txt

echo "Space check finished at `date +"%H:%M:%S"` CET " >> mail.txt
echo  >> mail.txt
echo "Thanks and Regards," >> mail.txt
echo "HM_AO_TA" >> mail.txt

mailx -S smtp=smtp01 -r noreply@testing.com -s "Status Report of /app utilization on PROD servers" -c vijen2000@gmail.com < /home/vijender.palsingh/mail.txt

rm -f crossed.txt good.txt crossed_sorted.txt good_sorted.txt
