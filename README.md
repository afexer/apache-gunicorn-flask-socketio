# apache-gunicorn-flask-socketio on CentOS 7
A project to create a load balanced websocket server using apache gunicorn and flask-socketio for a CentOs 7 server

## Setup:
Make sure you have apache 2.4, MySql, and OpenSSL installed on your server

You will need to create a MySql database named pysocket_db with the user: pysocket_admin and password: @Y0ur51t3!
Or you can change the mysql connection setting in config/development.py, config/production.py, and config/testing.py

Edit the install_script.sh file and update the SITENAME, SITEPREFIX, PASSWORD, and SITE_IP_ADDRESS to your site info
- If your site is developmentserver.com SITENAME would be developmentserver
- If your site is developmentserver.com SITEPREFIX could be ds
- The PASSWORD is used when making the SSL Certificate Authority
- The SITE_IP_ADDRESS is also used when making the SSL Certificate Authority
- In the section "Change to your company details" change country (ex US), state (ex NY), locality (ex Buffalo), and organizationalunit (ex IT) to the correct info for your area.


## Installation
Check out the repository into a folder in your home directory. Then run ./install_script.sh 
