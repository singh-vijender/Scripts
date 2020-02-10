Main.sh

#!/bin/bash
### get currnet location
LOC=`dirname $0`
CONF=${LOC}/config.cfg
LOG=${LOC}/`grep ^LOGFILE ${CONF} | cut -d':' -f2`

ARG1=$1

${LOC}/1*sh
${LOC}/2*sh
${LOC}/3*sh
${LOC}/4*sh
${LOC}/5*sh
${LOC}/6*sh
${LOC}/7*sh
if [ "X${ARG1}" == "XNOMAIL" ]; then
  echo "We promiss, no mail... no one will know.... :) "
else
  ${LOC}/8*sh
fi
${LOC}/9*sh





------------------------------------------------------------------------------

1_Collect_raw_dump_and_basic_format.sh


#!/bin/bash
### get currnet location
LOC=`dirname $0`
CONF=${LOC}/config.cfg
LOG=${LOC}/`grep ^LOGFILE ${CONF} | cut -d':' -f2`
SCRIPT_TO_RUN=${LOC}/str.sh
SVC_DUMP=${LOC}/svc.dump
DEP_DUMP=${LOC}/single_source.txt

echo "Starting $0 ....." >> $LOG
cat /dev/null > ${SVC_DUMP}
cat /dev/null > ${DEP_DUMP}

### to be removed will handle in mail logic
MAILS=${LOC}/summary.mail
cat /dev/null > $MAILS

########### version V4  10 min logic #########
DATE=`date +%H%M`
EXTN="`echo ${DATE} | cut -c1-3`0"
echo "${EXTN}" > ${LOC}/date.extn
#######################################################
########## Version V3 comment logic for 30 min #################
#MIN=`date +%M`
#if [ "$MIN" -ge 30 ]; then
#echo "`date +%H`30" > ${LOC}/date.extn
#else
#echo "`date +%H`00" > ${LOC}/date.extn
#fi
########################################################

for line in `grep ^K8S ${CONF}`
do
  DC=`echo $line |cut -d':' -f2`
  SERVER=`echo $line |cut -d':' -f3`
  ADMINCONF=`echo $line |cut -d':' -f4`

  ##################################
  ###  Pulling svc raw dump
  ##################################

  ### command to pull svc data
  SVCCMD="export PATH=/usr/local/bin:\$PATH; export KUBECONFIG=${ADMINCONF}; kubectl get svc --all-namespaces --show-labels"

  ### pulling data
  /usr/local/bin/sshcmd -u enabler -s $SERVER -q "$SVCCMD" >  ${LOC}/${SERVER}_svc_temp.txt

  ### filter collected data
  cat ${LOC}/${SERVER}_svc_temp.txt | grep -e '=green' -e '=blue' | grep -v -e '-green' -e '-blue' | tr -s " "| sed 's/ /,/g' | cut -d',' -f 1
,2,10 | sed 's/,/|/g' > ${LOC}/${SERVER}_svc_filter.txt

  ### formate collected data and put in single dump
  while read ln
  do
    echo "${DATE}|${DC}|${SERVER}|$ln"
  done < ${LOC}/${SERVER}_svc_filter.txt >> $SVC_DUMP

  ### clean up
  rm ${LOC}/${SERVER}_svc_temp.txt ${LOC}/${SERVER}_svc_filter.txt
  #####################################


  ##################################
  ###  Pulling deployment raw dump
  ##################################

  ### command to pull deployment data
  DEPCMD="export PATH=/usr/local/bin:\$PATH; export KUBECONFIG=${ADMINCONF}; kubectl get deploy --all-namespaces --no-headers ; kubectl get ds
 --all-namespaces --no-headers "

  ### pulling data
  /usr/local/bin/sshcmd -u enabler -s $SERVER -q "$DEPCMD" >  ${LOC}/${SERVER}_dep_temp.txt

  ### filter collected data
  #cat ${LOC}/${SERVER}_svc_temp.txt | grep -e '=green' -e '=blue' | grep -v -e '-green' -e '-blue' | tr -s " "| sed 's/ /,/g' | cut -d',' -f
1,2,10 | sed 's/,/|/g' > ${LOC}/${SERVER}_svc_filter.txt
  sed -i -e 's/\// /g' ${LOC}/${SERVER}_dep_temp.txt
  cat ${LOC}/${SERVER}_dep_temp.txt | tr -s " " > ${LOC}/${SERVER}_dep_filter.txt
  sed -i -e 's/ /|/g'  ${LOC}/${SERVER}_dep_filter.txt


  ### formate collected data and put in single dump
  while read ln
  do
    echo "${DATE}|${DC}|${SERVER}|$ln"
  done < ${LOC}/${SERVER}_dep_filter.txt >> ${DEP_DUMP}

  ### clean up
  rm ${LOC}/${SERVER}_dep_temp.txt ${LOC}/${SERVER}_dep_filter.txt
  #############################################
done




--------------------------------------------------------------------------------


2_filter.sh


LOC=`dirname $0`

CONFIG_FILE=${LOC}/config.cfg
COLLECTED_DATA=${LOC}/single_source.txt
FILTER_DATA=${LOC}/filtered_source.txt
SKIPPER_WORDS=${LOC}/skipper.txt
HIGHLIGHTER=${LOC}/highlighter.txt
HIGH_MS=${LOC}/highlighterMS.txt
LOG=${LOC}/log.log
POP_LIST=${LOC}/pop.txt
POP_NAME=${LOC}/popname.txt
##############################
#### Filter data --- remove skip match
##############################
echo "Applying SKIP filter...." >> $LOG
grep ^SKIP ${CONFIG_FILE} | cut -d':' -f3 > ${SKIPPER_WORDS}
fgrep -v -w -f ${SKIPPER_WORDS} ${COLLECTED_DATA} > ${FILTER_DATA}


