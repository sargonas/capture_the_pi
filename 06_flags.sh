#!/bin/bash

# MODULE 6: Deploy Enhanced CTF Flags

echo "[Module 6] Deploying enhanced CTF flags..."

# Create web directories
sudo mkdir -p /var/www/html/admin
sudo mkdir -p /var/www/html/config
sudo mkdir -p /var/www/html/backup
sudo mkdir -p /var/www/html/.hidden
sudo mkdir -p /var/www/html/api/v1
sudo mkdir -p /var/www/html/uploads
sudo mkdir -p /var/www/html/logs
sudo mkdir -p /var/www/html/temp
sudo mkdir -p /var/www/html/dev
sudo mkdir -p /var/www/html/old
sudo mkdir -p /var/www/html/test
sudo mkdir -p /var/www/html/maintenance

# === EASY FLAGS (100-200 points) ===

# Flag 1: Welcome flag in robots.txt
echo "User-agent: *" | sudo tee /var/www/html/robots.txt > /dev/null
echo "Disallow: /admin/" | sudo tee -a /var/www/html/robots.txt > /dev/null
echo "Disallow: /config/" | sudo tee -a /var/www/html/robots.txt > /dev/null
echo "Disallow: /.hidden/" | sudo tee -a /var/www/html/robots.txt > /dev/null
echo "# FLAG{welcome_to_honeypot}" | sudo tee -a /var/www/html/robots.txt > /dev/null

# Flag 2: Main page source
echo "<html><body><h1>Corporate Server</h1><!-- FLAG{web_explorer} --><p>Welcome to our intranet</p></body></html>" | sudo tee /var/www/html/index.html > /dev/null

# Flag 3: Config directory
echo "# Database Configuration" | sudo tee /var/www/html/config/database.conf > /dev/null
echo "host=localhost" | sudo tee -a /var/www/html/config/database.conf > /dev/null
echo "user=admin" | sudo tee -a /var/www/html/config/database.conf > /dev/null
echo "# FLAG{config_hunter}" | sudo tee -a /var/www/html/config/database.conf > /dev/null

# Flag 4: Admin panel
echo "<html><!-- FLAG{admin_access} --><body><h1>Admin Panel</h1><p>Access Denied</p></body></html>" | sudo tee /var/www/html/admin/index.html > /dev/null

# Flag 5: Hidden directory (directory traversal)
echo "FLAG{hidden_discovery}" | sudo tee /var/www/html/.hidden/secret.txt > /dev/null

# === MEDIUM FLAGS (250-400 points) ===

# Flag 6: Base64 encoded in HTML comment
echo "<html><body><h1>Support</h1><!-- RkxBR3tzb3VyY2VfY29kZV9yZXZpZXdlcn0= --><p>Contact IT</p></body></html>" | sudo tee /var/www/html/support.html > /dev/null

# Flag 7: Backup file with different extension
echo "<?php" | sudo tee /var/www/html/config.php.bak > /dev/null
echo "// Old configuration - FLAG{backup_file_exposed}" | sudo tee -a /var/www/html/config.php.bak > /dev/null
echo "\$db_pass = 'supersecret123';" | sudo tee -a /var/www/html/config.php.bak > /dev/null
echo "?>" | sudo tee -a /var/www/html/config.php.bak > /dev/null

# Flag 8: API endpoint
echo '{"status": "ok", "version": "1.0", "flag": "FLAG{api_enumeration}"}' | sudo tee /var/www/html/api/v1/status.json > /dev/null

# Flag 9: Log file with sensitive data
echo "[2024-08-06 12:34:56] Login attempt: admin:password123" | sudo tee /var/www/html/logs/access.log > /dev/null
echo "[2024-08-06 12:35:01] Failed login from 192.168.1.100" | sudo tee -a /var/www/html/logs/access.log > /dev/null
echo "[2024-08-06 12:35:15] FLAG{log_file_leakage} - Debug mode enabled" | sudo tee -a /var/www/html/logs/access.log > /dev/null

# Flag 10: Directory listing enabled
echo "FLAG{directory_listing}" | sudo tee /var/www/html/uploads/readme.txt > /dev/null
sudo rm -f /var/www/html/uploads/index.html 2>/dev/null || true

# Flag 11: Temp files
echo "Session data: user=admin, role=superuser" | sudo tee /var/www/html/temp/session_abc123.tmp > /dev/null
echo "FLAG{temp_file_exposure}" | sudo tee -a /var/www/html/temp/session_abc123.tmp > /dev/null

# === HARD FLAGS (500-700 points) ===

# Flag 12: Git repository exposed
sudo mkdir -p /var/www/html/.git/logs
echo "FLAG{git_exposure}" | sudo tee /var/www/html/.git/config > /dev/null
echo "commit abc123def456 - Added admin credentials" | sudo tee /var/www/html/.git/logs/HEAD > /dev/null
echo "Username: admin" | sudo tee -a /var/www/html/.git/logs/HEAD > /dev/null
echo "Password: FLAG{git_history_leak}" | sudo tee -a /var/www/html/.git/logs/HEAD > /dev/null

# Flag 13: Environment file
echo "DB_HOST=localhost" | sudo tee /var/www/html/.env > /dev/null
echo "DB_USER=root" | sudo tee -a /var/www/html/.env > /dev/null
echo "DB_PASS=FLAG{environment_variables}" | sudo tee -a /var/www/html/.env > /dev/null
echo "SECRET_KEY=supersecretkey123" | sudo tee -a /var/www/html/.env > /dev/null

