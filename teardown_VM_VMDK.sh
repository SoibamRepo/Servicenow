#set -x
#!bin/bash

###################################################################
#Script Name	: Retain the VMDK disk file from the Virtual Machine after the VM deletion.                                                                                
#Description	: This script uses WMware VCenter APIs to to perform the desired tasks.                                                                          
#Args           : No arguments (variables are defind globally in the script)                                                                                          
#Author       	: Nagaraj Gandge                          
#Email         	: nagaraj.gandge@hpe.com
###################################################################

#variables defination Section 
# This script needs the Variables like Vcenrer Username and Password to execute this shell script.
vcenter_IP="192.168.101.99"
vcenter_username="administrator@vsphere.local"
vcenter_password="Password@123"

#Fetch the VM Name from the VCenter
vm_name=`hostname`
echo "VM Name is : "$vm_name
echo "Retaining the Virtual disk for : " $vm_name

# Generate the VCenter API Session Token to peform the required tasks
Auth=$(curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -u "$vcenter_username:$vcenter_password" -k "https://$vcenter_IP/rest/com/vmware/cis/session")
token=$(echo $Auth | awk -F'[=:]' '{print $2}' | sed 's/\}//g'| sed 's/.*"\(.*\)"[^"]*$/\1/')

#Print the generated token
echo "VCenter API session Token is" : $token

# List All the Available VMs in the VCenter.
VMs=$(curl -sik -H 'Content-Type: application/json' -H 'Accept: application/json' -H "vmware-api-session-id: $token" -X GET "https://$vcenter_IP/rest/vcenter/vm")

#fetch the VMID using the VMName from the list of VMs.
vmid=$(echo $VMs | sed 's/},/\n/g' | awk -F '"vm":' '{print $2}' | grep $vm_name | awk -F, '{print $1}'| sed 's/.*"\(.*\)"[^"]*$/\1/')
echo "VMID pertainig to the VM Name `hostname` is: " $vmid

#Get the VMs Disk information.
disks=$(curl -sk -H 'Content-Type: application/json' -H 'Accept: application/json' -H "vmware-api-session-id: $token" -X GET "https://192.168.101.99/rest/vcenter/vm/$vmid/hardware/disk")
echo $disks

#Fetch the VMDK disk ids using Disk information.
id1=$(echo $disks | sed 's/{value://g' | head -c -3 | tail -c +2 )
id2=$(echo $id1 | awk -F ',' '{ print NF }')
for i in `seq 1 $id2`
    do
        #echo $i
        disk_ids=$(echo $id1 | awk -F ',' "{print \$$i}")
        #echo $id4
        id3=$(echo $disk_ids | sed 's/{disk://g' | head -c -2 |awk -F "disk" '{print $2}')
#       id4=$(echo $id3 |awk -F "disk" '{print $2}')
        diskid_val=$(echo $id3 |awk -F: '{print $2}'| sed 's/.*"\(.*\)"[^"]*$/\1/')
        echo $diskid_val
        diskinfo=$(curl -sk -H 'Content-Type: application/json' -H 'Accept: application/json' -H "vmware-api-session-id: $token" -X GET "https://$vcenter_IP/rest/vcenter/vm/$vmid/hardware/disk/$diskid_val")
        echo $diskinfo
 
#		Disassociate the Disk attached to the Virtual Machine.
        diskdelete=$(curl -sk -H 'Content-Type: application/json' -H 'Accept: application/json' -H "vmware-api-session-id: $token" -X DELETE "https://$vcenter_IP/rest/vcenter/vm/$vmid/hardware/disk/$diskid_val")
        echo $diskdelete
		echo "Disk is disassociated from the $vm_name Virtual Machine Successfully..!"
    done

#disk information
#$diskinfo=$(curl -sk -H 'Content-Type: application/json' -H 'Accept: application/json' -H "vmware-api-session-id: $token" -X GET "https://$vcenter_IP/rest/vcenter/vm/$vmid/hardware/disk/")

exit()