##############################
#### Filter data --- collect highlighers match
##############################
echo "Getting Highlight keywords and values...." >> $LOG
grep ^HIGHLIGHT ${CONFIG_FILE} | awk -F':' 'BEGIN{OFS="|";} {print $3,$4,$5;}' > ${HIGHLIGHTER}
grep ^HIGHLIGHT ${CONFIG_FILE} | cut -d':' -f 3 > ${HIGH_MS}
grep ^POP ${CONFIG_FILE} | awk -F':' 'BEGIN{OFS="|";} {print $2,$3,$4;}' > ${POP_NAME}
grep ^POP ${CONFIG_FILE} | cut -d':' -f 3 > ${POP_LIST}

mv $FILTER_DATA $COLLECTED_DATA



--------------------------------------------------------------------------------


4_GREEN_BLUE_MS_process.sh


#!/bin/bash
### get currnet location
LOC=`dirname $0`
CONF=${LOC}/config.cfg
LOG=${LOC}/`grep ^LOGFILE ${CONF} | cut -d':' -f2`
MAILS=${LOC}/summary.mail
DATA=${LOC}/GB_single_source.txt
SVC_DUMP=${LOC}/svc.dump

GB_FINAL_DUMP=${LOC}/GB_final_dump.txt
GB_HTML_BODY=${LOC}/GB_html_body.html

cat /dev/null > $GB_FINAL_DUMP
cat /dev/null > $GB_HTML_BODY

for row in `sort ${LOC}/GB_deploymentlist_extn_removed_sort_uniq.txt`
do
  #echo "------ $row ---------"
  FLAG="4NORM"
  CHECK='FIRSTRUN'
  LINE=""
  #LINE="<tr><td><b>$row </b></td>"
  for col in `sort ${LOC}/DC_LIST.txt`
  do
    POG=`grep -w "${row}-green" ${DATA} | grep $col | cut -d'|' -f9`
    POB=`grep -w "${row}-blue"  ${DATA} | grep $col | cut -d'|' -f9`
    LASTPO=""
    #### Make pod number -1 if not existing....
    if [ "X${POG}" == "X" ];then
      POG='-1'
    fi
    if [ "X${POB}" == "X" ]; then
      POB='-1'
    fi
    ###########################################

    ###########################################
    SVC_MARK=""
    SVC_COL=""
    if [ "$POG" -eq 0 ] && [ "$POB" -eq 0 ] ; then
      echo "[GB] $row $col : $POG $POB ---- why both are zero " >> $LOG
      SVC_MARK=`grep -w $row $SVC_DUMP | grep $col | cut -d'|' -f6`
      SVC_COL=`echo $SVC_MARK | cut -d'=' -f2`
      LINE="${LINE}<td bgcolor=red>0/0 <br> --${SVC_MARK}</td>"
      LASTPO=0
      FLAG="2HIGH"
      echo "PODS are ZERO for both green and blue deployment for deploy : [ $row ] on DC : [ $col ]" >> $MAILS
      echo "`grep -w "${row}-${SVC_COL}" ${DATA} | grep $col | sed s/-${SVC_COL}//g`" >> $GB_FINAL_DUMP
    elif [ "$POG" -gt 0 ] && [ "$POB" -gt 0 ] ; then
      echo "[GB] something fishy $row $col --- green:$POG blue:$POB " >> $LOG
      SVC_MARK=`grep -w $row $SVC_DUMP | grep $col | cut -d'|' -f6`
      SVC_COL=`echo $SVC_MARK | cut -d'=' -f2`
      LINE="${LINE}<td bgcolor=red>${POG}/${POB} <br> --${SVC_MARK}</td>"
      LASTPO=999
      FLAG="2HIGH"
      echo "PODS are up on both green and blue deployment for deploy : [ $row ] on DC : [ $col ]" >> $MAILS
      echo "`grep -w "${row}-${SVC_COL}" ${DATA} | grep $col | sed s/-${SVC_COL}//g`" >> $GB_FINAL_DUMP
    else
      echo "[GB] ${row}|${col}|green:${POG}|blue:${POB}" >> $LOG
      if [ "$POG" -gt "$POB" ]; then
        echo "`grep -w "${row}-green" ${DATA} | grep $col | sed 's/-green//g'`" >> $GB_FINAL_DUMP
        LINE="${LINE}<td><b><font color=lime >${POG}</font></b></td>"
        LASTPO=${POG}
      else
        if [ "$POB" -eq '-1' ];then
          LINE="${LINE}<td bgcolor=gray>NA</td>"
          LASTPO=-1
        else
          echo "`grep -w "${row}-blue" ${DATA} | grep $col | sed 's/-blue//g'`" >> $GB_FINAL_DUMP
          LINE="${LINE}<td><b><font color=blue>${POB}</font></b></td>"
          LASTPO=${POB}
        fi
      fi
    fi
    ###########################################

    if [ "X${CHECK}" == "XFIRSTRUN" ]; then
      CHECK="$LASTPO"
    else
      if [ "$FLAG" == "4NORM" ] && [ "$CHECK" -ne "$LASTPO" ]; then
        FLAG="3DIFF"
      fi
        CHECK="$LASTPO"
    fi

  done

  if [ "${FLAG}" == "2HIGH" ]; then
    LINE="2HIGH<tr><td bgcolor=#FF9494> $row </td>${LINE}</tr>"
  fi
  if [ "${FLAG}" == "3DIFF" ]; then
    LINE="3DIFF<tr><td bgcolor=#BBBBBB> $row </td>${LINE}</tr>"
  fi
  if [ "${FLAG}" == "4NORM" ]; then
    LINE="4NORM<tr><td> $row </td>${LINE}</tr>"
  fi
  echo "${LINE}" >> $GB_HTML_BODY

