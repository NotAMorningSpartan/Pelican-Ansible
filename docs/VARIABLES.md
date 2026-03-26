# Variable Reference

All user-facing variables with their defaults. Override in `group_vars/all.yml` or on the command line with `-e`.

## Panel Variables

### Common Role

| Variable | Default | Description |
|---|---|---|
| `pelican_base_packages` | `[curl, tar, unzip, git, policycoreutils-python-utils]` | Base OS packages to install |
| `pelican_firewall_ports` | `["80/tcp", "443/tcp"]` | Firewall ports to open |
| `pelican_selinux_booleans` | `[httpd_can_network_connect, httpd_unified]` | SELinux booleans to enable |

### PHP Role

| Variable | Default | Description |
|---|---|---|
| `pelican_php_version` | `"8.4"` | PHP version to install via Remi (`"8.2"`, `"8.3"`, `"8.4"`, `"8.5"`) |
| `pelican_web_user` | `"nginx"` | System user for PHP-FPM pool (must match web server) |
| `pelican_php_extensions` | `[php-gd, php-mysqlnd, php-mbstring, php-bcmath, php-xml, php-curl, php-zip, php-intl, php-sqlite3, php-fpm, php-cli]` | PHP extensions to install |

### Composer Role

| Variable | Default | Description |
|---|---|---|
| `composer_install_path` | `"/usr/local/bin/composer"` | Path to install the Composer binary |

### Database Role

Skipped entirely when `pelican_db_engine == "sqlite"`.

| Variable | Default | Description |
|---|---|---|
| `pelican_db_engine` | `"sqlite"` | Database engine (`"sqlite"`, `"mysql"`, `"mariadb"`, `"postgresql"`) |
| `pelican_db_name` | `"pelican"` | Database name to create |
| `pelican_db_user` | `"pelican"` | Database user to create |
| `pelican_db_password` | `"CHANGE_ME"` | Database password (**vault-encrypt in production**) |
| `pelican_db_host` | `"127.0.0.1"` | Database host for user privileges |
| `pelican_db_port` | `3306` | Database port (3306 for MySQL/MariaDB, 5432 for PostgreSQL) |

### Redis Role

Skipped entirely when `pelican_redis_enabled == false`.

| Variable | Default | Description |
|---|---|---|
| `pelican_redis_enabled` | `false` | Enable Redis installation |
| `pelican_redis_bind` | `"127.0.0.1"` | Redis bind address |
| `pelican_redis_port` | `6379` | Redis port |

### SSL Role

Skipped entirely when `pelican_ssl_enabled == false`.

| Variable | Default | Description |
|---|---|---|
| `pelican_ssl_enabled` | `true` | Enable SSL certificate provisioning via IDM/certmonger |
| `pelican_domain` | `"panel.example.com"` | Domain for the certificate |
| `pelican_webserver` | `"nginx"` | Web server (restarted by certmonger on renewal) |
| `pelican_ssl_cert` | `"/etc/pki/tls/certs/<domain>.crt"` | Path to the SSL certificate |
| `pelican_ssl_key` | `"/etc/pki/tls/private/<domain>.key"` | Path to the SSL private key |
| `pelican_ssl_principal` | `"HTTP/<domain>"` | IPA Kerberos principal for the certificate request |

### Webserver Role

| Variable | Default | Description |
|---|---|---|
| `pelican_webserver` | `"nginx"` | Web server to use (`"nginx"` or `"caddy"`) |
| `pelican_domain` | `"panel.example.com"` | Server name / site address |
| `pelican_ssl_enabled` | `true` | Deploy SSL or HTTP config template |
| `pelican_ssl_cert` | `"/etc/pki/tls/certs/<domain>.crt"` | SSL certificate path used in templates |
| `pelican_ssl_key` | `"/etc/pki/tls/private/<domain>.key"` | SSL private key path used in templates |
| `pelican_install_dir` | `"/var/www/pelican"` | Document root for web server |
| `pelican_web_user` | `"nginx"` | Web server system user |
| `pelican_php_version` | `"8.4"` | Used to locate PHP-FPM socket |

### Pelican App Role

| Variable | Default | Description |
|---|---|---|
| `pelican_install_dir` | `"/var/www/pelican"` | Application install directory |
| `pelican_app_version` | `"latest"` | Release to download (`"latest"` or a tag like `"1.0.0"`) |
| `pelican_web_user` | `"nginx"` | Owner of all application files |

## Wings Variables

### Common Role

| Variable | Default | Description |
|---|---|---|
| `wings_base_packages` | `[curl, tar, unzip]` | Base OS packages to install |
| `wings_firewall_ports` | `["8080/tcp", "2022/tcp", "443/tcp"]` | Firewall ports to open |

### Docker Role

| Variable | Default | Description |
|---|---|---|
| `wings_docker_edition` | `"ce"` | Docker edition |
| `wings_docker_channel` | `"stable"` | Docker release channel |
| `wings_docker_enable_swap` | `false` | Enable swap accounting in GRUB (requires reboot) |

### SSL Role

Skipped entirely when `wings_ssl_enabled == false`.

| Variable | Default | Description |
|---|---|---|
| `wings_ssl_enabled` | `true` | Enable SSL for Wings via IDM/certmonger |
| `wings_ssl_domain` | `"node1.example.com"` | FQDN for the certificate |
| `wings_ssl_cert` | `"/etc/pki/tls/certs/<domain>.crt"` | Path to the SSL certificate |
| `wings_ssl_key` | `"/etc/pki/tls/private/<domain>.key"` | Path to the SSL private key |
| `wings_ssl_principal` | `"HTTP/<domain>"` | IPA Kerberos principal for the certificate request |

### Wings Binary Role

| Variable | Default | Description |
|---|---|---|
| `wings_version` | `"latest"` | Wings release to download (`"latest"` or a tag like `"1.0.0"`) |
| `wings_architecture` | `"amd64"` | Target architecture (`"amd64"` or `"arm64"`) |
| `wings_binary_path` | `"/usr/local/bin/wings"` | Path for the Wings binary |
| `wings_config_dir` | `"/etc/pelican"` | Wings configuration directory |
| `wings_pid_dir` | `"/var/run/wings"` | Wings PID file directory |
