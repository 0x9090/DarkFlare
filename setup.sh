#!/usr/bin/env bash

set -e
set -o errexit
set -o nounset
set -o pipefail

name="allium_cepa"

function log () {
    message=${1:-}
    arg2=${2:-0}
    if [ ${arg2} = 0 ]; then
        echo -e "${message}" >&2
    elif [ ${arg2} = 1 ]; then
        echo -e "\033[0;31m${message}\033[0m" >&2 # red
    elif [ ${arg2} = 2 ]; then
        echo -e "\033[0;94m${message}\033[0m" >&2 # blue
    else
        echo -e "${message}" >&2
    fi
}

function handle_exit() {
    rm -f /tmp/${name}/mutex.lock
    rm -rf /tmp/${name}
    exit 0
}
trap handle_exit SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM

if [ "$EUID" -ne 0 ]; then
    log "Not root"
    exit 1
fi

if [ -f /tmp/${name}-mutex.lock ]; then
    log "Another instance running" 1
    exit 1
else
    #touch /tmp/${name}-mutex.lock
    echo ""
fi

directory=$(pwd)
arch=$(uname -m)
kernel=$(uname -r)
if [ -n "$(command -v lsb_release)" ]; then
    distroname=$(lsb_release -s -d)
elif [ -f "/etc/os-release" ]; then
	distroname=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="')
elif [ -f "/etc/debian_version" ]; then
	distroname="Debian $(cat /etc/debian_version)"
elif [ -f "/etc/redhat-release" ]; then
	distroname=$(cat /etc/redhat-release)
else
	distroname="$(uname -s) $(uname -r)"
fi
log "Distro: ${distroname}"
log "Arch: ${arch}"
log "Kernel: ${kernel}"
log "Directory: ${directory}"

apt update
apt upgrade -y
apt install unattended-upgrades apt-transport-https apt-transport-tor gpg expect sudo -y

cat > /etc/apt/sources.list.d/tor.list<< EOF
deb     https://deb.torproject.org/torproject.org $(lsb_release -cs) main
deb-src https://deb.torproject.org/torproject.org $(lsb_release -cs) main
EOF
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

#curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
#add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

apt update
apt install tor deb.torproject.org-keyring ca-certificates gnupg-agent software-properties-common -y
apt install git lsof -y

# --- Install & Start Hidden Service --- #
mkdir -p /var/lib/tor/hidden_service/
chmod 0700 /var/lib/tor/hidden_service/
chown -R debian-tor:debian-tor /var/lib/tor/hidden_service/
rm -f /etc/tor/torrc
cat > /etc/tor/torrc<< EOF
User debian-tor
PIDFile /var/run/tor/tor.pid
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 127.0.0.1:80
Log notice syslog
EOF
chmod 0644 /etc/tor/torrc
chown root:root /etc/tor/torrc
service tor restart
#systemctl enable tor@default
tar -zcvf ~/hidden_service_backup.tgz /var/lib/tor/hidden_service
sleep 1
tor_service_name=$(cat /var/lib/tor/hidden_service/hostname)


