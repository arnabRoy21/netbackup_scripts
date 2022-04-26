#!/bin/sh
#====================================================================
#This script is querying the Replication Status
#Last updated by Arnab arnab.roy@sce.com
#Updated on April 12 , 2021
#====================================================================

input=/backup_packages/nbuinput.out
> SLP.output
> SLP_backlog.output
> /tmp/header.tmp
> /tmp/repl_data.tmp
> SLP_Final.output
> SLP_PreFinal.output

echo "MASTER_SERVER SLP_NAME TYPE STATE SOURCE_VOLUME OLDEST_PENDING_IMAGE_DATE TIME" >> /tmp/header.tmp
echo "============= ============= ============= ============= ============= ============= =============" >> /tmp/header.tmp
echo "APPLIANCE BACK_LOG(TB)" >> SLP_backlog.output

for server in `cat $input`;do

	nbstlutil_out=/backup_packages/VERTIAS_NETBACKUP_PKG/nbstlutil_reports/SLP.backlogReport.$(date +%s).$server.txt
	echo "`sudo ssh $server /usr/openv/netbackup/bin/admincmd/nbstlutil report`" > $nbstlutil_out 2>&1

	for j in `sudo ssh $server  /usr/openv/netbackup/bin/admincmd/nbstl -L | egrep "Name" | grep -v "Window Name" | sed -e 's/^[ \t]*//' | sed -e 's/Name: //g'`;do

		STATE=$(sudo ssh $server /usr/openv/netbackup/bin/admincmd/nbstl $j -L | grep "State" | uniq | sed -e 's/^[ \t]*//' | sed -e 's/State: //g')
	
		if [ `sudo ssh $server /usr/openv/netbackup/bin/admincmd/nbstl $j -L | grep import > /dev/null 2>&1; echo $?` -eq 0 ]; then TYPE="IMPORT"; else TYPE="REPLICATION"; fi
	
		SOURCE_VOLUME=$(sudo ssh $server /usr/openv/netbackup/bin/admincmd/nbstl $j -L | grep "Source Volume" | sed -e 's/^[ \t]*//' | sed -e 's/Source Volume(Server:Type:Volume): "//g' | sed -e 's/:PureDisk:PureDiskVolume"//g' | sort -u)
	
		if [ -z $SOURCE_VOLUME ]; then
		SOURCE_VOLUME="NA"
		fi
	
		BACKUPID=$(sudo ssh $server /usr/openv/netbackup/bin/admincmd/nbstlutil stlilist -image_incomplete -lifecycle $j | more | awk 'NR==1 {print $3}')
	
		REPL_DATE=$(sudo ssh $server /usr/openv/netbackup/bin/admincmd/bpimagelist -backupid $BACKUPID -U | awk 'NR==3{print $1 " " $2}')
	
		if [ -z "$REPL_DATE" ]; then
			REPL_DATE="NA"
		fi
	
		echo "$server $j $TYPE $STATE $SOURCE_VOLUME $REPL_DATE" >> /tmp/repl_data.tmp
    done

	for media_serv in `cat /tmp/repl_data.tmp | sort -u -k5,5 | awk '{print $5}' | grep -v NA | sed 's/.sce.com//g'`;do
		BACK_LOG=`cat $nbstlutil_out | grep -v "_grp_" | grep -v NBU-MC | grep -v test_upgrade | sed 's/ypapnbu/yoapnbu/g' | grep $media_serv | grep -v "<1" | awk '{SUM+=$4}END{print SUM}'`

		if [ -n "$BACK_LOG"  ];then
			CONVERSION_RATE=1048576
			BACKLOG_DATA_TB=`echo "scale=2; $BACK_LOG/$CONVERSION_RATE" | bc -l`
			echo "$media_serv $BACKLOG_DATA_TB" >> SLP_backlog.output
		fi
		BACK_LOG=0
    done
    cat /tmp/repl_data.tmp >> SLP.output
    > /tmp/repl_data.tmp
done
cat /tmp/header.tmp >> SLP_PreFinal.output
cat SLP.output >> SLP_PreFinal.output
cat SLP_PreFinal.output | column -t >> SLP_Final.output
echo "====================================== BACK_LOG REPORT ======================================" >> SLP_Final.output
cat SLP_backlog.output | column -t >> SLP_Final.output
echo "" >> SLP_Final.output
echo "Created by ©Arnab Roy" >> SLP_Final.output
cat SLP_Final.output | mailx -s "======SLP REPORT======" backupsupport@sce.com
