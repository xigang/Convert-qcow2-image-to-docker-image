#!/bin/bash
#####################
#Script Name : Convert devel or release image to docker image
#Author : golfayi ( golfayi@sina.com)
#Author:  Xigang Wang (wangxigang@gmail.com)
#Using Method : ./ConvertToDockerImage.sh -i "ImageName"
####################

#================
# Check Permission of current user in $MOUNT_POINT/
#================
function CheckRootPerpermission()  
{  
    check_CurrentUser=`whoami`  
    if [ "$check_CurrentUser" == "root" ]  
    then   
        echo "You are $check_CurrentUser user, so is a supper admin."  
    else  
        echo "You are $check_CurrentUser user, so is a common user."  
    fi  
}

#================
#pre-check image before upload
#  1, if same image exists, abort this operation
#  2, if same image is not existed, continue
#================
function CheckImage()
{
    echo " release/devel image name: $1"
    imageqcow2=$1
    echo " imageqcow2: $imageqcow2"
    shortimagename=${imageqcow2##*/}
    echo " shortimagename: $shortimagename"
    JudgeImage $shortimagename;
}


function CheckImageExist()
{
    echo " image short name: $1"
    ls -al
    result=$(ls -al | grep $1)
    if [[ "$result" != "" ]]
    then
        echo "have $1 in image folder, abort this operation"
        exit 0
    else
        echo "Dont have $1 in image folder, continue"
    fi
}

function CheckQemuImgExist()
{
    echo "Check if the qemu-img tool exists."
    result=$(whereis qemu-img | awk '{print $2}')

    if [[ "$result" != "" ]]
    then
      echo "The qemu-img tool exists and is installed in the $result directory."
    else
      echo "The qemu-img tool does not exist. Please run the following command to install <yum install qemu-img>"
    fi
}

function GetImageName()
{
    [ $# -eq 0 ] #if no input, print the help info

    while getopts "i:p:o:h" opts
    do
        case $opts in
            i)
                IMAGE_NAME=$OPTARG
                ;;
            p)
                MOUNT_PPOINT=$OPTARG
                mkdir -p $MOUNT_PPOINT
                ;;
            o)
                PARTITION_OFFSET=$OPTARG
                ;;
            h)
              echo "Usage: ./ConvertToDockerImage.sh -i <image.qcow2> -p <mount-dir>"
                echo "-i the name of the image(eg: centos.qcow2)"
                echo "-p mount image to the location of the machine"
                echo "-o partition offet value for mount use"
                echo "-h print help info"
                ;;
            *)
                echo "unknown arguments: $OPTARG"
                ;;
        esac
    done

    if [ ! -z "$IMAGE_NAME" ]
    then
        echo "IMAGE NAME: " $IMAGE_NAME
    fi

    if [ ! -z "$MOUNT_PPOINT" ]
    then
        echo "IMAGE MOUNT POINT: " $MOUNT_PPOINT
    fi
}


function ConvertToDockerImage()
{
   imageqcow2=$1
   shortname=${imageqcow2##*/}
   echo " shortname: $shortname"
   namewithoutqcow2=${shortname%.*}
   echo " namewithoutqcow2 : $namewithoutqcow2"
   ls -al
   echo "qcloud" | sudo rm -rf $namewithoutqcow2.raw
   echo "qcloud" | sudo qemu-img convert -f qcow2 -O raw $shortname $namewithoutqcow2.raw
   echo " convert successfully "
   echo "qcloud"  | sudo fdisk -lu $namewithoutqcow2.raw
   echo "qcloud" | sudo rm -rf $namewithoutqcow2
   echo "qcloud" | sudo mkdir $namewithoutqcow2
   echo "partition offset: " $PARTITION_OFFSET
   echo "qcloud" | sudo mount -o loop,rw,offset=$PARTITION_OFFSET $namewithoutqcow2.raw  $MOUNT_PPOINT/$namewithoutqcow2
   echo " mount successfully "

   GenerateImage $namewithoutqcow2;
   UnmountImage $namewithoutqcow2;
   UploadToDocker $namewithoutqcow2;
}

function GenerateImage()
{
    echo " namewithoutqcow2: $1 "
    cd $MOUNT_POINT/$1
    ls -al
    pwd
    echo "qcloud" | sudo tar -czf $MOUNT_POINT/$1.tar.gz .
    echo " generate image successfully "
    cd ../
    ls -al
    pwd
}

function UnmountImage()
{
    echo " namewithoutqcow2: $1 "
    echo "qcloud" | sudo umount $MOUNT_POINT/$1
    echo "umount successfully "
}

function UploadToDocker()
{
    echo " namewithoutqcow2: $1 "
    echo "qcloud" | cat $MOUNT_POINT/$1.tar.gz | sudo docker import -c "EXPOSE 22" - $1 
    echo " upload to Docker successfully"
    echo "qcloud" | sudo docker images
    ls -al
    echo "qcloud" | sudo rm -rf *.gz
    echo "qcloud" | sudo rm -rf *.raw
    pwd
    ls -al
}


# script entry.
CheckRootPerpermission
GetImageName $@

if [ ! -z "$IMAGE_NAME" ]
then 
  ConvertToDockerImage $IMAGE_NAME
fi
