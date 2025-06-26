#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'         # Error
YELLOW='\033[0;33m'       # Warning
DEEP_GREEN='\033[0;32m'   # Success
HGREEN='\033[0;36m' # Runtime/Info (using a shade of cyan for "hacker green")
NC='\033[0m'             # No Color

# --- Variables ---
DOCKER_COMPOSE_FILE="docker-compose.yaml"

# --- Functions ---

MrXintro() {
    echo ""

    echo -e "${BOLD}${HGREEN}"    
    echo "███╗   ███╗██████╗        ██╗  ██╗"
    echo "████╗ ████║██╔══██╗       ╚██╗██╔╝"
    echo "██╔████╔██║██████╔╝        ╚███╔╝ "
    echo "██║╚██╔╝██║██╔══██╗        ██╔██╗ "
    echo "██║ ╚═╝ ██║██║  ██║██╗    ██╔╝ ██╗"
    echo "╚═╝     ╚═╝╚═╝  ╚═╝╚═╝    ╚═╝  ╚═╝"
                                  
    echo "                 Github: http://github.com/iamxlord"
    echo -e "                 Twitter: http://x.com/iamxlord${NC}"
    echo ""
}

# check_sudo_privileges: Checks for sudo access
check_sudo_privileges() {
    if ! sudo -n true 2>/dev/null; then
        echo -e "${RED}SUDO (elevated sudo privilege not authorized on your device;)${NC}"
        echo -e "${RED}Please ensure you have sudo privileges and try again.${NC}"
        exit 1
    fi
}

# check_docker_installed: Checks if Docker is installed and working
check_docker_installed() {
    echo -e "${HGREEN}>>> Checking Docker installation...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker is not installed.${NC}"
        install_docker
    else
        if ! sudo docker run hello-world &> /dev/null; then
            echo -e "${YELLOW}Docker is installed but not configured correctly or user is not in 'docker' group.${NC}"
            echo -e "${YELLOW}Attempting to add current user to 'docker' group and re-test...${NC}"
            sudo usermod -aG docker "$USER"
            echo -e "${YELLOW}Please log out and log back in for group changes to take effect, then re-run the script.${NC}"
            exit 1
        fi
        echo -e "${DEEP_GREEN}Docker is installed and running correctly!${NC}"
    fi
}

# install_docker: Installs Docker
install_docker() {
    echo -e "${HGREEN}>>> Attempting to install Docker...${NC}"
    sudo apt-get update -y
    sudo apt-get install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    if [ $? -eq 0 ]; then
        echo -e "${DEEP_GREEN}Docker installed successfully!${NC}"
        echo -e "${DEEP_GREEN}Adding current user to 'docker' group for seamless operation...${NC}"
        sudo usermod -aG docker "$USER"
        echo -e "${YELLOW}Please log out and log back in for group changes to take effect, then re-run the script.${NC}"
        exit 0 # Exit, as the user needs to re-login
    else
        echo -e "${RED}Failed to install Docker.${NC}"
        echo -e "${RED}Please check your internet connection or try installing Docker manually.${NC}"
        exit 1
    fi
}

# start_blockcast_containers: Starts Blockcast containers using docker compose
start_blockcast_containers() {
    echo -e "${HGREEN}BOOTING ${RED}✘${NC}.... ${NC}"
    echo -e "${HGREEN}starting Blockcast Node ${RED}✘${NC}"
    sudo docker compose -f "$DOCKER_COMPOSE_FILE" up -d

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to start Blockcast containers. Please check your '$DOCKER_COMPOSE_FILE' and Docker logs.${NC}"
        exit 1
    fi

    sleep 1
    echo -e "${HGREEN}>>> Checking container status...${NC}"
    sudo docker compose -f "$DOCKER_COMPOSE_FILE" ps

    # Wait a few seconds to ensure services are up
    sleep 5

    # Initialize and fetch Hardware ID + Challenge Key
    echo -e "${HGREEN}>>> Initializing node to get Hardware ID & Challenge Key...${NC}"
    sudo docker compose -f "$DOCKER_COMPOSE_FILE" exec blockcastd blockcastd init

    echo ""
    echo -e "${DEEP_GREEN}>>> DONE! Now follow the next steps:${NC}"
    echo -e "${DEEP_GREEN}1. Copy your Hardware ID, Challenge Key, and Registration URL${NC}"
    echo -e "${DEEP_GREEN}2. Visit: ${HGREEN}https://app.blockcast.network?referral-code=F3bqfr${NC}"
    echo -e "${DEEP_GREEN}3. Paste your Registration URL or manually register your node.${NC}"
    echo -e "${DEEP_GREEN}4. Leave your node running 24/7 to earn rewards!${NC}"
    echo ""
    echo -e "${HGREEN}>>> TIP: Backup your private key:${NC}"
    echo -e "${HGREEN}cat ~/.blockcast/certs/gw_challenge.key${NC}"
    echo ""
}

# --- Main Script Execution ---

MrXintro             # Call the custom introduction
check_sudo_privileges # Check for sudo rights
check_docker_installed # Check and potentially install Docker
start_blockcast_containers # Start the Blockcast containers
