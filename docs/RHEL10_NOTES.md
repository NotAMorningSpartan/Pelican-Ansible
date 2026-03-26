# RHEL 10 Specific Notes

Considerations addressed by these playbooks for RHEL 10 targets.

## 1. PHP Availability

RHEL 10 base repos do not ship PHP 8.4/8.5. The `php` role installs the Remi repository (`remi-release-10.rpm`) and enables the appropriate module stream.

```bash
# What the role does under the hood:
dnf install https://rpms.remirepo.net/enterprise/remi-release-10.rpm
dnf module enable php:remi-8.4 -y
dnf install php php-fpm php-gd php-mbstring ...
```

To use a different PHP version, set `pelican_php_version` to `"8.2"`, `"8.3"`, or `"8.5"`.

## 2. SELinux Enforcing by Default

RHEL 10 runs SELinux in enforcing mode. **These playbooks keep it enforcing** and configure it properly.

**Panel booleans set:**
- `httpd_can_network_connect` — allows the web server to make outbound connections
- `httpd_unified` — allows httpd to access all unified content
- `httpd_can_network_connect_db` — allows database connections (only when `pelican_db_engine != "sqlite"`)

**File contexts applied:**
- `httpd_sys_rw_content_t` on the Pelican install directory (`/var/www/pelican`) via `ansible.posix.sefcontext` + `restorecon`

**Wings boolean set:**
- `container_manage_cgroup` — required for Docker container cgroup management

If you encounter `AVC` denials after installation:

```bash
# Check recent denials
ausearch -m AVC -ts recent

# Re-apply file contexts if needed
restorecon -Rv /var/www/pelican
```

## 3. firewalld is the Default Firewall

All firewall management uses `ansible.posix.firewalld`. No iptables rules are used.

**Panel ports:** 80/tcp, 443/tcp
**Wings ports:** 8080/tcp, 2022/tcp, 443/tcp

To verify open ports after installation:

```bash
firewall-cmd --list-ports
```

## 4. Web User Differs from Debian

On RHEL-based systems the web server runs under a different user than on Debian/Ubuntu:

| Web Server | RHEL User | Debian User |
|---|---|---|
| Nginx | `nginx:nginx` | `www-data:www-data` |
| Apache | `apache:apache` | `www-data:www-data` |
| Caddy | `caddy:caddy` | `caddy:caddy` |

The `pelican_web_user` variable (default: `"nginx"`) controls file ownership, PHP-FPM pool user, and socket permissions. If you switch to Caddy, set `pelican_web_user: "caddy"`.

## 5. No `sites-enabled` Pattern in Nginx

RHEL's Nginx package does not include a `sites-available` / `sites-enabled` directory structure. The webserver role places configuration directly at `/etc/nginx/conf.d/pelican.conf` and removes the default `/etc/nginx/conf.d/default.conf`.

## 6. Docker CE Repository

The Docker role uses the RHEL-specific repository URL:

```
https://download.docker.com/linux/rhel/$releasever/$basearch/stable
```

This is distinct from the CentOS URL (`/linux/centos/`). Using the wrong URL may result in incompatible packages on RHEL 10.

## 7. PHP-FPM Socket Path

On RHEL, the PHP-FPM socket is located at `/run/php-fpm/www.sock` (not `/run/php/php8.x-fpm.sock` as on Debian). All web server templates in this project use the RHEL path. If you are adapting templates from Debian-based guides, update the socket path accordingly.

## 8. SSL Certificates via Red Hat IDM (certmonger)

These playbooks use `ipa-getcert` (certmonger) to request SSL certificates from a Red Hat Identity Management (IDM/FreeIPA) certificate authority. This requires:

- **Target hosts must be IPA-enrolled** (`ipa-client-install` completed) before running the playbooks
- **The IDM CA must be operational** and reachable from the target hosts
- **HTTP service principals** (e.g. `HTTP/panel.example.com`) will be created automatically by `ipa-getcert request`

Certmonger handles automatic renewal — no cron jobs needed. Certificates are placed in `/etc/pki/tls/certs/` and `/etc/pki/tls/private/` by default.

To check certificate status after deployment:

```bash
ipa-getcert list
# Status should show: MONITORING
```

To manually resubmit a failed request:

```bash
ipa-getcert resubmit -f /etc/pki/tls/certs/<domain>.crt
```