# Flag 14: XML file with credentials
cat > /tmp/users.xml << 'XML_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<users>
    <user id="1">
        <username>admin</username>
        <password>FLAG{xml_parsing}</password>
        <role>administrator</role>
    </user>
    <user id="2">
        <username>guest</username>
        <password>guest123</password>
        <role>user</role>
    </user>
</users>
XML_EOF
sudo mv /tmp/users.xml /var/www/html/config/users.xml

# Flag 15: Development/debug endpoint
echo '{"debug": true, "server_info": {"version": "2.1.4", "flag": "FLAG{debug_info_disclosure}"}}' | sudo tee /var/www/html/dev/debug.json > /dev/null

# Flag 16: Old version files
echo "<h1>Version 1.0 - Deprecated</h1>" | sudo tee /var/www/html/old/index_v1.html > /dev/null
echo "<!-- TODO: Remove this before production -->" | sudo tee -a /var/www/html/old/index_v1.html > /dev/null
echo "<!-- Admin password: FLAG{legacy_code} -->" | sudo tee -a /var/www/html/old/index_v1.html > /dev/null

# Flag 17: Test credentials
echo "# Test Environment Credentials" | sudo tee /var/www/html/test/credentials.txt > /dev/null
echo "test_user:testpass123" | sudo tee -a /var/www/html/test/credentials.txt > /dev/null
echo "admin_test:FLAG{test_environment}" | sudo tee -a /var/www/html/test/credentials.txt > /dev/null

# === EXPERT FLAGS (800-1000 points) ===

# Flag 18: JWT Secret (Base64 encoded in weird location)
echo "Maintenance scheduled for tonight" | sudo tee /var/www/html/maintenance/notice.txt > /dev/null
echo "JWT_SECRET: RkxBR3tqd3Rfc2VjcmV0X2V4cG9zZWR9" | sudo tee -a /var/www/html/maintenance/notice.txt > /dev/null

# Flag 19: SQL dump file
cat > /tmp/backup.sql << 'SQL_EOF'
-- Database backup
-- Generated: 2024-08-06
CREATE TABLE users (id INT, username VARCHAR(50), password VARCHAR(100));
INSERT INTO users VALUES (1, 'admin', 'FLAG{sql_dump_analysis}');
INSERT INTO users VALUES (2, 'user', 'password123');
-- End of dump
SQL_EOF
sudo mv /tmp/backup.sql /var/www/html/backup/database_backup.sql

# Flag 20: Configuration with encryption key
echo "[encryption]" | sudo tee /var/www/html/config/app.ini > /dev/null
echo "algorithm=AES256" | sudo tee -a /var/www/html/config/app.ini > /dev/null
echo "key=FLAG{encryption_key_exposure}" | sudo tee -a /var/www/html/config/app.ini > /dev/null
echo "iv=1234567890abcdef" | sudo tee -a /var/www/html/config/app.ini > /dev/null

# Flag 21: Docker secrets
sudo mkdir -p /var/www/html/.docker
echo "registry.password=FLAG{docker_secrets}" | sudo tee /var/www/html/.docker/config.json > /dev/null

# Flag 22: Kubernetes config
sudo mkdir -p /var/www/html/.kube
echo "apiVersion: v1" | sudo tee /var/www/html/.kube/config > /dev/null
echo "kind: Config" | sudo tee -a /var/www/html/.kube/config > /dev/null
echo "# FLAG{kubernetes_config}" | sudo tee -a /var/www/html/.kube/config > /dev/null

# === NINJA FLAGS (1200+ points) ===

# Flag 23: Hidden in HTTP headers (will need special OpenCanary config)
echo "FLAG{http_header_injection}" | sudo tee /var/www/html/.htaccess_flag > /dev/null

# Flag 24: Steganography-style (hidden in plain sight)
echo "Welcome to our server!" | sudo tee /var/www/html/welcome.txt > /dev/null
echo "Friendly" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Learning" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Always" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Great" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "{" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Server" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Technology" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Enterprise" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Gateway" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Applications" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Network" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "Operations" | sudo tee -a /var/www/html/welcome.txt > /dev/null
echo "}" | sudo tee -a /var/www/html/welcome.txt > /dev/null
# FLAG{steganography} - first letter of each line

# Flag 25: Reverse engineering required
echo '{"data": "7B2274657874223A22524C424F65336C6A625856796558526C65575A3058326C7A6647397759576C754F6E3164222C22666C6167223A2246524C4245652D395247657232664A65314D227D"}' | sudo tee /var/www/html/api/encrypted_data.json > /dev/null

# Set permissions for all web files
sudo chown -R www-data:www-data /var/www/html 2>/dev/null || sudo chown -R $USER:$USER /var/www/html
sudo chmod -R 755 /var/www/html

# Make some files world-readable (security misconfiguration)
sudo chmod 644 /var/www/html/config/database.conf
sudo chmod 644 /var/www/html/logs/access.log
sudo chmod 644 /var/www/html/.env

echo "[Module 6] Enhanced flags deployed - 25 flags total!"
echo "  Easy: 5 flags (100-200 pts each)"
echo "  Medium: 7 flags (250-400 pts each)" 
echo "  Hard: 8 flags (500-700 pts each)"
echo "  Expert: 3 flags (800-1000 pts each)"
echo "  Ninja: 2 flags (1200+ pts each)"