done

#rm $SVC_DUMP



--------------------------------------------------------------------------------


5_NOGB_MS_process.sh


#!/bin/bash
### get currnet location
LOC=`dirname $0`
CONF=${LOC}/config.cfg
LOG=${LOC}/`grep ^LOGFILE ${CONF} | cut -d':' -f2`

ROW=${LOC}/NOGB_deployment_list.txt
COL=${LOC}/NOGB_DC_list.txt
DATA=${LOC}/NO_GB_refined_single_source.txt

NOGB_HTML_BODY=${LOC}/NOGB_html_body.html

cat /dev/null > $NOGB_HTML_BODY

######## Table data generator - Normal #######
echo "[NOGB] generating complete table body data.... " >> $LOG

cat ${LOC}/NO_GB_refined_single_source.txt | cut -d'|' -f5 | sort | uniq >$ROW
cat ${LOC}/NO_GB_refined_single_source.txt | cut -d'|' -f2 | sort | uniq >$COL

for row in `sort ${ROW}`
do
    #echo "----- $row -----"
    FLAG="4NORM"
    CHECK='FIRSTRUN'
    LINE=""
    for col in `sort ${COL}`
    do
        PODS=`grep -w ${row} ${DATA} | grep ${col}| tail -1 |cut -d'|' -f7`
        if [ "X${PODS}" == "X" ]; then
          PODS='-1'
        fi
        echo "[NOGB] $row -- $col -- $PODS -- $CHECK" >> $LOG
        if [ "X${CHECK}" == "XFIRSTRUN" ]; then
          CHECK="$PODS"
        else
          if [ "$FLAG" == "4NORM" ] && [ "$CHECK" -ne "$PODS" ]; then
             FLAG="3DIFF"
          fi
          CHECK="$PODS"
        fi
        if [ "$PODS" -ne -1 ];then
          LINE="${LINE}<td>${PODS}</td>"
        else
          LINE="${LINE}<td bgcolor=gray>NA</td>"
        fi
    done
    #echo "FLAG --- $FLAG"


    if [ "${FLAG}" == "3DIFF" ]; then
      LINE="3DIFF<tr><td bgcolor=#BBBBBB> $row </td>${LINE}</tr>"
    fi

    if [ "${FLAG}" == "4NORM" ]; then
      LINE="4NORM<tr><td> $row </td>${LINE}</tr>"
    fi
    #LINE="${LINE}</tr>"

    echo "${LINE}" >> $NOGB_HTML_BODY
done

---------------------------------------------------------------------------------------------



6_highlighter.sh


#!/bin/bash
### get currnet location
LOC=`dirname $0`
CONF=${LOC}/config.cfg
LOG=${LOC}/`grep ^LOGFILE ${CONF} | cut -d':' -f2`
MAILS=${LOC}/summary.mail
COL=${LOC}/DC_LIST.txt
DATA=${LOC}/NO_GB_refined_single_source.txt
DATA2=${LOC}/GB_final_dump.txt
GB_HTML_BODY=${LOC}/GB_html_body.html
NOGB_HTML_BODY=${LOC}/NOGB_html_body.html
SVC_DUMP=${LOC}/svc.dump

grep '=red' $GB_HTML_BODY > ${LOC}/CheckRed.html

echo "[HGIHLIGHT] generating highligher data...." >> $LOG
######## Table data generator - Highlight #######
cat /dev/null > ${LOC}/html_highligted.html
for hrow in `cat ${LOC}/highlighter.txt`
do
  HSERV=`echo $hrow | cut -d'|' -f1`
  PODCOUNT=`echo $hrow | cut -d'|' -f2`
  LINE="1ALTR<tr><td bgcolor=#c0decd > $HSERV --[${PODCOUNT}] </td>"
  for col in `sort ${COL}`
  do
    SVC_MARK=""
    SVC_MARK=`grep "|${HSERV}|" $SVC_DUMP | grep $col | cut -d'=' -f2`
    if [ "X${SVC_MARK}" == "X" ] ; then
      SVC_MARK=black
    fi
    #echo "[HIGHL $HSERV $col] $SVC_MARK"
    PODS=`grep "|${HSERV}|" ${DATA} ${DATA2} | grep ${col} | tail -1 |cut -d'|' -f7`
    if [ "X${PODS}" == "X" ]; then
      PODS='-1'
    fi
    echo "[HIGHLIGHT] ${col}:${HSERV} -- expected: $PODCOUNT -- currnet: $PODS " >>$LOG
    if [ "${PODCOUNT}" -le "${PODS}" ]; then
      LINE="${LINE}<td bgcolor=#c0e3ea ><b><font color=$SVC_MARK >${PODS}</font></b></td>"
    else
      if [ "X${PODS}" == "X-1" ]; then
        LINE="${LINE}<td bgcolor=gray >NA</td>"
      else
        LINE="${LINE}<td bgcolor=#ff9955 ><b><font color=$SVC_MARK >${PODS}</font></b></td>"
      fi
      echo "HIGHLIGHTED deployment :[ $HSERV ] on DC : [ $col ] --- pod values : [ $PODS ] is below expected [ $PODCOUNT ] " >> $MAILS
      #echo "`date +%Y%m%d:%H%M`|${HSERV}|${col}|${PODS}|${PODCOUNT}" >> ${LOC}/mailit.mal
    fi
  done
  LINE="${LINE}</tr>"
  echo "${LINE}" >> ${LOC}/html_highligted.html
  ####### remove from GB and NOGB #################
  sed -i -e "/${HSERV}/d" $GB_HTML_BODY
  sed -i -e "/${HSERV}/d" $NOGB_HTML_BODY
  #################################################
