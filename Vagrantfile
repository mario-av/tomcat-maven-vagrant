# Vagrantfile - Tomcat & Maven Deployment Server
# Author: Mario Acosta Vargas
# Date: January 2026

Vagrant.configure("2") do |config|

  # 1. Base OS Image
  config.vm.box = "debian/bullseye64"

  # 2. Hostname
  config.vm.hostname = "tomcat.local"

  # 3. Private Network
  config.vm.network "private_network", ip: "192.168.56.110"

  # 4. Port Forwarding
  config.vm.network "forwarded_port", guest: 8080, host: 8080

  # 5. VirtualBox Provider Settings
  config.vm.provider "virtualbox" do |vb|
    vb.name = "Tomcat-Maven-Server"
    vb.memory = "2048"
    vb.cpus = 2
  end

  # 6. Synced Folder
  config.vm.synced_folder "config", "/vagrant/config"

  # 7. Provisioning Script
  config.vm.provision "shell", path: "config/bootstrap.sh"
  
end
