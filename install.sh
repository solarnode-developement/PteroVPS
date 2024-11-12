#!/bin/bash

PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

#############################
# Linux Installation #
#############################

# Define the root directory to /home/container.
# We can only write in /home/container and /tmp in the container.
ROOTFS_DIR=/home/container

export PATH=$PATH:~/.local/usr/bin

PROOT_VERSION="5.4.0"

# Detect the machine architecture.
ARCH=$(uname -m)

# Check machine architecture to make sure it is supported.
# If not, we exit with a non-zero status code.
if [ "$ARCH" = "x86_64" ]; then
    ARCH_ALT=amd64
    elif [ "$ARCH" = "aarch64" ]; then
    ARCH_ALT=arm64
    elif [ "$ARCH" = "riscv64" ]; then
    ARCH_ALT=riscv64
else
    printf "Unsupported CPU architecture: ${ARCH}"
    exit 1
fi

# Base mirror url
BASE_URL="https://images.linuxcontainers.org/images"

# Function to install a specific distro
install() {
    local distro_name="$1"
    local pretty_name="$2"
    local is_custom="$3"

    # Determine if it's a custom install  (Has more than one flavor for each version)
    # e.g musl, glibc for voidlinux
    if [[ "$is_custom" == "true" ]]; then
        # Fetch the directory listing and extract the image names
        image_names=$(curl -s "$BASE_URL/$distro_name/current/$ARCH_ALT/" | grep 'href="' | grep -o '"[^/"]*/"' | tr -d '"/' | grep -v '^\.\.$')
    else
        # Fetch the directory listing and extract the image names
        image_names=$(curl -s "$BASE_URL/$distro_name/" | grep 'href="' | grep -o '"[^/"]*/"' | tr -d '"/' | grep -v '^\.\.$')
    fi
    # Convert the space-separated string into an array
    set -- $image_names
    image_names=("$@")
    
    # Display the available versions
    for i in "${!image_names[@]}"; do
        echo "* [$((i + 1))] ${pretty_name} (${image_names[i]})"
    done
    
    # Enter the the desired version
    echo -e "${YELLOW}Enter the desired version (1-${#image_names[@]}): ${NC}"
    read -p "" version
    
    # Validate the input
    if [[ $version -lt 1 || $version -gt ${#image_names[@]} ]]; then
        echo -e "${RED}Invalid selection. Exiting.${NC}"
        exit 1
    fi
    
    # Get the selected version
    selected_version=${image_names[$((version - 1))]}
    echo -e "${GREEN}Installing $pretty_name (${selected_version})...${NC}"
    
    # Determine if it's a custom install to check whether your architecture is supported and obtain the URL accordingly 
    if [[ "$is_custom" == "true" ]]; then
        ARCH_URL="${BASE_URL}/${distro_name}/current/"
        URL="$BASE_URL/${distro_name}/current/$ARCH_ALT/$selected_version/"
    else
        ARCH_URL="${BASE_URL}/${distro_name}/${selected_version}/"
        URL="${BASE_URL}/${distro_name}/${selected_version}/${ARCH_ALT}/default/"
    fi

    # Check if the distro support $ARCH_ALT
    if ! curl -s "$ARCH_URL" | grep -q "$ARCH_ALT"; then
        echo -e "${RED}Error: This distro doesn't support $ARCH_ALT. Exiting.${NC}"
        exit 1
    fi

    # Fetch the latest version of the root filesystem
    LATEST_VERSION=$(curl -s "$URL" | grep 'href="' | grep -o '"[^/"]*/"' | tr -d '"' | sort -r | head -n 1)
    
    # Download and extract the root filesystem
    mkdir -p "$ROOTFS_DIR"
    curl -Ls "${URL}${LATEST_VERSION}/rootfs.tar.xz" -o "$ROOTFS_DIR/rootfs.tar.xz"
    tar -xf "$ROOTFS_DIR/rootfs.tar.xz" -C "$ROOTFS_DIR"
    mkdir -p "$ROOTFS_DIR/home/container/"
}

# Function to install a specific distro (custom) from a specific URL
install_custom() {
    local pretty_name="$1" 
    local URL="$2"   

    # Download and extract the root filesystem
    mkdir -p "$ROOTFS_DIR"

    # Get rootfs file name from URL
    FILE_NAME=$(basename "${URL}")
    # Print to screen what's currently installing
    echo -e "${GREEN}Installing $pretty_name ...${NC}"
    # Download the rootfs image to $ROOTFS_DIR
    curl -Ls "${URL}" -o "$ROOTFS_DIR/$FILE_NAME" || exit 1
    # Extract rootfs image to ROOTFS_DIR
    tar -xf "$ROOTFS_DIR/$FILE_NAME" -C "$ROOTFS_DIR"
    # Create ROOTFS_DIR/home/container/ dir
    mkdir -p "$ROOTFS_DIR/home/container/"

    # Check whether the OS is installed, then delete the rootfs image file
    if [ ! -e "$ROOTFS_DIR/.installed" ]; then
        rm $ROOTFS_DIR/$FILE_NAME
    fi
}

# Function to get Chimera Linux
get_chimera_linux() {
    local base_url="https://repo.chimera-linux.org/live/latest/"

    local latest_file=$(curl -s "$base_url" | grep -o "chimera-linux-$ARCH-ROOTFS-[0-9]\{8\}-bootstrap\.tar\.gz" | sort -V | tail -n 1)
    if [ -n "$latest_file" ]; then
        local date=$(echo "$latest_file" | grep -o '[0-9]\{8\}')
        echo "${base_url}chimera-linux-$ARCH-ROOTFS-$date-bootstrap.tar.gz"
    else
        exit 1
    fi
}

# Download & decompress the Linux root file system if not already installed.
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    
    # Clear the terminal
    printf "\033c"
    
    # Display the menu
    echo -e "${GREEN}=============================${NC}"
    echo -e "${GREEN}Welcome to PteroVPS 2024!${NC}"
    echo -e "${GREEN}To begin installation, select a preferred distro.${NC}"
    echo -e "${GREEN}=============================${NC}"
    echo "* [1] Debian                                                                                   "
    echo "* [2] Ubuntu                                                                                   "
    echo "* [3] Void Linux                                                                               "
    echo "* [4] Alpine Linux                                                                             "
    echo "* [5] CentOS                                                                                   "
    echo "* [6] Rocky Linux                                                                              "
    echo "* [7] Fedora                                                                                   "
    echo "* [8] AlmaLinux                                                                                "
    echo "* [9] Slackware Linux                                                                          "
    echo "* [10] Kali Linux                                                                              "
    echo "* [11] openSUSE                                                                                "
    echo "* [12] Gentoo Linux                                                                            "
    echo "* [13] Arch Linux                                                                              "
    echo "* [14] Devuan Linux                                                                            "
    echo "* [15] Chimera Linux                                                                           "
    echo "                                                                                               "
    echo -e "${YELLOW}Enter OS (1-14):                                                                 ${NC}"
    
    read -p "" input
    
    case $input in
        
        1)
            install             "debian"        "Debian"
        ;;
        
        2)
            install             "ubuntu"        "Ubuntu"
        ;;
        
        3)
            install             "voidlinux"     "Void Linux"         "true"
        ;;
        
        4)
            install             "alpine"        "Alpine Linux"
        ;;
        
        5)
            install             "centos"        "CentOS"
        ;;
        
        6)
            install             "rockylinux"    "Rocky Linux"
        ;;
        
        7)
            install             "fedora"        "Fedora"
        ;;
        
        8)
            install             "almalinux"     "Alma Linux"
        ;;
        
        9)
            install             "slackware"     "Slackware"
        ;;
        
        
        10)
            install             "kali"          "Kali Linux"
        ;;
        
        11)
            install             "opensuse"      "openSUSE"
        ;;
        
        12)
            install             "gentoo"        "Gentoo Linux"         "true"
        ;;
        
        13)
            install             "archlinux"     "Arch Linux"
            
            # Fix pacman
            sed -i '/^#RootDir/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
            sed -i 's|/var/lib/pacman/|/var/lib/pacman|' "$ROOTFS_DIR/etc/pacman.conf"
            sed -i '/^#DBPath/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
        ;;
        
        14)
            install             "devuan"        "Devuan Linux"
        ;;

        15)
            install_custom      "Chimera Linux"        $(get_chimera_linux)
        ;;

        ## An example of the usage of the install_custom function
        # 16)
        #     install_custom      "Debian"        "https://github.com/JuliaCI/rootfs-images/releases/download/v7.10/debian_minimal.aarch64.tar.gz"
        # ;;

        *)
            echo -e "${RED}Invalid selection. Exiting.${NC}"
            exit 1
        ;;
    esac