done

cp $GB_HTML_BODY ${LOC}/GB_TEMP.html
sed -i -e /=red/d ${LOC}/GB_TEMP.html

cat ${LOC}/CheckRed.html ${LOC}/GB_TEMP.html > $GB_HTML_BODY

#rm $SVC_DUMP





------------------------------------------------------------------------------------



7_html_generator.sh
#!/bin/bash
### get currnet location
LOC=`dirname $0`
CONF=${LOC}/config.cfg
LOG=${LOC}/`grep ^LOGFILE ${CONF} | cut -d':' -f2`
MAILS=${LOC}/summary.mail

DATA=${LOC}/NO_GB_refined_single_source.txt
DATA2=${LOC}/GB_final_dump.txt
POP_LIST=${LOC}/pop.txt
POP_NAME=${LOC}/popname.txt


GB_HTML_BODY=${LOC}/GB_html_body.html
NOGB_HTML_BODY=${LOC}/NOGB_html_body.html
HI_HTML_BODY=${LOC}/html_highligted.html

ADD_INFO=${LOC}/additional_info.txt
EXTN=`cat ${LOC}/date.extn`
MAIL_HTML=${LOC}/alert_html.html
FINAL_HTML=${LOC}/result_${EXTN}.html
HTML_HOME=`grep ^HTML_HOME ${CONF} | cut -d':' -f3`
APH_HOME=`basename $HTML_HOME`
mkdir -p ${HTML_HOME}/CURRENT

#########################################
## Generation addional info
########################################
echo "<br><br>" > $ADD_INFO

echo "<b> SKIPPED keyword </b><br>" >>$ADD_INFO
for SKP in `cat $CONF | grep ^SKIP | cut -d':' -f3`
do
  echo "${SKP}<br>" >>$ADD_INFO
done

echo "<br><br>" >> $ADD_INFO
echo "<b> HIGHLIGHTER keyword </b><br>" >>$ADD_INFO
for HIG in `cat $CONF | grep ^HIGHL `
do
  HIGHW=`echo ${HIG} | cut -d':' -f3`
  EPOD=`echo ${HIG} | cut -d':' -f4`
  echo "${HIGHW} --- set for expected pod number [ $EPOD ]<br>" >>$ADD_INFO
done

echo "<br><br>" >> $ADD_INFO
echo "<b> Separately marked </b><br>" >>$ADD_INFO
for POP in `cat $CONF | grep ^POP `
do
  APP=`echo ${POP} | cut -d':' -f2`
  MSS=`echo ${POP} | cut -d':' -f3`
  echo "[${APP}] is marked for -- microservice: [${MSS}] <br>" >>$ADD_INFO
done

echo "<br><br>" >> $ADD_INFO
echo "<b> Alert Snoozed for :</b><br>" >>$ADD_INFO
for SNZ in `cat $CONF | grep ^SNOOZE | cut -d':' -f3`
do
  echo "${SNZ}<br>" >>$ADD_INFO
done

echo "<br><br>" >> $ADD_INFO
echo "<b> Namespace [Record fetched] </b><br>" >> $ADD_INFO
for NSL in `cat $DATA $DATA2 | cut -d'|' -f4 | sort | uniq`
do
  echo "${NSL} [ `cat $DATA $DATA2 | grep -c ${NSL}` ]<br>" >> $ADD_INFO
done

echo "<br><br>" >> $ADD_INFO
NEEDMAIL=`grep ^MAIL $CONF | grep MAIL_ENABLE |cut -d':' -f3`
if [ "X$NEEDMAIL" == "Xtrue" ]; then
  echo "<b> !!! Mail alerts are enabled !!! </b><br>" >> $ADD_INFO
else
  echo "<b> !!! Mail alerts are disabled !!! </b><br>" >> $ADD_INFO
fi
#########################################



############### Begin HTML generation ###########
echo "<html><head><meta http-equiv="refresh" content="60"></head><body>" > $FINAL_HTML

############# links for backup data #############
echo "[<a href="http://zlp12380.vci.att.com:8080/${APH_HOME}/result-0.html">NOW</a>]" >> ${FINAL_HTML}
echo "[<a href=\"http://zlp12380.vci.att.com:8080/${APH_HOME}/result-1.html\">history-1</a>]" >> ${FINAL_HTML}
echo "[<a href=\"http://zlp12380.vci.att.com:8080/${APH_HOME}/result-2.html\">history-2</a>]" >> ${FINAL_HTML}
echo "[<a href=\"http://zlp12380.vci.att.com:8080/${APH_HOME}/result-3.html\">history-3</a>]" >> ${FINAL_HTML}
echo "[<a href=\"http://zlp12380.vci.att.com:8080/${APH_HOME}/result-4.html\">history-4</a>]" >> ${FINAL_HTML}
echo "[<a href=\"http://zlp12380.vci.att.com:8080/${APH_HOME}/result-5.html\">history-5</a>]" >> ${FINAL_HTML}
echo "<br><br>" >> ${FINAL_HTML}
##################################################



######### dividing page in two, this part will be first half ##########
echo "<table><tr><td width=50%>" >> ${FINAL_HTML}

####### Table and  Header generator #####
echo "<table border=1>" >> $FINAL_HTML
HEAD="<tr><td>`date +%m%d%Y:%H%M` <br>Deployment/DC</td>"
for headcol in `sort ${LOC}/DC_LIST.txt`
do
    HEAD="${HEAD}<td>--- ${headcol}  ---</td>"
done
HEAD="${HEAD}</tr>"
echo ${HEAD} >> $FINAL_HTML
#########################################

