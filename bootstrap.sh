#!/bin/bash
set -e
DATADOG_HOME="/etc/datadog-agent"
DATADOG_CONF_FILE=CONF="$DATADOG_HOME/datadog.yaml"
DATADOG_CONF_DIR="$DATADOG_HOME/conf.d/"
OS=$(cat /etc/*-release | grep ^ID= | awk -F = '{print $2}')
if [ $OS = \"centos\" ]
then
APACHE="httpd"
else
APACHE="apache2"
fi

Integration() {
case $1 in
    nginx)
        cat nginx/status.conf >>/etc/nginx/conf.d/status.conf
        cat nginx/conf.yaml>>$DATADOG_CONF_DIR/nginx.d/conf.yaml
        chown dd-agent:dd-agent $DATADOG_CONF_DIR/nginx.d/conf.yaml
        systemctl restart nginx
        systemctl restart datadog-agent
    ;;
    apache)
        cat apache/status.conf>>/etc/$APACHE/conf.modules.d/status.conf
        cat apache/conf.yaml>>$DATADOG_CONF_DIR/apache.d/conf.yaml
        chown dd-agent:dd-agent $DATADOG_CONF_DIR/apache.d/conf.yaml
        systemctl restart $APACHE
        systemctl restart datadog-agent
    ;;
esac
}

for i in "$@"
do
case $i in
    -a=*|--agent=*)
        API_KEY="${i#*=}"
        DD_API_KEY=$API_KEY bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
    ;;
    -i=*|--integration=*)
        integration="${i#*=}"
        Integration $integration
    ;;
    *)
        echo "Dont have this key"
    ;;
esac
done