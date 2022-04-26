#!/bin/sh
#=====================================================================
# This script is querying the Last Backup Date of Servers configured in OS(Filesystem) and VM Backups
#=====================================================================
#                        REVISIONS
#=====================================================================
# Updated By - Kaijer	| Date -  Feb 8, 2020  | Comments - moved script to aexvptsm01 and modified ssh, date-time
# Updated By - Arnab	| Date -  Jan 4, 2021  | Comments - script optimized, cleaned up
# Updated By - Arnab 	| Date -  Feb 10, 2021 | Comments - script modified to report on active policies
# Updated By - Arnab 	| Date -  Apr 14, 2021 | Comments - script modified to reflect master server details against clients
# Updated By - Arnab 	| Date -  Apr 16, 2021 | Comments - script now captures implicit execution time
#=====================================================================

start_time=$(date +%s)
DATE=`date +%m.%d.%Y-%H:%M:%S`


input=/backup_packages/nbuinput.out
output1=/backup_packages/output1.out
output2=/backup_packages/output2.out
output3=/backup_packages/output3.out
output4=/backup_packages/output4.out
output5=/backup_packages/output5.out
output6=/backup_packages/output6.out
LOG1=/backup_packages/log1_output.out
LOG2=/backup_packages/log2_output.out

TITLE="VM and OS Last Backup Date"
WHOTOSEND="unixops@sce.com backupsupport@sce.com aicc@sce.com"

rm -rf /backup_packages/output1.out
rm -rf /backup_packages/output2.out
rm -rf /backup_packages/output3.out
rm -rf /backup_packages/output4.out
rm -rf /backup_packages/output5.out
rm -rf /backup_packages/output6.out
rm -rf /backup_packages/log1_output.out
rm -rf /backup_packages/log2_output.out
echo "====================== ====================== ====================== ====================== ======================" >> $LOG1
echo "  Server Client_Name Policy_Name Incr_Backup_Date Full_Backup_Date " >> $LOG1
echo "====================== ====================== ====================== ====================== ======================" >> $LOG1

for server in `cat $input`;do
	ssh $server /usr/openv/netbackup/bin/admincmd/bppllist | egrep -i "win|std" | egrep -i "MC|NC" | egrep -v -i "decomm|test|temp|adhoc|special|onetime|domino|sapdump|sybase|datastage|db2dump|oracle|clus|spl-std" > $output1

	if [ -s $output1 ];then
		for policy in `cat $output1`;do
			if [ `ssh $server /usr/openv/netbackup/bin/admincmd/bppllist $policy -U | grep "Active" | awk '{print $2}'` = "yes" ];then
				ssh $server /usr/openv/netbackup/bin/admincmd/bppllist $policy | grep -i Client | awk '{print $2}' > $output2

				for client in `cat $output2`;do
					os_backup_incr=`ssh $server /usr/openv/netbackup/bin/admincmd/bpimagelist -d 01/01/1970 -policy $policy -client $client -U | grep -i Diff | awk 'NR==1 {print $1}'`
					os_backup_full=`ssh $server /usr/openv/netbackup/bin/admincmd/bpimagelist -d 01/01/1970 -policy $policy -client $client -U | grep -i Full | awk 'NR==1 {print $1}'`

					echo " $server $client $policy $os_backup_incr $os_backup_full " >> $LOG1
				done
			fi
		done
	fi

	ssh $server /usr/openv/netbackup/bin/admincmd/bppllist | egrep -i "vmware" | egrep -v -i "decomm|test|manual|aywvpvmc05" | egrep -v -i vip > $output3
	
	if [ -s  $output3 ];then
		for policy in `cat $output3`;do
			if [ `ssh $server /usr/openv/netbackup/bin/admincmd/bppllist $policy -U | grep "Active" | awk '{print $2}'` = "yes" ];then
				ssh $server /usr/openv/netbackup/bin/admincmd/bppllist $policy | grep -i Client | awk '{print $2}' >  $output4

				for client in `cat $output4`;do
					os_backup_incr=`ssh $server /usr/openv/netbackup/bin/admincmd/bpimagelist -d 01/01/1970 -client $client -U | grep -i Diff | grep -i vm | awk 'NR==1 {print $1}'`
					os_backup_full=`ssh $server /usr/openv/netbackup/bin/admincmd/bpimagelist -d 01/01/1970 -client $client -U | grep -i Full | grep -i vm | awk 'NR==1 {print $1}'`

					echo " $server $client $policy $os_backup_incr $os_backup_full " >> $LOG1
				done
			fi
		done
	fi

    ssh $server /usr/openv/netbackup/bin/admincmd/bppllist | egrep -i "vmware" | egrep -v -i "decomm|test|manual|aywvpvmc05" | egrep -i vip > $output5

	if [ -s  $output5 ];then
		for policy in `cat $output5`;do
			if [ `ssh $server /usr/openv/netbackup/bin/admincmd/bppllist $policy -U | grep "Active" | awk '{print $2}'` = "yes" ];then
				ssh $server /usr/openv/netbackup/bin/nbdiscover -noxmloutput -policy $policy -includedonly >  $output6
	
				for client in `cat $output6`;do
					os_backup_incr=`ssh $server "/usr/openv/netbackup/bin/admincmd/bpimagelist -d 01/01/1970 -client '$client'  -U" | grep -i Diff | grep -i vm |awk 'NR==1 {print $1}'`
					os_backup_full=`ssh $server "/usr/openv/netbackup/bin/admincmd/bpimagelist -d 01/01/1970 -client '$client'  -U" | grep -i Full | grep -i vm |awk 'NR==1  {print $1}'`
	
					echo " $server $client $policy $os_backup_incr $os_backup_full " >> $LOG1
				done
			fi
		done
    fi
done

total_server=`cat $LOG1 |wc -l`

##Report##

echo "$TITLE" > $LOG2
echo "Date: $DATE " >> $LOG2
echo "Total_Number_of_Servers:$total_server" >> $LOG2

cat $LOG1 | column -t >> $LOG2


duration_time=$(echo "$(date +%s) - $start_time" | bc)
duration=$(date -d@$duration -u +%H:%M:%S)

echo "Script Execution Time: $duration" >> $LOG2
echo "Script_Location `hostname`:$0"  >> $LOG2
echo "Created by ©Arnab Roy"  >> $LOG2

cat $LOG2 | mailx -s "$TITLE - $DATE" $WHOTOSEND
cp  $LOG1 /backup_packages/it11/software/log1_output.out