########## Table body generator #########
#cat $GB_HTML_BODY $NOGB_HTML_BODY $HI_HTML_BODY | sort | cut -c6- >> $FINAL_HTML
cat $GB_HTML_BODY $NOGB_HTML_BODY $HI_HTML_BODY |fgrep -w -f ${POP_LIST} | sort | cut -c6- > ${LOC}/part1

for pp in `cat ${POP_NAME}`
do
NAME=`echo $pp | cut -d'|' -f 1`
MS=`echo $pp | cut -d'|' -f 2`
sed -i -e "s:\b${MS}\b:[${NAME}] <b>${MS}</b>:g" ${LOC}/part1
done

sort ${LOC}/part1 >> $FINAL_HTML

cat $GB_HTML_BODY $NOGB_HTML_BODY $HI_HTML_BODY |fgrep -w -v -f ${POP_LIST} | sort | cut -c6- > ${LOC}/part2

cat ${LOC}/part2 >> $FINAL_HTML
echo "</table>" >> $FINAL_HTML

rm ${LOC}/part1 ${LOC}/part2
#########################################

########### Alert email body ##########
echo "<html><body>"  > $MAIL_HTML
echo "<table border=1>" >>$MAIL_HTML
echo ${HEAD} >>$MAIL_HTML
grep -w -e ff9955 -e red $FINAL_HTML | grep -v 'ALERT!!!!' >> $MAIL_HTML
echo "</table>" >> $MAIL_HTML
echo "<br><br><h3>For full report [<a href="http://zlp12380.vci.att.com:8080/${APH_HOME}/result-0.html">click here</a>] </h3><br>" >> $MAIL_HT
ML
echo "</body></html>" >> $MAIL_HTML
#######################################

####################### first half over ####################
####################### second half begins #################
echo '</td><td valign="top" width=50%>' >> $FINAL_HTML

cat ${LOC}/legends.DND >>${FINAL_HTML}
cat $ADD_INFO >> $FINAL_HTML

echo "</td></tr></table>" >>${FINAL_HTML}
echo "<a href="https://wiki.web.att.com/display/SSI/POD+Monitor+Tool">wiki</a>" >> ${FINAL_HTML}
####################### second half ends   ################

########   adding addtional info and finising html  ########
#cat $ADD_INFO >> $FINAL_HTML

echo "</body></html>" >> $FINAL_HTML
############################################################

###################  HTML copy to Apache location ##########
#cp $FINAL_HTML /opt/app/workload/httpserver/htdocs/RB_TEST/
rm ${HTML_HOME}/CURRENT/result_*html 2>/dev/null
cp ${FINAL_HTML} ${HTML_HOME}/CURRENT
#echo "${HTML_HOME}/CURRENT"
#ls -l ${HTML_HOME}/CURRENT
############################################################

################## invoke link manager to update softlins ####
${LOC}/_7_link_manager.sh
##############################################################







---------------------------------------------------------------------------------------------




8_mail_logic.sh


#!/bin/bash
### get currnet location
LOC=`dirname $0`
CONF=${LOC}/config.cfg
LOG=${LOC}/`grep ^LOGFILE ${CONF} | cut -d':' -f2`
EXTN=`cat ${LOC}/date.extn`
HTML=${LOC}/result_${EXTN}.html
MAILS=${LOC}/summary.mail
MAILHRLY=${LOC}/hourly_summary.mail
ALERT_HTML=${LOC}/alert_html.html
MAILSUB='[MONITOR] 911 POD count Alert'

NEEDMAIL=`grep ^MAIL $CONF | grep MAIL_ENABLE |cut -d':' -f3`
HOURLY_MAIL=`grep ^MAIL $CONF | grep ONLYHOURLY |cut -d':' -f3`
RECEIVER="`grep ^MAIL $CONF | grep MAILLIST | cut -d':' -f3`"

HOUR00=`cat ${LOC}/date.extn | cut -c3,4`

MAIL_TRIG=${LOC}/MAIL_TRIG.txt

grep -w -e ff9955 -e red ${HTML} | grep -v 'ALERT!!!!' > ${MAIL_TRIG}

for snz in `grep ^SNOOZE $CONF | grep -v grep | cut -d':' -f3`
do
  sed -i -e /$snz/d $MAILS
  sed -i -e /$snz/d $ALERT_HTML
  sed -i -e /$snz/d ${MAIL_TRIG}
done


while read sum
do
echo "[ $EXTN ] $sum <br>" >> $MAILHRLY
done < $MAILS


##### function to send mail -- need body file in arugment #########
letsMail(){
(
echo "To:$RECEIVER "
echo "From: DL-alerts-idpsystem@att.com"
echo "Subject: $MAILSUB"
echo "MIME-Version:1.0"
echo "Content-Type:text/html;"
cat $1
echo ""
echo ""
) | /usr/sbin/sendmail $RECEIVER
}
####################################################################

if [ "X$NEEDMAIL" == "Xtrue" ]; then
  if [ "X${HOURLY_MAIL}" == "Xtrue" ]; then
    if [ "X${HOUR00}" == "X00" ]; then
      if [ `wc -l $MAILHRLY | awk '{print $1}'` -eq 0 ] ;then
        echo "[HOURLY Mail] `date +%d%m%H%M` nothing to send in email...." >> $LOG
      else
        #cat $MAILHRLY | mailx -s "${MAILSUB} HOURLY report" -a $HTML $RECEIVER
        #cat $HTML | mailx -s "${MAILSUB} HOURLY report" -a $HTML $RECEIVER
        letsMail $ALERT_HTML $MAILHRLY
      fi
      cat /dev/null > $MAILHRLY
    fi
  else
    #if [ `wc -l $MAILS | awk '{print $1}'` -eq 0 ] ;then
    if [ `wc -l ${MAIL_TRIG} | awk '{print $1}'` -eq 0 ] ;then
      echo "[Mail] `date +%d%m%H%M` nothing to send in email...." >> $LOG
    else
      #cat $MAILS | mailx -s "$MAILSUB" -a $HTML $RECEIVER
      #cat $HTML | mailx -s "$MAILSUB" -a $HTML $RECEIVER
      letsMail $ALERT_HTML $MAILS 2>/dev/null
      #cat /dev/null > $MAILS
    fi
  fi
