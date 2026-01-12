#!/bin/bash

# Bootstrap Script - Tomcat & Maven Server
# Author: Mario Acosta Vargas
# Date: January 2026

set -e  # Exit on error

echo "[INFO] Provisioning Tomcat & Maven Server"

# 1. GLOBAL VARIABLES

TOMCAT_USER_GUI="alumno"
TOMCAT_PASS_GUI="1234"
TOMCAT_USER_DEPLOY="deploy"
TOMCAT_PASS_DEPLOY="1234"

SERVER_IP="192.168.56.110"

echo "[INFO] Server IP: $SERVER_IP"


# 2. SYSTEM UPDATE AND PACKAGE INSTALLATION

echo ""
echo "[STEP 1/7] Installing required packages..."

apt-get update -qq
apt-get install -y -qq openjdk-11-jdk tomcat9 tomcat9-admin maven git

echo "[OK] OpenJDK 11, Tomcat , Maven and Git installed"


# 3. CONFIGURE TOMCAT USERS AND ROLES

echo ""
echo "[STEP 2/7] Configuring Tomcat users and roles..."

# Copy tomcat-users.xml from synced folder
cp /vagrant/config/tomcat-users.xml /etc/tomcat9/tomcat-users.xml
chown root:tomcat /etc/tomcat9/tomcat-users.xml
chmod 640 /etc/tomcat9/tomcat-users.xml

echo "[OK] Tomcat users configured (alumno for GUI, deploy for Maven)"


# 4. CONFIGURE REMOTE ACCESS

echo ""
echo "[STEP 3/7] Configuring remote access..."

# Copy context.xml to allow remote access to manager apps
cp /vagrant/config/context.xml /usr/share/tomcat9-admin/manager/META-INF/context.xml
cp /vagrant/config/context.xml /usr/share/tomcat9-admin/host-manager/META-INF/context.xml

echo "[OK] Remote access configured for manager and host-manager"


# 5. CONFIGURE MAVEN SETTINGS

echo ""
echo "[STEP 4/7] Configuring Maven settings..."

# Create Maven settings with Tomcat server credentials
cat > /etc/maven/settings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd">
  
  <servers>
    <server>
      <id>Tomcat</id>
      <username>$TOMCAT_USER_DEPLOY</username>
      <password>$TOMCAT_PASS_DEPLOY</password>
    </server>
  </servers>

</settings>
EOF

echo "[OK] Maven configured with Tomcat server credentials"


# 6. RESTART SERVICES

echo ""
echo "[STEP 5/7] Restarting Tomcat service..."

systemctl restart tomcat9
systemctl enable tomcat9

echo "[OK] Tomcat service restarted and enabled"


# 7. CLONE AND PREPARE ROCK-PAPER-SCISSORS APP

echo ""
echo "[STEP 6/7] Cloning Rock-Paper-Scissors application..."

cd /home/vagrant

if [ ! -d "rock-paper-scissors" ]; then
    git clone https://github.com/cameronmcnz/rock-paper-scissors.git
    cd rock-paper-scissors
    git checkout patch-1
    
    # Add Tomcat Maven plugin to pom.xml if not present
    if ! grep -q "tomcat7-maven-plugin" pom.xml; then
        # Insert plugin before closing </build> tag
        sed -i '/<\/build>/i \
    <plugins>\
      <plugin>\
        <groupId>org.apache.tomcat.maven</groupId>\
        <artifactId>tomcat7-maven-plugin</artifactId>\
        <version>2.2</version>\
        <configuration>\
          <url>http://localhost:8080/manager/text</url>\
          <server>Tomcat</server>\
          <path>/rps</path>\
        </configuration>\
      </plugin>\
    </plugins>' pom.xml
    fi
    
    chown -R vagrant:vagrant /home/vagrant/rock-paper-scissors
    echo "[OK] Rock-Paper-Scissors cloned and configured"
else
    echo "[SKIP] Rock-Paper-Scissors already exists"
fi


# 8. COPY WAR FILE FOR MANUAL DEPLOYMENT

echo ""
echo "[STEP 7/7] Copying tomcat1.war for manual deployment test..."

if [ -f "/vagrant/config/tomcat1.war" ]; then
    cp /vagrant/config/tomcat1.war /home/vagrant/tomcat1.war
    chown vagrant:vagrant /home/vagrant/tomcat1.war
    echo "[OK] tomcat1.war copied to /home/vagrant/"
else
    echo "[WARN] tomcat1.war not found in config folder"
fi


# FINAL STATUS CHECK

echo ""
echo "  Provisioning Complete!"
echo ""
echo "Services Status:"
systemctl is-active tomcat9 && echo " [OK] Tomcat: RUNNING" || echo " [ERROR] Tomcat: STOPPED"
echo ""
echo "Installed Versions:"
echo "  Java:   $(java -version 2>&1 | head -n 1)"
echo "  Tomcat: $(dpkg -l | grep tomcat9 | head -n 1 | awk '{print $3}')"
echo "  Maven:  $(mvn -v 2>&1 | head -n 1)"
echo ""
echo "Access URLs (from host machine):"
echo "  Tomcat Home:     http://localhost:8080"
echo "  Manager GUI:     http://localhost:8080/manager/html"
echo "  Host Manager:    http://localhost:8080/host-manager/html"
echo ""
echo "Credentials:"
echo "  GUI User:    $TOMCAT_USER_GUI / $TOMCAT_PASS_GUI"
echo "  Deploy User: $TOMCAT_USER_DEPLOY / $TOMCAT_PASS_DEPLOY"
echo ""
echo "To deploy Rock-Paper-Scissors:"
echo "  cd /home/vagrant/rock-paper-scissors"
echo "  mvn tomcat7:deploy"
echo ""
