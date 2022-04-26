#!/bin/sh
#=======================================================
#This script is installing NetBackup 8.2 on RHEL Clients
# Last updated by Arnab arnab.roy@sce.com
# Updated on October 27 , 2020
for i in `cat tmp_os_arnab`;do

        echo ==================================================================
        echo Server: $i
        echo ==================================================================
        echo "Saving Config Files..."
        #sudo ssh -oBatchMode=yes $i cp /usr/openv/netbackup/bp.conf /tmp/bp.conf_bkp; FLAG=$?;
        sudo ssh -oBatchMode=yes $i cp /usr/openv/netbackup/exclude_list /tmp/exclude_list.bkp

        echo "Server Entry is: "
        echo ==================================================================
        sudo ssh -oBatchMode=yes $i cat /tmp/bp.conf_bkp
        echo ==================================================================

        echo "Uninstalling NetBackup 8.0..."
        sudo ssh -oBatchMode=yes $i /usr/openv/netbackup/bin/nblu_registration -r
        sudo ssh -oBatchMode=yes $i /usr/openv/netbackup/bin/vxlogcfg -r -p 51216
        sudo ssh -oBatchMode=yes $i /usr/openv/netbackup/bin/admincmd/nbftsrv_config -d

        #echo Fixing rpm issue for server: $i...
        #echo ========================================================
        #sudo ssh $i mkdir /var/lib/rpm/backup
        #sudo ssh $i cp -a /var/lib/rpm/__db* /var/lib/rpm/backup/
        #sudo ssh $i rm -f /var/lib/rpm/__db.[0-9][0-9]*
        #sudo ssh $i rpm --quiet -qa
        #sudo ssh $i rpm --rebuilddb
        #sudo ssh $i yum clean all


        sudo ssh -oBatchMode=yes $i rpm -e VRTSnbcfg
        sudo ssh -oBatchMode=yes $i cat /usr/openv/netbackup/bp.conf.rpmsave
        sudo ssh -oBatchMode=yes $i /opt/pdde/pddeuninstall.sh -forceclean
        sudo ssh -oBatchMode=yes $i /opt/pdde/pddeuninstall.sh -basedir /usr/openv/pdde/ -ostdir /usr/openv/lib/ost-plugins/ -forceclean
        sudo ssh -oBatchMode=yes $i rpm -e VRTSnetbp
        sudo ssh -oBatchMode=yes $i rpm -e VRTSnbjava
        sudo ssh -oBatchMode=yes $i rpm -e VRTSnbjre
        sudo ssh -oBatchMode=yes $i rpm -e VRTSnbclt
        sudo ssh -oBatchMode=yes $i rpm -e VRTSpbx
        sudo ssh -oBatchMode=yes $i rpm -e VRTSnbpck

        for j in `sudo ssh $i /usr/openv/netbackup/bin/bpps | awk '{print $2}'`;do sudo ssh $i "kill -9 $j"; done;

        sudo ssh -oBatchMode=yes $i ls -lrt /usr/openv/
        echo "Deleting Files in /usr/openv..."
        sudo ssh -oBatchMode=yes $i 'rm -rf /usr/openv/* /tmp/updating_client'
        sudo ssh -oBatchMode=yes $i ls -lrt /usr/openv/
        echo "Starting Installation of NetBackup 8.2..."
        echo "Transferring NetBackup Package to server..."
        scp -rp /backup_packages/VERTIAS_NETBACKUP_PKG/NetBackup_8.2_CLIENTS2_RedHat2.6.32.tar.gz root@$i:/usr/openv/
        sudo ssh -oBatchMode=yes $i tar -xvf /usr/openv/NetBackup_8.2_CLIENTS2_RedHat2.6.32.tar.gz -C /usr/openv/
        echo "Pushing answer file for silent install..."
        #scp -rp nbanswer_input root@$i:/usr/openv/
        scp -rp NBInstallAnswer.conf root@$i:/tmp/NBInstallAnswer.conf
        #sudo ssh -oBatchMode=yes $i '/usr/openv/NetBackup_8.2_CLIENTS2_RedHat2.6.32/install < /usr/openv/nbanswer_input'

        sudo ssh -oBatchMode=yes $i /usr/openv/NetBackup_8.2_CLIENTS2_RedHat2.6.32/NBClients/anb/Clients/usr/openv/netbackup/client/Linux/RedHat2.6.32/client_config

        INSTALL_STATUS=$?

        echo "Cleaning Up..."
        sudo ssh -oBatchMode=yes $i 'rm -rf /usr/openv/NetBackup_8.2_CLIENTS2_RedHat2.6.32.tar.gz /usr/openv/NetBackup_8.2_CLIENTS2_RedHat2.6.32'
        echo "Restore Config Settings..."

                #if [ $FLAG -eq 0 ]; then
                        #sudo ssh -oBatchMode=yes $i cat /tmp/bp.conf_bkp | sudo ssh -oBatchMode=yes $i "cat > /usr/openv/netbackup/bp.conf"
                #else
                        today=$(date +"%Y-%m-%d")
                        sudo ssh -oBatchMode=yes  $i cp /usr/openv/netbackup/bp.conf /usr/openv/netbackup/bp.conf_backup.$today
                        sudo ssh -oBatchMode=yes  $i cat /usr/openv/netbackup/bp.conf |grep -v 'SERVER =' > secondPart.txt
                        sudo ssh -oBatchMode=yes  $i echo  ">/usr/openv/netbackup/bp.conf"
                        cat iocEntries.txt | sudo ssh -oBatchMode=yes  $i -T "cat >> /usr/openv/netbackup/bp.conf"
                        cat secondPart.txt | sudo ssh -oBatchMode=yes  $i -T "cat >> /usr/openv/netbackup/bp.conf"


                        echo ===========================================================================
                        echo CLIENT: $i
                                    sudo ssh -oBatchMode=yes  $i "sed -i '/^$/d' /usr/openv/netbackup/bp.conf"

                        echo ===========================================================================
                #fi




        sudo ssh -oBatchMode=yes $i cat /tmp/exclude_list.bkp | sudo ssh -oBatchMode=yes $i "cat > /usr/openv/netbackup/exclude_list"
        echo "Server: [ $i ] Entry is: "
        echo ==================================================================
        sudo ssh -oBatchMode=yes $i cat /usr/openv/netbackup/bp.conf
        echo ==================================================================
        echo "Registering Server with Master Server..."
        echo ==================================================================
        sudo ssh -oBatchMode=yes $i /usr/openv/netbackup/bin/nbcertcmd -getcertificate -force
        REGISTRATION_STATUS=$?
        if [ "$REGISTRATION_STATUS" -ne 0 ]
        then
                sudo ssh -oBatchMode=yes $i /usr/openv/netbackup/bin/nbcertcmd -getcertificate -force -host $i
                REGISTRATION_STATUS=$?
                if [ "$REGISTRATION_STATUS" -ne 0 ]
                then
                        sudo ssh -oBatchMode=yes $i /usr/openv/netbackup/bin/nbcertcmd -getcertificate -force -host $i.sce.com
                        REGISTRATION_STATUS=$?
                        if [ "$REGISTRATION_STATUS" -ne 0 ]
                        then
                                sudo ssh -oBatchMode=yes $i "/usr/openv/netbackup/bin/nbcertcmd -getcertificate -token TLIUHOKGZDZGCQLQ -force"
                                REGISTRATION_STATUS=$?
                        fi
                fi
        fi
        echo ==================================================================

        echo "$i $INSTALL_STATUS $REGISTRATION_STATUS" >> CLIENT_STATUS_RHEL.txt
        echo "========================================================================================="

done