fi

cat /dev/null > /var/spool/mail/enabler





-----------------------------------------------------------------------------------





9_cleanup.sh


LOC=`dirname $0`
DAY00=`cat ${LOC}/date.extn | cut -c1,2`

mv ${LOC}/result*html ${LOC}/BKP/
for r in `ls ${LOC}/BKP/*html`
do
gzip -f $r
done

rm ${LOC}/*txt ${LOC}/*html

if [ "X${DAY00}" == "X00" ]; then
cat /dev/null > ${LOC}/log.log
fi





--------------------------------------------------------------------------------



config.cfg

#K8SOLD1:OLD_ALDC:host04006:/home/enabler/.kube/admin.conf_local:
K8SNEW1:DATACENTER:Server:PATH_TO_admin.conf:
K8SNEW1:AL_Set_1:host38911:/home/enabler/.kube/admin.conf:
K8SNEW1:AL_Set_2:host40245:/home/enabler/.kube/admin.conf:
#K8SOLD1:DLD_C1:host39378:/home/enabler/.kube/admin.conf:
K8SNEW1:DL_Set_1:hosty10990:/home/enabler/.kube/admin.conf:
K8SNEW1:DL_Set_2:hosty10282:/home/enabler/.kube/admin.conf:
#K8SOLD1:FF1:host29035:/home/enabler/.kube/admin.conf:
K8SNEW1:FF_set_1:host39195:/home/enabler/.kube/admin.conf:
K8SNEW1:FF_set_2:host39423:/home/enabler/.kube/admin.conf:
#K8SNEW1:ALD_C2:host38911:/home/enabler/.kube/admin.conf:
##### log file ######
LOGFILE:log.log:
#### Mail configuration ######
MAIL:MAIL_ENABLE:true:
MAIL:MAILLIST:DL-@company.com rb1277@company.com dl-IDP-alert@list.company.com
MAIL:ONLYHOURLY:false:
#### Snooze keywords ######
SNOOZE:ALERT:billms:
#SNOOZE:ALERT:edgeprofilefileprocessms:
#### Apache home ######
HTML_HOME:hostlocation:/opt/httpserver/htdocs/POD_MONITOR_V3
##### skip keyworkds ######
SKIP:NAMESPACE:com-company-elkpaas:
SKIP:NAMESPACE:kube-system:
SKIP:NAMESPACE:com-company-ocnp-mgm:
SKIP:NAMESPACE:com-company-roster-prod:
SKIP:NAMESPACE:com-company-cpfmon:
SKIP:deployment:catalogms:
SKIP:deployment:certman-ingress:
SKIP:deployment:deployment-demo:
#SKIP:deployment:dplcustomergraphms-file:
SKIP:deployment:edsatgms2:
SKIP:deployment:edsatgms3:
SKIP:deployment:edsatgms4:
SKIP:deployment:minio:
SKIP:deployment:cfgmapchecker:
SKIP:deployment:dynatrace-oneagent-operator:
SKIP:deployment:jaeger-collector:
SKIP:deployment:jaeger-query:
SKIP:deployment:sentry-postgresql:
SKIP:deployment:sentry-redis:
SKIP:deployment:sentry-sentry-cron:
SKIP:deployment:sentry-sentry-web:
SKIP:deployment:sentry-sentry-worker:
####### highlighters ###################################
HIGHLIGHT:DEPLOYMENT:loginms:5:
HIGHLIGHT:DEPLOYMENT:repsearchms:5:
HIGHLIGHT:DEPLOYMENT:retailcardauthorizationms:5:
HIGHLIGHT:DEPLOYMENT:directvnoworderms:5:
HIGHLIGHT:DEPLOYMENT:dplcustomergraphms:20:
HIGHLIGHT:DEPLOYMENT:idmloginms:40:
HIGHLIGHT:DEPLOYMENT:idmprofilems:40:
HIGHLIGHT:DEPLOYMENT:configrulems-001:5:
HIGHLIGHT:DEPLOYMENT:edgeprofiledataconsumerms:10:
HIGHLIGHT:DEPLOYMENT:edgeprofilems:5:
HIGHLIGHT:DEPLOYMENT:personalizationconfigtoolms-001:5:
HIGHLIGHT:DEPLOYMENT:recommendationms-001:15:
HIGHLIGHT:DEPLOYMENT:topvaluelocationconfigms-001:5:
HIGHLIGHT:DEPLOYMENT:topvaluelocationms-001:5:
HIGHLIGHT:DEPLOYMENT:wirelessaccountms:5:
HIGHLIGHT:DEPLOYMENT:wirelessorderms:40:
HIGHLIGHT:DEPLOYMENT:accessoryorderms:5:
HIGHLIGHT:DEPLOYMENT:accountservicesorchestrationms:5:
HIGHLIGHT:DEPLOYMENT:agent-app-shell:5:
HIGHLIGHT:DEPLOYMENT:alertms:5:
HIGHLIGHT:DEPLOYMENT:authknowledgems:5:
HIGHLIGHT:DEPLOYMENT:authorizationms-001:20:
HIGHLIGHT:DEPLOYMENT:billms:5:
HIGHLIGHT:DEPLOYMENT:broadbandorderms:5:
HIGHLIGHT:DEPLOYMENT:bundledaccountsms:5:
HIGHLIGHT:DEPLOYMENT:cachetoolsms:5:
HIGHLIGHT:DEPLOYMENT:captchams:5:
HIGHLIGHT:DEPLOYMENT:cartms:30:
HIGHLIGHT:DEPLOYMENT:centurylinkpaymentdatams:5:
HIGHLIGHT:DEPLOYMENT:checkoutms:20:
HIGHLIGHT:DEPLOYMENT:consentms:5:
HIGHLIGHT:DEPLOYMENT:coverage-app-shell:5:
HIGHLIGHT:DEPLOYMENT:crosschannelvisibilityms:20:
HIGHLIGHT:DEPLOYMENT:customeridentification:5:
HIGHLIGHT:DEPLOYMENT:customernotificationms:5:
HIGHLIGHT:DEPLOYMENT:customersnapshotms:20:
HIGHLIGHT:DEPLOYMENT:data-breach-app-shell:5:
HIGHLIGHT:DEPLOYMENT:databreachms:5:
HIGHLIGHT:DEPLOYMENT:deviceinsclaimeligibilityms:5:
HIGHLIGHT:DEPLOYMENT:directv-mktg-app-shell:5:
HIGHLIGHT:DEPLOYMENT:discountsonaccountms:5:
HIGHLIGHT:DEPLOYMENT:dtvnowaccountms:5:
HIGHLIGHT:DEPLOYMENT:dtvnowpaymentms:5:
HIGHLIGHT:DEPLOYMENT:dtvsorderms:5:
HIGHLIGHT:DEPLOYMENT:edsatgms:10:
HIGHLIGHT:DEPLOYMENT:external-traffic-ui-001:5:
HIGHLIGHT:DEPLOYMENT:feavailability:4:
HIGHLIGHT:DEPLOYMENT:feconfiguration:4:
HIGHLIGHT:DEPLOYMENT:femobileswitcher:4:
HIGHLIGHT:DEPLOYMENT:feoffers:4:
HIGHLIGHT:DEPLOYMENT:futurebillestimatorms:5:
HIGHLIGHT:DEPLOYMENT:gatsby-sales-static:5:
HIGHLIGHT:DEPLOYMENT:groupsonwirelessaccountms:5:
HIGHLIGHT:DEPLOYMENT:homedevicesms:5:
HIGHLIGHT:DEPLOYMENT:idmorchestrationms:5:
#HIGHLIGHT:DEPLOYMENT:idp-ssaf-beacon-mapper:1:
#HIGHLIGHT:DEPLOYMENT:logupdatems:1:
#HIGHLIGHT:DEPLOYMENT:idp-app-shell:5:
HIGHLIGHT:DEPLOYMENT:idp-content-orchestration-001:20:
HIGHLIGHT:DEPLOYMENT:idp-ms-cart:5:
HIGHLIGHT:DEPLOYMENT:idp-ms-pricing-and-promotion:5:
HIGHLIGHT:DEPLOYMENT:idp-ms-product-configuration:5:
HIGHLIGHT:DEPLOYMENT:idp-ms-product-listing:5:
HIGHLIGHT:DEPLOYMENT:idp-ms-profile:5:
HIGHLIGHT:DEPLOYMENT:idp-ms-service-availability:5:
HIGHLIGHT:DEPLOYMENT:idp-ssaf-controller-001:1:
HIGHLIGHT:DEPLOYMENT:idp-wll-gateway:2:
HIGHLIGHT:DEPLOYMENT:idse-app-shell:5:
HIGHLIGHT:DEPLOYMENT:idse-sng-app-shell:5:
HIGHLIGHT:DEPLOYMENT:insurancewarranty-app-shell:5:
HIGHLIGHT:DEPLOYMENT:iptvorderms:5:
HIGHLIGHT:DEPLOYMENT:ixp-allocation-manager-service-001:10:
HIGHLIGHT:DEPLOYMENT:ixp-experiment-manager-service-001:5:
HIGHLIGHT:DEPLOYMENT:ixp-experiment-manager-ui:5:
HIGHLIGHT:DEPLOYMENT:kafkarestproxyms:5:
HIGHLIGHT:DEPLOYMENT:lokims:5:
HIGHLIGHT:DEPLOYMENT:lokiui:5:
HIGHLIGHT:DEPLOYMENT:manageservicems:5:
HIGHLIGHT:DEPLOYMENT:masterdescriptionmgmtapi:5:
HIGHLIGHT:DEPLOYMENT:mdsatgms:10:
HIGHLIGHT:DEPLOYMENT:mktg-app-shell:10:
HIGHLIGHT:DEPLOYMENT:mycompany-app-shell:5:
HIGHLIGHT:DEPLOYMENT:offersms:20:
HIGHLIGHT:DEPLOYMENT:omhub-app-shell:5:
HIGHLIGHT:DEPLOYMENT:onemapms:5:
HIGHLIGHT:DEPLOYMENT:orderstatusms:5:
HIGHLIGHT:DEPLOYMENT:outagems:5:
HIGHLIGHT:DEPLOYMENT:outages-app-shell:6:
HIGHLIGHT:DEPLOYMENT:paymentms:10:
HIGHLIGHT:DEPLOYMENT:paymentthirdpartyms:5:
HIGHLIGHT:DEPLOYMENT:photoidauthenticationms:10:
HIGHLIGHT:DEPLOYMENT:portal-app-shell:5:
HIGHLIGHT:DEPLOYMENT:pricingms:5:
HIGHLIGHT:DEPLOYMENT:rcwirelessaccountms:5:
HIGHLIGHT:DEPLOYMENT:referralsms:30:
HIGHLIGHT:DEPLOYMENT:reportingms:50:
HIGHLIGHT:DEPLOYMENT:resolvems:5:
HIGHLIGHT:DEPLOYMENT:retailcareoffersms:5:
HIGHLIGHT:DEPLOYMENT:retaileventsretrieverms:5:
HIGHLIGHT:DEPLOYMENT:riskassessmentms:10:
HIGHLIGHT:DEPLOYMENT:salesproductorchestrationms:20:
HIGHLIGHT:DEPLOYMENT:scheduledappointmentms:5:
HIGHLIGHT:DEPLOYMENT:serviceavailabilityms:15:
HIGHLIGHT:DEPLOYMENT:shoplander-orchestration-001:5:
HIGHLIGHT:DEPLOYMENT:sngcartms:5:
HIGHLIGHT:DEPLOYMENT:sngcatalogms:5:
HIGHLIGHT:DEPLOYMENT:sngcheckoutms:5:
HIGHLIGHT:DEPLOYMENT:sngorchestrationlayer-001:5:
HIGHLIGHT:DEPLOYMENT:sngtaxms:5:
HIGHLIGHT:DEPLOYMENT:sngtermsms:5:
HIGHLIGHT:DEPLOYMENT:sngwirelessms:5:
HIGHLIGHT:DEPLOYMENT:support-app-shell:5:
HIGHLIGHT:DEPLOYMENT:support-service-app-shell:5:
HIGHLIGHT:DEPLOYMENT:trackingauditconsumerms:4:
HIGHLIGHT:DEPLOYMENT:uf-app-shell:10:
HIGHLIGHT:DEPLOYMENT:unifiedaccountms:25:
HIGHLIGHT:DEPLOYMENT:unifiedschedulingms:5:
HIGHLIGHT:DEPLOYMENT:unifiedusagems:5:
HIGHLIGHT:DEPLOYMENT:universalaccountsetupms:10:
HIGHLIGHT:DEPLOYMENT:wireless-productlist-ui:25:
HIGHLIGHT:DEPLOYMENT:wirelessaccountsetupms:20:
HIGHLIGHT:DEPLOYMENT:wirelessagreementsms:5:
HIGHLIGHT:DEPLOYMENT:wirelessdeviceandsimdetailsms:5:
HIGHLIGHT:DEPLOYMENT:wirelessproductrecommendationms:25:
HIGHLIGHT:DEPLOYMENT:wirelessupgradeeligibilityms:15:
HIGHLIGHT:DEPLOYMENT:wirelessupgradems:8:
HIGHLIGHT:DEPLOYMENT:wirelessupgradeoptionsms:20:
HIGHLIGHT:DEPLOYMENT:wirelineaccountms:5:
HIGHLIGHT:DEPLOYMENT:wlsacctmaintenancems:5:
HIGHLIGHT:DEPLOYMENT:wmauditconsumerms:1:
HIGHLIGHT:DEPLOYMENT:certserver:5:
#HIGHLIGHT:DEPLOYMENT:idpnginxplus:4:
HIGHLIGHT:DEPLOYMENT:apporigin-nginx:8:
HIGHLIGHT:DEPLOYMENT:notesms:5:
HIGHLIGHT:DEPLOYMENT:notificationhistoryms-001:5:
HIGHLIGHT:DEPLOYMENT:personalizationmetadatams-001:5:
HIGHLIGHT:DEPLOYMENT:profilecompanyributemapms-001:5:
HIGHLIGHT:DEPLOYMENT:qrcodegenerator:5:
HIGHLIGHT:DEPLOYMENT:qrcodeviewer:1:
HIGHLIGHT:DEPLOYMENT:retailcaredeliveryoptionsms:5:
HIGHLIGHT:DEPLOYMENT:wirelessusagems:5:
HIGHLIGHT:DEPLOYMENT:accountnotificationsms:5:
HIGHLIGHT:DEPLOYMENT:authdevicesupportms:5:
HIGHLIGHT:DEPLOYMENT:closurepromotionms:5:
HIGHLIGHT:DEPLOYMENT:deliverymatrixms-001:5:
HIGHLIGHT:DEPLOYMENT:devicerecommenderms:5:
HIGHLIGHT:DEPLOYMENT:inquireorderms:5:
HIGHLIGHT:DEPLOYMENT:wirelessinstallmentplanms:5:
HIGHLIGHT:DEPLOYMENT:unifiedcustomerservice:5:
HIGHLIGHT:DEPLOYMENT:manageadjustmentms:5:
HIGHLIGHT:DEPLOYMENT:products-and-services-ui:25:
######### POP element on top of result #################
POP:OPUS:loginms:
POP:OPUS:repsearchms:
POP:OPUS:retailcardauthorizationms:
POP:OPUS:agent-app-shell:
POP:OPUS:authorizationms:
POP:OPUS:centurylinkpaymentdatams:
POP:OPUS:consentms:
POP:OPUS:customeridentification:
POP:OPUS:customersnapshotms:
POP:OPUS:discountsonaccountms:
POP:OPUS:groupsonwirelessaccountms:
POP:OPUS:lokims:
POP:OPUS:lokiui:
POP:OPUS:photoidauthenticationms:
POP:OPUS:rcwirelessaccountms:
POP:OPUS:retailcareoffersms:
POP:OPUS:retaileventsretrieverms:
POP:OPUS:wirelessaccountsetupms:
POP:OPUS:wirelessagreementsms:
POP:OPUS:wirelessdeviceandsimdetailsms:
POP:OPUS:wirelessupgradeeligibilityms:
POP:OPUS:wirelessupgradems:
POP:OPUS:wlsacctmaintenancems:
POP:OPUS:wirelessinstallmentplanms:
POP:OPUS:unifiedcustomerservice:
#POP:RBTEST:riskassessmentms:
#POP:DUMMY:trackingauditconsumerms:
########################################################
