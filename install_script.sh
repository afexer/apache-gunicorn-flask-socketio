#!/bin/bash

if [ $# -eq 0 ]; then
  SITENAME="yoursite"
  SITEPREFIX="ys"
  PASSWORD="@Y0ur51t3!"
  SITE_IP_ADDRESS=192.168.0.1
else
  SITENAME=$1
  if [ $2 != '' ]; then
    SITEPREFIX=$2
  else
    echo "Missing Argument: SITEPREFIX (example ys)"
    exit
  fi
  PASSWORD="@Y0ur51t3!"
  SITE_IP_ADDRESS=192.168.0.1
fi

# install web server dependencies
sudo yum -y update python-virtualenv supervisor epel-release redis
sudo yum -y install python-virtualenv supervisor epel-release redis

# start redis server and enable autostart
sudo systemctl start redis
sudo systemctl enable redis

# start supervisor service and enable autostart
sudo systemctl start supervisord
sudo systemctl enable supervisord


sudo mkdir "/etc/httpd/ssl/"
sudo mkdir "/etc/httpd/ssl/ca/"
######################
## Change to your company details
######################
commonname="$SITENAME.com"
country="Your Country"
state="Your State"
locality="Your City"
organization="$SITENAME.com"
organizationalunit="IT"
email="webmaster@$SITENAME.com"

######################
# Become a Certificate Authority
######################
ROOTCA="/etc/httpd/ssl/ca/$SITENAME.CA.pem"
if [ ! -f "$ROOTCA" ]; then
  echo "##################################################"
  echo "Become a Certificate Authority"
  echo "##################################################"
  # Generate private key
  echo "#####################################"
  echo "Generate CA private key"
  echo "#####################################"
  sudo openssl genrsa -des3 -out "/etc/httpd/ssl/ca/$SITENAME.CA.key" -passout pass:"$PASSWORD" 2048
  # Generate root certificate
  echo "#####################################"
  echo "Generate CA root certificate"
  echo "#####################################"
  sudo openssl req -x509 -new -nodes -sha256 -days 825 -out "/etc/httpd/ssl/ca/$SITENAME.CA.pem" -passin pass:"$PASSWORD" -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email" -key "/etc/httpd/ssl/ca/$SITENAME.CA.key"

fi

######################
# Create CA-signed certs
######################
CRTFILE="/etc/httpd/ssl/$SITENAME.com.crt"
if [ ! -f "$CRTFILE" ]; then
  echo "##################################################"
  echo "Create CA Signed Certs"
  echo "##################################################"
  NAME="$SITENAME.com" # Use your own domain name
  # Generate a private key
  echo "#####################################"
  echo "Generate site a private key"
  echo "#####################################"
  sudo openssl genrsa -out "/etc/httpd/ssl/$NAME.key" 2048
  # Create a certificate-signing request
  echo "#####################################"
  echo "Create a site certificate signing request"
  echo "#####################################"
  sudo openssl req -new -key "/etc/httpd/ssl/$NAME.key" -out "/etc/httpd/ssl/$NAME.csr" -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
  # Create a config file for the extensions
  echo "#####################################"
  echo "Create a config file for the extensions"
  echo "#####################################"
  rm -rf "/etc/httpd/ssl/$NAME.ext"
sudo tee "/etc/httpd/ssl/$NAME.ext" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
DNS.2 = pysocket.$NAME # Optionally, add additional domains (I've added a subdomain here)
IP.1 = $SITE_IP_ADDRESS # Optionally, add an IP address (if the connection which you have planned requires it)
EOF
  # Create the signed certificate
  echo "#####################################"
  echo "Create signed certificate"
  echo "#####################################"
  sudo openssl x509 -req -in "/etc/httpd/ssl/$NAME.csr" -passin pass:"$PASSWORD" -CA "/etc/httpd/ssl/ca/$SITENAME.CA.pem" -CAkey "/etc/httpd/ssl/ca/$SITENAME.CA.key" -CAcreateserial -out "/etc/httpd/ssl/$NAME.crt" -days 825 -sha256 -extfile "/etc/httpd/ssl/$NAME.ext"
fi

# install application (source location in $1)
sudo mkdir "/var/www/pysocket.$SITENAME.com"
sudo mkdir "/var/www/pysocket.$SITENAME.com/log"
sudo mkdir "/var/www/pysocket.$SITENAME.com/log/apisocket_$SITEPREFIX"
sudo touch "/var/www/pysocket.$SITENAME.com/log/apisocket_$SITEPREFIX/access.log"
sudo chown -R centos:centos "/var/www/pysocket.$SITENAME.com"
sudo yes | cp -rf /home/centos/wspysocket/* "/var/www/pysocket.$SITENAME.com"

# change directories to set file permissions for the application
cd "/var/www/pysocket.$SITENAME.com/app"
find . -type f -exec chmod 664 {} \;
find . -type d -exec chmod 775 {} \;
sudo chown -R centos:centos .
sudo chown -R apache:apache ./static

# change directories to set file permissions for the log files
cd ..
cd "/var/www/pysocket.$SITENAME.com/log"
pwd
find . -type f -exec chmod 664 {} \;
find . -type d -exec chmod 775 {} \;
sudo chown -R centos:centos .

# move files to the $SITENAME that is specified above
cd ..
pwd
sudo mv "pysocket.{{SERVERNAME}}.com.conf" "pysocket.$SITENAME.com.conf"
sudo mv "pysocket.{{SERVERNAME}}.com.ssl.conf" "pysocket.$SITENAME.com.ssl.conf"
sudo mv "apisocket_{{SITEPREFIX}}_w1.conf" "apisocket_${SITEPREFIX}_w1.conf"
sudo mv "apisocket_{{SITEPREFIX}}_w2.conf" "apisocket_${SITEPREFIX}_w2.conf"

# Replace the {{SERVERNAME}} placeholder in the following files with the specified $SITENAME
sudo sed -i "s/{{SERVERNAME}}/$SITENAME/" "pysocket.$SITENAME.com.conf"
sudo sed -i "s/{{SERVERNAME}}/$SITENAME/" "pysocket.$SITENAME.com.ssl.conf"

sudo sed -i "s/{{SERVERNAME}}/$SITENAME/" "apisocket_${SITEPREFIX}_w1.conf"
sudo sed -i "s/{{SERVERNAME}}/$SITENAME/" "apisocket_${SITEPREFIX}_w1.conf"
sudo sed -i "s/{{SERVERNAME}}/$SITENAME/" "apisocket_${SITEPREFIX}_w1.conf"
sudo sed -i "s/{{SITEPREFIX}}/$SITEPREFIX/" "apisocket_${SITEPREFIX}_w1.conf"

sudo sed -i "s/{{SERVERNAME}}/$SITENAME/" "apisocket_${SITEPREFIX}_w2.conf"
sudo sed -i "s/{{SERVERNAME}}/$SITENAME/" "apisocket_${SITEPREFIX}_w2.conf"
sudo sed -i "s/{{SERVERNAME}}/$SITENAME/" "apisocket_${SITEPREFIX}_w2.conf"
sudo sed -i "s/{{SITEPREFIX}}/$SITEPREFIX/" "apisocket_${SITEPREFIX}_w2.conf"


# Copy CA pem file to site to download and add to Chrome/Firefox browsers
sudo cp "/etc/httpd/ssl/ca/$SITENAME.CA.pem" "/var/www/pysocket.$SITENAME.com/app/static/ca"

# create a virtualenv and install python dependencies
virtualenv "/var/www/pysocket.$SITENAME.com/venv"
venv/bin/pip install -r "/var/www/pysocket.$SITENAME.com/app/requirements.txt"

# configure supervisor to run two gunicorn eventlet workers
sudo supervisorctl stop "apisocket_${SITEPREFIX}_w1"
sudo supervisorctl stop "apisocket_${SITEPREFIX}_w2"
sudo systemctl stop supervisord
sudo redis-cli FLUSHALL
sudo rm -rf "/etc/supervisord.d/apisocket_${SITEPREFIX}_*"
sudo cp -R "/var/www/pysocket.$SITENAME.com/apisocket_${SITEPREFIX}_w1.conf" "/etc/supervisord.d/apisocket_${SITEPREFIX}_w1.ini"
sudo cp -R "/var/www/pysocket.$SITENAME.com/apisocket_${SITEPREFIX}_w2.conf" "/etc/supervisord.d/apisocket_${SITEPREFIX}_w2.ini"
sudo systemctl restart redis
sudo systemctl start supervisord
sudo supervisorctl reread
sudo supervisorctl update

# configure apache to reverse proxy to a loadbalancer pointed at the two gunnicorn application servers
sudo systemctl stop httpd
sudo rm -rf "/etc/httpd/conf.d/pysocket.$SITENAME.com.conf"
sudo cp -R "/var/www/pysocket.$SITENAME.com/pysocket.$SITENAME.com.conf" /etc/httpd/conf.d/
sudo rm -rf "/etc/httpd/conf.d/pysocket.$SITENAME.com.ssl.conf"
sudo cp -R "/var/www/pysocket.$SITENAME.com/pysocket.$SITENAME.com.ssl.conf" /etc/httpd/conf.d/
sudo systemctl start httpd

echo "Application deployed to http://pysocket.$SITENAME.com"