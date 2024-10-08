#!/bin/bash

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
BOLD="\033[1m"
RESET="\033[0m"

total_steps=16
current_step=0

show_progress() {
    local progress=$(( (current_step * 100) / total_steps ))
    echo -ne "${BLUE}${BOLD}Progress: ${progress}%${RESET}\n"
}

next_step() {
    current_step=$((current_step + 1))
    show_progress
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

wait_for_dpkg_lock() {
    echo -ne "${YELLOW}${BOLD}Waiting for dpkg lock to be released...${RESET}"
    while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
        sleep 1
    done
    echo -e "${GREEN} Done!${RESET}"
}

display_menu() {
    clear
    echo -e "${CYAN}${BOLD}======================================${RESET}"
    echo -e "${GREEN}${BOLD}   Made by Astro-Service | Version 1.0.1${RESET}"
    echo -e "${YELLOW}${BOLD}   Join us on Discord: https://discord.gg/vsN2SGf2gZ${RESET}"
    echo -e "${CYAN}${BOLD}======================================${RESET}"
    echo ""
    echo -e "${YELLOW}${BOLD}Wähle eine Option:${RESET}"
    echo "1) Apache2 und phpMyAdmin installieren"
    echo "2) FiveM-Server mit txAdmin installieren"
    echo "3) Setup abbrechen"
    echo ""
    read -p "Option: " choice
    case $choice in
        1)
            echo -e "${GREEN}Installation wird gestartet...${RESET}"
            install_mariadb
            install_apache2
            install_php
            install_phpmyadmin
            create_admin_account
            ;;
        2)
            echo -e "${GREEN}FiveM-Server mit txAdmin wird installiert...${RESET}"
            read -p "Gib den Link zur Artifact-Version an: " artifact_url
            install_fivem_with_txadmin "$artifact_url"
            ;;
        3)
            echo -e "${RED}Setup abgebrochen.${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Ungültige Auswahl. Bitte versuche es erneut.${RESET}"
            display_menu
            ;;
    esac
}

generate_password() {
    openssl rand -base64 12 | cut -c1-16
}

generate_username() {
    local base="Admin"
    local number=$(shuf -i 100000-999999 -n 1)
    echo "${base}${number}"
}

install_php() {
    print_header "Installing PHP and Required Modules"
    wait_for_dpkg_lock
    
    print_step "Installing PHP"
    sudo apt-get install php libapache2-mod-php php-mysql php-json php-gd php-mbstring php-curl php-zip php-xml -y 2>&1 | tee -a /root/php_install.log
    echo -e "${GREEN} Done!${RESET}"
    next_step

    print_step "Restarting Apache to apply PHP configuration"
    sudo systemctl restart apache2 2>&1 | tee -a /root/php_install.log
    echo -e "${GREEN} Done!${RESET}"
    next_step

    if command_exists php; then
        echo -e "${GREEN}${BOLD}PHP successfully installed!${RESET}"
    else
        echo -e "${RED}${BOLD}Failed to install PHP.${RESET}"
        echo -e "${YELLOW}${BOLD}Check the log file at /root/php_install.log for details.${RESET}"
        exit 1
    fi
}

install_mariadb() {
    print_header "Installing MariaDB"
    wait_for_dpkg_lock
    
    print_step "Checking if MariaDB is installed"
    if command_exists mysql; then
        echo -e "${GREEN} MariaDB is already installed.${RESET}"
    else
        print_step "Installing MariaDB Server"
        sudo apt-get install mariadb-server -y 2>&1 | tee -a /root/mariadb_install.log
        echo -e "${GREEN} Done!${RESET}"
    fi
    next_step
    
    print_step "Ensuring MariaDB is running"
    sudo systemctl start mariadb
    sudo systemctl enable mariadb
    sleep 5
    if sudo systemctl status mariadb | grep -q "active (running)"; then
        echo -e "${GREEN} MariaDB is running.${RESET}"
    else
        echo -e "${RED} MariaDB failed to start. Please check the logs.${RESET}"
        exit 1
    fi
    next_step
}

install_apache2() {
    print_header "Installing Apache2"
    wait_for_dpkg_lock
    print_step "Updating package list"
    sudo apt-get update -y 2>&1 | tee /root/apache2_install.log
    echo -e "${GREEN} Done!${RESET}"
    next_step
    
    print_step "Installing Apache2"
    sudo apt-get install apache2 -y 2>&1 | tee -a /root/apache2_install.log
    echo -e "${GREEN} Done!${RESET}"
    next_step

    if command_exists apache2; then
        echo -e "${GREEN}${BOLD}Apache2 successfully installed!${RESET}"
    else
        echo -e "${RED}${BOLD}Failed to install Apache2.${RESET}"
        echo -e "${YELLOW}${BOLD}Check the log file at /root/apache2_install.log for details.${RESET}"
        exit 1
    fi
}

