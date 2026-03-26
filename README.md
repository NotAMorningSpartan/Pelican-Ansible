# Pelican Panel & Wings — Ansible Playbooks

Ansible playbooks for automated installation of **Pelican Panel** and **Pelican Wings** on RHEL 10 systems.

These playbooks automate the full installation stack: PHP (via Remi), Composer, Nginx or Caddy, optional database (MySQL/MariaDB/PostgreSQL), optional Redis, SSL certificates, Docker CE, and the Wings daemon — all configured for SELinux enforcing mode and firewalld.

## Prerequisites

- **Control node:** Ansible 2.16+ with Python 3
- **Target hosts:** RHEL 10 (or compatible) with SSH access and a user with sudo privileges
- **DNS:** A and/or AAAA records pointing your Panel and Wings domains to the target servers
- **Network:** Ports 80 and 443 reachable for Let's Encrypt validation (if using certbot)

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/your-org/pelican-ansible.git
cd pelican-ansible
```

### 2. Install Ansible collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### 3. Configure the Panel inventory

Edit `inventories/panel/hosts.yml` with your Panel server's IP or hostname:

```yaml
all:
  hosts:
    panel:
      ansible_host: 203.0.113.10
      ansible_user: root
```

Edit `inventories/panel/group_vars/all.yml` with your environment settings:

```yaml
pelican_domain: "panel.example.com"
pelican_ssl_email: "admin@example.com"
pelican_db_engine: "sqlite"
```

### 4. Run the Panel playbook

```bash
ansible-playbook panel/site.yml -i inventories/panel/hosts.yml
```

### 5. Configure the Wings inventory

Edit `inventories/wings/hosts.yml` and `inventories/wings/group_vars/all.yml`:

```yaml
wings_ssl_domain: "node1.example.com"
wings_ssl_email: "admin@example.com"
```

### 6. Run the Wings playbook

```bash
ansible-playbook wings/site.yml -i inventories/wings/hosts.yml
```

## Variable Reference (Summary)

See [docs/VARIABLES.md](docs/VARIABLES.md) for the complete reference.

### Key Panel Variables

| Variable | Default | Description |
|---|---|---|
| `pelican_webserver` | `"nginx"` | `"nginx"` or `"caddy"` |
| `pelican_domain` | `"panel.example.com"` | Panel FQDN |
| `pelican_ssl_enabled` | `true` | Enable SSL |
| `pelican_ssl_provider` | `"certbot"` | `"certbot"` or `"self_signed"` |
| `pelican_db_engine` | `"sqlite"` | `"sqlite"`, `"mysql"`, `"mariadb"`, or `"postgresql"` |
| `pelican_db_password` | `"CHANGE_ME"` | Database password (vault-encrypt!) |
| `pelican_redis_enabled` | `false` | Enable Redis |
| `pelican_php_version` | `"8.4"` | PHP version via Remi |
| `pelican_app_version` | `"latest"` | `"latest"` or a specific release tag |

### Key Wings Variables

| Variable | Default | Description |
|---|---|---|
| `wings_ssl_domain` | `"node1.example.com"` | Node FQDN |
| `wings_ssl_method` | `"standalone"` | `"standalone"` or `"dns"` |
| `wings_architecture` | `"amd64"` | `"amd64"` or `"arm64"` |
| `wings_version` | `"latest"` | `"latest"` or a specific release tag |
| `wings_docker_enable_swap` | `false` | Enable swap accounting (requires reboot) |

## Common Scenarios

### Panel with Nginx + SSL + SQLite (simplest)

```yaml
# inventories/panel/group_vars/all.yml
pelican_domain: "panel.example.com"
pelican_ssl_email: "admin@example.com"
```

All other defaults apply: Nginx, certbot SSL, SQLite, no Redis.

### Panel with Caddy + SSL + MariaDB + Redis (full stack)

```yaml
# inventories/panel/group_vars/all.yml
pelican_webserver: "caddy"
pelican_domain: "panel.example.com"
pelican_ssl_email: "admin@example.com"
pelican_db_engine: "mariadb"
pelican_db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...
pelican_redis_enabled: true
```

### Wings node with SSL

```yaml
# inventories/wings/group_vars/all.yml
wings_ssl_domain: "node1.example.com"
wings_ssl_email: "admin@example.com"
```

For ARM64 nodes:

```yaml
wings_architecture: "arm64"
```

## Post-Installation Steps

1. **Complete Panel web setup:** Navigate to `https://<panel_domain>/installer` in your browser and follow the setup wizard to create your admin account.

