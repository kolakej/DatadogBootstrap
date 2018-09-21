set -e
DATADOG_HOME="/etc/datadog-agent"
DATADOG_CONF_FILE=CONF="$DATADOG_HOME/datadog.yaml"
DATADOG_CONF_DIR="$DATADOG_HOME/conf.d/"
AGENT_TYPE=$1
##Install Agent section##
##DD_API_KEY=$API_KEY bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
#Integrate agent##
Integration() {
case $1 in
     nginx)
echo "
  server {
  listen 81;
  server_name localhost;

  access_log off;
  allow 127.0.0.1;
  deny all;

  location /nginx_status {
    # Choose your status module

    # freely available with open source NGINX
    stub_status;

    # for open source NGINX < version 1.7.5
    # stub_status on;

    # available only with NGINX Plus
    # status;
  }
}">>/etc/nginx/conf.d/status.conf

echo "init_config:

instances:
  - nginx_status_url: http://localhost:81/nginx_status/">> $DATADOG_CONF_DIR/nginx.d/conf.yaml
  chown dd-agent:dd-agent $DATADOG_CONF_DIR/nginx.d/conf.yaml
  systemctl restart nginx
  systemctl restart datadog-agent
          ;;
     apache)
echo "<IfModule mod_status.c>
    <Location /server-status>
        SetHandler server-status
        <RequireAny>
            Require local
        </RequireAny>
    </Location>
    ExtendedStatus On
</IfModule>">>/etc/httpd/conf.modules.d/status.conf
echo "
init_config:

instances:
  - apache_status_url: http://localhost/server-status?auto
">>$DATADOG_CONF_DIR/apache.d/conf.yaml
chown dd-agent:dd-agent $DATADOG_CONF_DIR/apache.d/conf.yaml
systemctl restart httpd
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