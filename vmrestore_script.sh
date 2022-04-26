#!/bin/sh
#=====================================================================
# This script is used to initiate VM Restores of Servers using CLI Interface
#=====================================================================

ser_name=""
bkp_date=""
master_serv=""
#nbdiscover -noxmloutput "vmware:/?filter=Displayname Contains 'aywcplpi01'"


check_servername () {
	echo "Enter Server Name to Restore: "
	read ser_name
	if [ ! -z $ser_name ]; then
		str1=$(sudo ssh $master_serv "/usr/openv/netbackup/bin/nbdiscover -noxmloutput \"vmsearch:/;reqType=search?filter=VMDisplayName Equal '$ser_name' OR VMHostName Equal '$ser_name' OR IPAddress Equal '`sudo ssh $master_serv nslookup $ser_name | awk 'NR==5{print $2}'`'\"" | awk -F'"' '{print $2}')
		echo "Server Name Entered: $str1"
		if [ ! -z $str1 ]; then
			ser_name=$str1
		else
			echo "Server $ser_name not configured in VM Backup. Exiting..."
			exit 1
		fi
	else
		echo "No input given!"
		check_servername
	fi
}
		
check_backup () {
	echo "Enter the backup date in mm/dd/yyyy format from which to restore: " 
	read bkp_date
	case $bkp_date in
        [0-9][0-9][/][0-9][0-9][/][0-9][0-9][0-9][0-9])
			echo "Checking if backup is available for $bkp_date. "
			
			str2=$(sudo ssh $master_serv /usr/openv/netbackup/bin/admincmd/bpimagelist -d $bkp_date -e $bkp_date -l -client $ser_name | awk 'NR==1{print $7}' | grep -i vmware | wc -l)
			
			str3=$(sudo ssh $master_serv /usr/openv/netbackup/bin/admincmd/bpimagelist -d $bkp_date -e $bkp_date -l -client $ser_name | awk 'NR==1{print $6}')
			
			
			if [ $str2 -eq 1 ]; then
				echo "Backup Image Found!! Restoring from backup image: $str3 "
			else
				echo "No Backup Image Found! Exiting..."
				echo "Would you like to enter a different date? [y/n] "
				read user_input
				case $user_input in
					[yY][eE][sS]|[yY])
						check_backup
						;;
					[nN][oO]|[nN])
						echo "Exiting..."
						exit 1
						;;
					*)
						echo "Invalid input. Exiting...."
						exit 1
						;;
				esac
			fi	
			;;

		*)
			echo "Invalid date format. Please re-enter."
			check_backup
			;;
	esac
}		

check_restoretype () {		
	echo "Do you want to restore to original location or alternate location? [Input [o] for original, [a] for alternate] "
	read type
	case $type in
        [o])
			echo "Initiating Original Restore"
			
			echo "sudo ssh $master_serv /usr/openv/netbackup/bin/nbrestorevm -vmw -C $ser_name -s $bkp_date -e $bkp_date"
			echo "Restore started "
			;;
        [a])
			echo "Initiating Alternate Restore"
			
			NOW="renamefile-$(date +"%m-%d-%y-%H.%M.%S").txt"
			RENAMEFILE=/tmp/renamefiles/$NOW
			sudo ssh $master_serv touch $RENAMEFILE
			sudo ssh $master_serv chmod 777 $RENAMEFILE
			
			
			
			
			echo "Would you like to rename VM (y/n)? " 
			read CONT1
			if [ "$CONT1" = "y" ]; then
				echo "Enter new VM Name: "
				read NEW_VM_NAME
				sudo ssh $master_serv echo "change vmname to $NEW_VM_NAME >> $RENAMEFILE "
			else
				echo "Skipping";
			fi
			
			echo "Would you like to restore to new ESX Host (y/n)? " 
			read CONT2
			if [ "$CONT2" = "y" ]; then
				echo "Enter new ESX Host name: "
				read NEW_ESX_HOST
				sudo ssh $master_serv echo "change esxhost to $NEW_ESX_HOST >> $RENAMEFILE "
			else
				echo "Skipping...";
			fi

			echo "Would you like to restore to new Datacenter (y/n)? " 
			read CONT3
			if [ "$CONT3" = "y" ]; then
				echo "Enter new Datacenter name: "
				read NEW_DATACENTER
				sudo ssh $master_serv echo "change datacenter to $NEW_DATACENTER >> $RENAMEFILE "
			else
				echo "Skipping...";
			fi
			
			echo "Would you like to restore to new Folder (y/n)? " 
			read CONT4
			if [ "$CONT4" = "y" ]; then
				echo "Enter new Folder name: "
				read NEW_FOLDER
				sudo ssh $master_serv echo "change folder to $NEW_FOLDER >> $RENAMEFILE "
			else
				echo "Skipping...";
			fi
			
			echo "Would you like to restore to new Resource Pool (y/n)? " 
			read CONT5
			if [ "$CONT5" = "y" ]; then
				echo "Enter new Resource Pool name: "
				read NEW_RESOURCEPOOL
				sudo ssh $master_serv echo "change resourcepool to $NEW_RESOURCEPOOL >> $RENAMEFILE"
			else
				echo "Skipping...";
			fi
			
			echo "Would you like to restore to new Datastore (y/n)? " 
			read CONT6
			if [ "$CONT6" = "y" ]; then
				echo "Enter new Datastore name: "
				read NEW_DATASTORE
				sudo ssh $master_serv echo "change datastore to $NEW_DATASTORE >> $RENAMEFILE"
			else
				echo "Skipping...";
			fi
			
			echo "Changes will be as follows: "
			sudo ssh $master_serv "cat $RENAMEFILE"
			
			echo "sudo ssh $master_serv /usr/openv/netbackup/bin/nbrestorevm -vmw -C $ser_name -R $RENAMEFILE -s $bkp_date -e $bkp_date"
			echo "Restore started"
			
			;;
        *)
			echo "Invalid input. Please re-enter: "
			check_restoretype
                
			;;
	esac		
}
		



while true; do
        echo "Proceed with Full Server Restore (VM Restore) [y/n] "
		read input

		case $input in
        [yY][eE][sS]|[yY])
				echo "Enter name of the datacenter where server is located [adc/ioc]: "
				read master
				if [ "$master" = "adc" ]; then
					master_serv="ayxvpnbu01.sce.com"
				elif [ "$master" = "ioc" ]; then
					master_serv="iyxvpnbu01.sce.com"
				else
					echo "Exiting...";
					exit 1
				fi			
				
				check_servername
				check_backup
				check_restoretype
				break
                ;;
        [nN][oO]|[nN])
                echo "Exiting..."
                break
                ;;
        *)
                echo "Invalid input. Please re-enter"
                ;;
esac
done