2. **Back up your APP_KEY:** The playbook prints the key during execution. You can also find it in `/var/www/pelican/.env`. Loss of this key means all encrypted data is irrecoverable.

3. **Connect Wings to Panel:**
   - In the Panel admin UI, go to **Nodes** and create a new node.
   - Copy the configuration YAML from the **Configuration** tab.
   - Paste it into `/etc/pelican/config.yml` on the Wings server.
   - Restart Wings: `systemctl restart wings`
   - Alternatively, use the **Auto Deploy Command** from the Panel.

4. **Verify the connection:** Check the Panel UI — the node should show as connected with a green status.

## Troubleshooting

### PHP-FPM socket errors in Nginx/Caddy

Verify the socket exists and has correct ownership:

```bash
ls -la /run/php-fpm/www.sock
# Should be owned by the web user (nginx or caddy)
systemctl status php-fpm
```

### SELinux denials

Check the audit log for denials:

```bash
ausearch -m AVC -ts recent
# If Pelican files are denied, re-run restorecon:
restorecon -Rv /var/www/pelican
```

### Certbot certificate request fails

Ensure DNS points to the server and ports 80/443 are reachable:

```bash
firewall-cmd --list-ports
curl -I http://<domain>
```

For Wings standalone certbot, ensure no other service is listening on port 80:

```bash
ss -tlnp | grep :80
```

### Wings won't connect to Panel

- Verify `/etc/pelican/config.yml` exists and contains the correct Panel URL and token.
- Check Wings logs: `journalctl -u wings -f`
- Ensure firewall ports are open: `firewall-cmd --list-ports`

### Docker issues on Wings node

```bash
systemctl status docker
docker info
journalctl -u docker -f
```

If swap accounting was enabled, a reboot is required before it takes effect.

## Security Notes

- **Vault-encrypt all passwords** before committing to version control:
  ```bash
  ansible-vault encrypt_string 'your_db_password' --name 'pelican_db_password'
  ```
  Then run playbooks with `--ask-vault-pass` or `--vault-password-file`.

- **Never commit plaintext credentials** to version control. The `pelican_db_password` default of `"CHANGE_ME"` is intentional — always override it.

- **SELinux remains enforcing.** These playbooks configure SELinux properly rather than disabling it. Do not set SELinux to permissive or disabled.

- **Firewall is configured, not disabled.** Only the required ports are opened. Review `pelican_firewall_ports` and `wings_firewall_ports` if you need additional ports.

- **Back up the APP_KEY** from `/var/www/pelican/.env` immediately after installation. Store it securely — it encrypts all sensitive data in the Panel database.

- **Restrict SSH access** to the Ansible control node and trusted administrators only.

## RHEL 10 Notes

See [docs/RHEL10_NOTES.md](docs/RHEL10_NOTES.md) for platform-specific considerations including PHP availability, SELinux, firewalld, web user differences, and Docker repository configuration.

## Project Structure

```
pelican-ansible/
├── ansible.cfg
├── requirements.yml
├── inventories/
│   ├── panel/
│   │   ├── hosts.yml
│   │   └── group_vars/all.yml
│   └── wings/
│       ├── hosts.yml
│       └── group_vars/all.yml
├── panel/
│   ├── site.yml
│   └── roles/
│       ├── common/        # Base packages, SELinux, firewall
│       ├── php/           # PHP via Remi repository
│       ├── composer/      # Composer binary
│       ├── database/      # MySQL, MariaDB, or PostgreSQL
│       ├── redis/         # Optional Redis
│       ├── ssl/           # Certbot or self-signed certificates
│       ├── webserver/     # Nginx or Caddy
│       └── pelican_app/   # Panel download and setup
├── wings/
│   ├── site.yml
│   └── roles/
│       ├── common/        # Base packages, SELinux, firewall
│       ├── docker/        # Docker CE
│       ├── ssl/           # Certbot certificates
│       └── wings_binary/  # Wings daemon
└── docs/
    ├── VARIABLES.md
    └── RHEL10_NOTES.md
```

## License

See [LICENSE](LICENSE) for details.
