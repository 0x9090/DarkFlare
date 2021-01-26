#!/usr/bin/env bash
set -e

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