# --- Install & Start Nginx Proxy --- #
apt install nginx -y
sed -i -e 's/^.*server_tokens.*$//g' /etc/nginx/nginx.conf
sed -i -e 's/http {/http {\n\tserver_tokens off;/g' /etc/nginx/nginx.conf
cat > /etc/nginx/sites-available/tor.conf<< EOF
server {
    listen 127.0.0.1:80 default_server;
    server_name ${tor_service_name};
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    client_max_body_size 100M;
    charset utf-8;
    root /opt/flarum/public;
    index index.html index.php;
    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    location ~ \\.php\$ {
        fastcgi_split_path_info ^(.+\\.php)(/.+)\$;
        fastcgi_pass unix:/var/run/php-fpm-flarum.sock;
        fastcgi_index index.php;
        include fastcgi.conf;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
rm -rf /etc/nginx/sites-enabled/*
ln -sf /etc/nginx/sites-available/tor.conf /etc/nginx/sites-enabled/tor.conf
service nginx restart

# --- Install & Start MariaDB --- #
if ! pgrep -x mariadbd &> /dev/null 2>&1; then
    log "--- mariadb not installed ---"
    mkdir -p /tmp/${name}/wget
    wget https://mariadb.org/mariadb_release_signing_key.asc -e use_proxy=yes -e http_proxy=127.0.0.1:9050 -P /tmp/${name}/wget/
    apt-key add /tmp/${name}/wget/mariadb_release_signing_key.asc
    add-apt-repository "deb [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.5/debian $(lsb_release -cs) main"
    apt update
    apt install mariadb-server mariadb-client -y
    if [ ! -f ~/mariadb_root_pw ]; then
        pass=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c14; echo)
        echo ${pass} >> ~/mariadb_root_pw
        mysql --user=root --password="${pass}" -e "SET PASSWORD FOR root@localhost = PASSWORD('${pass})');"
    else
        pass=$(cat ~/mariadb_root_pw)
    fi
    mysql --force --user=root --password="${pass}" -e "DELETE FROM mysql.user where User='';"
    mysql --force --user=root --password="${pass}" -e "DELETE FROM mysql.user where User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    #mysql --force --user=root --password="${pass}" -e "DROP DATABASE test;"
    #mysql --force --user=root --password="${pass}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
    mysql --force --user=root --password="${pass}" -e "FLUSH PRIVILEGES;"
    if ! mysql --user=root --password="${pass}" -e "use flarum"; then
        log "flarum database non-existant" 2
        mysql --user=root --password="${pass}" -e "CREATE DATABASE flarum;"
        if [ ! -f ~/mariadb_flarum_pw ]; then
            pass2=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c14; echo)
            echo ${pass2} >> ~/mariadb_flarum_pw
        else
            pass2=$(cat ~/mariadb_flarum_pw)
        fi
        mysql --force --user=root --password="${pass}" -e "CREATE USER 'flarum'@'localhost' IDENTIFIED BY '${pass2}'"
        mysql --force --user=root --password="${pass}" -e "GRANT ALL ON flarum.* TO 'flarum'@'localhost' IDENTIFIED BY '${pass2}' WITH GRANT OPTION;"
        mysql --user=root --password="${pass}" -e "FLUSH PRIVILEGES;"
    fi
fi


# --- Install & Start Flarum --- #
adduser --disabled-password --system composer
groupadd -f -r composer
usermod -aG composer composer
chown -R composer:composer /home/composer
chmod -R 0700 /home/composer
apt install php php-fpm php-gd php-mysql php-mbstring php-xml php-curl unzip software-properties-common dirmngr -y
<<COMMENT
# Hardening PHP.ini
find / -type f -name php.ini -exec sed -i -e 's/^.*allow_url_fopen.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "allow_url_fopen = 0" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*allow_url_include.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "allow_url_include = 0" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*max_input_time.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "max_input_time = 30" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*max_execution_time.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "max_execution_time = 30" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*memory_limit.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "memory_limit = 8M" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*register_globals.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "register_globals = off" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*expose_php.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "expose_php = 0" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*cgi\.force_redirect.*$//g' {} + # Enforce PHP exec only via CGI
find / -type f -name php.ini -exec sh -c 'echo "cgi.force_redirect = 1" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*post_max_size.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "post_max_size = 256K" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*max_input_vars.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "max_input_vars = 100" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*display_errors.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "display_errors = 0" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*display_startup_errors.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "display_startup_errors = 0" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*log_errors.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "log_errors = 0" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*open_basedir.*$//g' {} + # whitelisting of PHP exec locations
find / -type f -name php.ini -exec sh -c 'echo "open_basedir = \"/opt/flarum\"" >> "${1-}"' -- {} \;
find / -type f -name php.ini -exec sed -i -e 's/^.*upload_max_filesize.*$//g' {} +
find / -type f -name php.ini -exec sh -c 'echo "upload_max_filesize = 1M" >> "${1-}"' -- {} \;
service php7.3-fpm restart
COMMENT
if [ ! -f /opt/bin/composer ]; then
    EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
    then
	    log 'ERROR: Invalid Composer installer checksum' 2
	    rm composer-setup.php
	    handle_exit
    fi
    php composer-setup.php
    RESULT=$?
    rm composer-setup.php
    mkdir -p /opt/bin
    mv composer.phar /opt/bin/composer
else
    php /opt/bin/composer self-update
fi
chmod -R 0755 /opt/bin/composer
ln -sf /opt/bin/composer /usr/bin/composer
chmod +x /opt/bin/composer
log "Composer installed: /home/composer/bin/composer"
adduser --disabled-password --system flarum --shell /bin/bash
groupadd -f -r flarum
usermod -aG flarum flarum
mkdir -p /opt/flarum
chown -R flarum:flarum /home/flarum
chown -R www-data:www-data /opt/flarum
chmod -R 0700 /home/flarum
chmod -R 0755 /opt/flarum
if [ ! "$(ls -A /opt/flarum)" ]; then
    runuser -l flarum -c "cd /opt/flarum && composer create-project flarum/flarum . --stability=beta"
fi
rm -f /etc/php/7.3/fpm/pool.d/*
cat > /etc/php/7.3/fpm/pool.d/www.conf<< EOF
[www]
user = www-data
group = www-data
listen = /var/run/php-fpm-flarum.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500
slowlog = /var/log/php7.3-fpm/slow.log
request_slowlog_timeout = 5s
php_admin_value[disable_functions]=exec,passthru,shell_exec,system
php_admin_flag[allow_url_fopen0]=off
php_flag[display_errors]=off
EOF
touch /var/run/php-fpm-flarum.sock
chown www-data:www-data /var/run/php-fpm-flarum.sock
mkdir -p /var/log/php7.3-fpm
touch /var/log/php7.3-fpm/slow.log
chown -R www-data:www-data /opt/flarum/public
service php7.3-fpm restart


# --- Cleanup --- #
apt autoclean
apt autoremove -y
cd ${directory}
clear
log "\n------- Hidden Service Address -------\n${tor_service_name}\n"
log "\nGenerated passwords for your MariaDB instance can be found in /root or your home directory.\n"
handle_exit
