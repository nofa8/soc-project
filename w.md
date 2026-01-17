# 1. Remove the directory Docker created (Fixing the error)
sudo rmdir /var/log/firewall/firewall.log 2>/dev/null || sudo rm -rf /var/log/firewall/firewall.log

# 2. Create the real directory and file
sudo mkdir -p /var/log/firewall
sudo touch /var/log/firewall/firewall.log
sudo chmod 644 /var/log/firewall/firewall.log

# 3. Install and start the export service
sudo cp firewall/firewall-log-export.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now firewall-log-export.service

# 4. Restart containers to mount the correct file
docker-compose down
docker-compose up -d