fi

################################
# Package Installation & Setup #
#################################

# Download static proot.
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    # Create "$ROOTFS_DIR/usr/local/bin" dir
    mkdir -p "$ROOTFS_DIR/usr/local/bin"
    # Download static proot.
    curl -Ls "https://github.com/ysdragon/proot-static/releases/download/v${PROOT_VERSION}/proot-${ARCH}-static" -o "$ROOTFS_DIR/usr/local/bin/proot"
    # Make PRoot executable.
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
fi

# Clean-up after installation complete & finish up.
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    # Add DNS Resolver nameservers to resolv.conf.
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
    # Wipe the files we downloaded into /tmp previously.
    rm -rf $ROOTFS_DIR/rootfs.tar.xz /tmp/sbin
    # Create .installed to later check whether OS is installed.
    touch "$ROOTFS_DIR/.installed"
fi

###########################
# Start PRoot environment #
###########################

# Get all ports from vps.config
port_args=""
while read line; do
    case "$line" in
        internalip=*) ;;
        port[0-9]*=*) port=${line#*=}; if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi;;
        port=*) port=${line#*=}; if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi;;
    esac
done < "$ROOTFS_DIR/vps.config"

# This command starts PRoot and binds several important directories
# from the host file system to our special root file system.
"$ROOTFS_DIR/usr/local/bin/proot" \
--rootfs="${ROOTFS_DIR}" \
-0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf $port_args --kill-on-exit \
/bin/sh "/run.sh"