install_phpmyadmin() {
    print_header "Installing phpMyAdmin"
    wait_for_dpkg_lock
    
    print_step "Configuring phpMyAdmin"
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password root" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
    echo -e "${GREEN} Done!${RESET}"
    next_step

    print_step "Installing phpMyAdmin"
    sudo apt-get install phpmyadmin -y 2>&1 | tee -a /root/phpmyadmin_install.log
    echo -e "${GREEN} Done!${RESET}"
    next_step
}

create_admin_account() {
    print_header "Creating phpMyAdmin Admin Account"
    
    PASSWORD=$(generate_password)
    USERNAME=$(generate_username)

    print_step "Creating MariaDB admin user"
    sudo mysql -e "CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$PASSWORD';" >/dev/null 2>&1
    echo -e "${GREEN} Done!${RESET}"
    next_step

    print_step "Granting privileges to admin user"
    sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'localhost' WITH GRANT OPTION;" >/dev/null 2>&1
    echo -e "${GREEN} Done!${RESET}"
    next_step

    print_step "Flushing privileges"
    sudo mysql -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
    echo -e "${GREEN} Done!${RESET}"
    next_step

    echo "phpMyAdmin Admin Account" > /root/php-data.txt
    echo "Username: $USERNAME" >> /root/php-data.txt
    echo "Password: $PASSWORD" >> /root/php-data.txt

    echo -e "${GREEN}${BOLD}Admin account created successfully!${RESET}"
    echo -e "${YELLOW}${BOLD}Credentials saved in /root/php-data.txt${RESET}"
}

install_fivem_with_txadmin() {
    local artifact_url="$1"

    print_header "Installing FiveM Server with txAdmin"

    mkdir -p /home/fivem/server
    cd /home/fivem/server

    wget "$artifact_url" -O fx.tar.xz
    tar xf fx.tar.xz

    rm fx.tar.xz

    DB_PASSWORD=$(generate_password)

    print_step "Creating FiveM database and user"
    sudo mysql -e "CREATE DATABASE fivem;" >/dev/null 2>&1
    sudo mysql -e "CREATE USER 'fivem'@'localhost' IDENTIFIED BY '$DB_PASSWORD';" >/dev/null 2>&1
    sudo mysql -e "GRANT ALL PRIVILEGES ON fivem.* TO 'fivem'@'localhost';" >/dev/null 2>&1
    sudo mysql -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
    echo -e "${GREEN} Done!${RESET}"
    next_step

    echo "FiveM Database Credentials" > /home/fivem/data.txt
    echo "Database: fivem" >> /home/fivem/data.txt
    echo "Username: fivem" >> /home/fivem/data.txt
    echo "Password: $DB_PASSWORD" >> /home/fivem/data.txt

    chmod +x run.sh
    echo -e "${YELLOW}${BOLD}FiveM Server mit txAdmin wurde installiert. Um den Server zu starten, verwenden Sie folgenden Befehl:${RESET}"
    echo -e "${CYAN}${BOLD}cd /home/fivem/server && ./run.sh +exec server.cfg +set txAdminPort 40120${RESET}"
    next_step
}

display_final_message() {
    clear
    echo -e "${CYAN}${BOLD}======================================${RESET}"
    echo -e "${GREEN}${BOLD}  Installation abgeschlossen!${RESET}"
    echo -e "${CYAN}${BOLD}======================================${RESET}"
    echo -e "${YELLOW}${BOLD}  Vielen Dank, dass Sie dieses Script verwendet haben.${RESET}"
    echo -e "${GREEN}${BOLD}  Credits:${RESET}"
    echo -e "${GREEN}${BOLD}    Entwicklung: Adrian${RESET}"
    echo -e "${GREEN}${BOLD}    Planung: Jonas${RESET}"
    echo -e "${GREEN}${BOLD}  Made by Astro-Service | Version 1.0.1${RESET}"
    echo -e "${YELLOW}${BOLD}  Join us on Discord: https://discord.gg/vsN2SGf2gZ${RESET}"
    echo -e "${CYAN}${BOLD}======================================${RESET}"
}

display_menu
display_final_message
