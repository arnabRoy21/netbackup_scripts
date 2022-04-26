#!/bin/bash

echo "==== BACKUP SCRIPT STARTED on `date` ==== stdout"
echo "==== BACKUP SCRIPT STARTED on `date` ==== stderr" 1>&2

#ORACLE PARAMETER SECTION
#======================================================
ORACLE_SID=p8112dg
ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/dbhome_1
RMAN_EXECUTABLE=$ORACLE_HOME/bin/rman
PATH=$ORACLE_HOME/bin:$PATH
#======================================================


#if [ "$NB_ORA_FULL" = "1" ]; then
#    BACKUP_TYPE="INCREMENTAL LEVEL=0"
#
#elif [ "$NB_ORA_INCR" = "1" ]; then
#    BACKUP_TYPE="INCREMENTAL LEVEL=1"
#
#fi
#
#
#if [ "$NB_ORA_FULL" = "1" ] || [ "$NB_ORA_INCR" = "1" ]; then

	WEEK_NUMBER=$((($(date +%-d)-1)/7+1))
	DAY="$(date +%A)"
	
	
	if [ "$DAY" == "Saturday" ]; then
	
		RMAN_LOG_FILE=FULL_`date "+%m-%d-%Y"`.out
		BACKUP_TYPE="INCREMENTAL LEVEL=0"
	
		if [ "$WEEK_NUMBER" -le 3 ]; then
			BACKUP_SCHEDULE="Full_Backup_02_Child_Stream"
	
		else
			BACKUP_SCHEDULE="Full_Backup_03_Child_Stream"
	
		fi
	
	else
	
		RMAN_LOG_FILE=INCR_`date "+%m-%d-%Y"`.out
		BACKUP_TYPE="INCREMENTAL LEVEL=1"
	
		if [ "$WEEK_NUMBER" -le 3 ]; then
			BACKUP_SCHEDULE="Incr_Backup_02_Child_Stream"
	
		else
			BACKUP_SCHEDULE="Incr_Backup_03_Child_Stream"
	
		fi
	
	fi
	
	LOG_FILE=/u01/p811/admin/scripts/NetBackup_Script_Logs/$RMAN_LOG_FILE

#else

#CUSTOMIZABLE VARIABLE SECTION FOR MANUAL BACKUP
#----------------------------------------------------------------------------------
#BACKUP_TYPE                    VALUES
#----------------------------------------------------------------------------------
#For LEVEL 0 RMAN BACKUP        INCREMENTAL LEVEL=0
#For LEVEL 1 RMAN BACKUP        INCREMENTAL LEVEL=1
#----------------------------------------------------------------------------------
#BACKUP_SCHEDULE                TARGET                  VALUES
#----------------------------------------------------------------------------------
#For FULL BACKUP                ayoapnbu02.sce.com      Full_Backup_02_Child_Stream
#For FULL BACKUP                ayoapnbu03.sce.com      Full_Backup_03_Child_Stream
#For INCR BACKUP                ayoapnbu02.sce.com      Incr_Backup_02_Child_Stream
#For INCR BACKUP                ayoapnbu03.sce.com      Incr_Backup_03_Child_Stream
#----------------------------------------------------------------------------------

#UNCOMMENT BELOW PARAMETERS TO TAKE EFFECT
#====================================================
#	BACKUP_TYPE="INCREMENTAL LEVEL=1"
#  	BACKUP_SCHEDULE="Incr_Backup_02_Child_Stream"
#====================================================

#OPTIONAL PARAMETER
#=======================================================================================
#	LOG_FILE=/u01/p811/admin/scripts/NetBackup_Script_Logs/MANUAL_`date "+%m-%d-%Y"`.out
#=======================================================================================
#fi

#Check for unbound log growth. 
#Delete logs older than 30days
find /u01/p811/admin/scripts/NetBackup_Script_Logs/ -type d -mtime +30 -exec rm -rf {} \;

echo >> $LOG_FILE
chmod 644 $LOG_FILE

out=/tmp/`basename $0`.stdout.$$
trap "rm -f $out" EXIT SIGHUP SIGINT SIGQUIT SIGTRAP SIGKILL SIGUSR1 SIGUSR2 SIGPIPE SIGTERM SIGSTOP
mkfifo "$out"
tee -a $LOG_FILE < "$out" &
exec 1>&- 2>&-
exec 1>"$out" 2>&1


echo "==== $0 started on `date` ===="
echo "==== $0 $*"
echo

BACKUP_CUSER=`id |cut -d"(" -f2 | cut -d ")" -f1`

echo "Script is being run by user: $BACKUP_CUSER"
echo "Backup is running with schedule: $BACKUP_SCHEDULE"
echo

CMDS="
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
export PATH=$PATH

echo ----- SUBSHELL ENV VARIABLES -----
echo
env | sort | egrep '^ORACLE_|^NB_ORA_|^RMAN_|^BACKUP_|^TNS_'
echo

$RMAN_EXECUTABLE target / <<!
run
{
allocate channel t1 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t2 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t3 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t4 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t5 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t6 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t7 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t8 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t9 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t10 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t11 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t12 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t13 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t14 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t15 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t16 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t17 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t18 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t19 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t20 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t21 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t22 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t23 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
allocate channel t24 type 'SBT_TAPE' PARMS 'SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64,ENV=(NB_ORA_SERV=ayxvpnbu01.sce.com,NB_ORA_CLIENT=axyp02dbadm02-1120.sce.com,NB_ORA_POLICY=adc-MC-prod-exadata-mdms-scr-db-02,NB_ORA_SCHED=$BACKUP_SCHEDULE,NB_ORA_SID=p8112dg)';
BACKUP $BACKUP_TYPE FORMAT 'bk_d%d_u%u_s%s_p%p_t%t' FILESPERSET 64 DATABASE;
backup archivelog all not backed up 2 times FORMAT 'arch_d%d_u%u_s%s_p%p_t%t' FILESPERSET 4;
backup FORMAT 'ctrl_d%d_u%u_s%s_p%p_t%t' current controlfile;
backup spfile;
release channel t1;
release channel t2;
release channel t3;
release channel t4;
release channel t5;
release channel t6;
release channel t7;
release channel t8;
release channel t9;
release channel t10;
release channel t11;
release channel t12;
release channel t13;
release channel t14;
release channel t15;
release channel t16;
release channel t17;
release channel t18;
release channel t19;
release channel t20;
release channel t21;
release channel t22;
release channel t23;
release channel t24;
}
exit
!
"

echo "Running RMAN Backup as oracle user"

/bin/su -c "$CMDS" - oracle

RESULT=$?
echo

# ---------------------------------------------------------------------------
# Log the completion of this script to both stdout/obk_stdout
# and stderr/obk_stderr.
# ---------------------------------------------------------------------------

if [ "$RESULT" = "0" ]; then
    
	echo "|===========================|"
    echo "|  Script ran successfully  |"
	echo "|===========================|"
else
	echo "|===========================|"
    echo "|  Script execution failed  |"
	echo "|===========================|"
fi

echo
echo "==== $0 $LOGMSG on `date` ==== stdout"
echo "==== $0 $LOGMSG on `date` ==== stderr" 1>&2


