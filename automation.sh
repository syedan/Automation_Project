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




echo "===*** End of apache server checks ***==="
echo "cd into apache2 logs dir..."

cd /var/log/apache2/
myname="syed"
timestamp=$(date '+%d%m%Y-%H%M%S')
tarFileName="${myname}-httpd-logs-${timestamp}.tar"

echo "Generating tarfile for logs..."
tar -czvf $tarFileName *.log
tarSize=$(ls -sh $tarFileName | awk '{print $1}')


echo "Move log tar to /tmp..."
mv $tarFileName /tmp/

echo "copying log tar to s3..."
if [  -z "$s3_bucket" ]; then
  s3_bucket="upgrad-syed"
fi

aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar



echo "checking if inventory.html exists ..."
inventoryFile="/var/www/html/inventory.html"
if [ -e $inventoryFile ]
then
  echo "The inventory file exists"
else
  echo "Creating inventory.html"
  touch $inventoryFile
  echo "Log Type    Date Created    Type    Size\n" >> $inventoryFile;
fi
echo "httpd-logs    ${timestamp}    tar    ${tarSize}\n" >> $inventoryFile;





echo "checking if cron is scheduled ..."
cronFile="/etc/cron.d/automation"
if [ -e $cronFile ]
then
  echo "The cron file is present"
else
  echo "Creating cron"
  touch $cronFile
  echo -e "0 1 * * *  root /root/Automation_Project/automation.sh\n" >> $cronFile;
fi



