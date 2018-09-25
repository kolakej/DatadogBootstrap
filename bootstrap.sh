#!/bin/bash
set -e
DATADOG_HOME="/etc/datadog-agent"
DATADOG_CONF_FILE=CONF="$DATADOG_HOME/datadog.yaml"
DATADOG_CONF_DIR="$DATADOG_HOME/conf.d/"
KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS|openSUSE|Amazon|Arista|SUSE)"
DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION  || grep -Eo $KNOWN_DISTRIBUTION /etc/issue 2>/dev/null || grep -Eo $KNOWN_DISTRIBUTION /etc/Eos-release 2>/dev/null || grep -m1 -Eo $KNOWN_DISTRIBUTION /etc/os-release 2>/dev/null || uname -s)
WORK_DIR=$(pwd)
if [ $DISTRIBUTION = CentOS ] || [ $DISTRIBUTION = RedHat ]
then
APACHE="httpd"
else
APACHE="apache2"
fi

function Integration() {
case $1 in
    nginx)
        if [ -f /etc/nginx/conf.d/status.conf ]
        then
        echo "/etc/nginx/conf.d/status.conf file exist"
        else 
        cat $WORK_DIR/integration/nginx/status.conf >>/etc/nginx/conf.d/status.conf
        fi
        cat $WORK_DIR/integration/nginx/conf.yaml>>$DATADOG_CONF_DIR/nginx.d/conf.yaml
        chown dd-agent:dd-agent $DATADOG_CONF_DIR/nginx.d/conf.yaml
        systemctl restart nginx
        systemctl restart datadog-agent
    ;;
    apache)
        if [ -f /etc/$APACHE/conf.modules.d/status.conf ]
        then
        echo "/etc/$APACHE/conf.modules.d/status.conf file exist"
        else
        cat $WORK_DIR/integration/apache/status.conf>>/etc/$APACHE/conf.modules.d/status.conf
        fi
        cat $WORK_DIR/integration/apache/conf.yaml>>$DATADOG_CONF_DIR/apache.d/conf.yaml
        chown dd-agent:dd-agent $DATADOG_CONF_DIR/apache.d/conf.yaml
        systemctl restart $APACHE
        systemctl restart datadog-agent
    ;;
esac
}
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }


for i in "$@"
do
case $i in
    -a=*|--agent=*)
        API_KEY="${i#*=}"
        DD_API_KEY=$API_KEY bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
    ;;
    -i=*|--integration=*)
        if [ -d /etc/datadog-agent ] 
        then
	        integration="${i#*=}"
            Integration $integration
        else
	        echo "Dont have a agent /nPlease use key -a=[Enter you API key here] or  to install agent"
        fi
    ;;
    -u|--upgrade)
        if [ -d /etc/datadog-agent ] 
            then
	        VERSION=$(datadog-agent version | awk '{print $2}')
            LATEST_VERSION=$(cat version)
                if version_gt $LATEST_VERSION $VERSION; then
                    DD_UPGRADE=true bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
                else
                    echo "Agent have latest version"
                 fi
            else
	        echo "Dont have a agent /nPlease use key -a=[Enter you api key here] to install agent"
        fi

    ;;
    -l) 
        echo "List if integration app:"
        ls -1 $WORK_DIR/integration
        echo "For integration use key --integration=[Enter integration app here]"
    ;;
    *)
        echo "Dont have this key"
    ;;
esac
done