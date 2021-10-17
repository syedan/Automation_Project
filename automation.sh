#!/bin/bash


while getopts ":a:b:" opt; do
  case $opt in
    b) s3_bucket="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac

  case $OPTARG in
    -*) echo "Option $opt needs a valid argument"
    exit 1
    ;;
  esac
done



echo "Updating package information..."
sudo apt update -y


isApacheInstalledWc=$(dpkg --get-selections | grep apache2 | wc -l)
if [ $isApacheInstalledWc -le 0 ]
then 
  echo "Installing apache2..."
  sudo apt-get -y install apache2
else
  echo "apache2 is already installed."
fi



isApacheRunningWc=$(systemctl --type=service --state=running  | grep apache2.service | wc -l)
if [ $isApacheRunningWc -le 0 ]
then 
  echo "Starting apache2..."
  sudo systemctl start apache2
else
  echo "apache2 is running."
fi


isApache2Enabled=$(sudo systemctl is-enabled apache2)
if [[ "$isApache2Enabled" == "enabled" ]]
then
  echo "apache2 is enabled."
else
  echo "enabling apache2..."
  sudo systemctl enable apache2
fi



echo "cd into apache2 logs dir..."
cd /var/log/apache2/
myname="syed"
timestamp=$(date '+%d%m%Y-%H%M%S')
tarFileName="${myname}-httpd-logs-${timestamp}.tar"

echo "Generating tarfile for logs..."
tar -czvf $tarFileName *.log


echo "Move log tar to /tmp..."
mv $tarFileName /tmp/

echo "copy log tar to s3..."
if [  -z "$s3_bucket" ]; then
  s3_bucket="upgrad-syed"
fi

aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

