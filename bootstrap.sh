#!/bin/bash
set -e
DATADOG_HOME="/etc/datadog-agent"
DATADOG_CONF_FILE=CONF="$DATADOG_HOME/datadog.yaml"
DATADOG_CONF_DIR="$DATADOG_HOME/conf.d/"
KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS|openSUSE|Amazon|Arista|SUSE)"
DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION  || grep -Eo $KNOWN_DISTRIBUTION /etc/issue 2>/dev/null || grep -Eo $KNOWN_DISTRIBUTION /etc/Eos-release 2>/dev/null || grep -m1 -Eo $KNOWN_DISTRIBUTION /etc/os-release 2>/dev/null || uname -s)
if [ $DISTRIBUTION = CentOS ] || [ $DISTRIBUTION = RedHat ]
then
APACHE="httpd"
else
APACHE="apache2"
fi

Integration() {
case $1 in
    nginx)
        if [ -f /etc/nginx/conf.d/status.conf ]
        then
        echo "/etc/nginx/conf.d/status.conf file exist"
        else 
        cat nginx/status.conf >>/etc/nginx/conf.d/status.conf
        fi
        cat nginx/conf.yaml>>$DATADOG_CONF_DIR/nginx.d/conf.yaml
        chown dd-agent:dd-agent $DATADOG_CONF_DIR/nginx.d/conf.yaml
        systemctl restart nginx
        systemctl restart datadog-agent
    ;;
    apache)
        if [ -f /etc/$APACHE/conf.modules.d/status.conf ]
        then
        echo "/etc/$APACHE/conf.modules.d/status.conf file exist"
        else
        cat apache/status.conf>>/etc/$APACHE/conf.modules.d/status.conf
        fi
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
    -u|--upgrade)
        VERSION=$(datadog-agent version | awk '{print $2}')
        LATEST_VERSION=
        DD_UPGRADE=true bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
    ;;
    *)
        echo "Dont have this key"
    ;;
esac
done