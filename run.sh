#!/bin/sh

PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

printf "\033c"
printf "${GREEN}[PteroVPS] Starting Up..${NC}\n"
sleep 1
printf "\033c"

DIR=$PWD # get current dir
# if current dir is /root print ~
if [ "$PWD" = "/root"* ]; then
    DIR="~${PWD#/root}"
fi

printf "\033c"
printf "${GREEN}=============================${NC}"
printf "${GREEN}Welcome to PteroVPS 2024!${NC}"
printf "${GREEN}You are up-to-date running 1.0.${NC}"
printf "${GREEN}Developed by solarnode | forked @ ysdragon${NC}"
printf "${GREEN}=============================${NC}"
sleep 1
printf "${GREEN}=============================${NC}"
printf "${GREEN}Status: Active${NC}"
printf "${GREEN}=============================${NC}"
printf "                                                                                               \n"
printf "root@MyVPS:${DIR}#                                                                             \n"                                                                             

run_cmd() {
    read -p "root@MyVPS:$DIR# " CMD
    eval "$CMD"
    
    # Update DIR after executing command
    DIR=$PWD
    if [ "$PWD" = "/root"* ]; then
        DIR="~${PWD#/root}"
    fi
    
    printf "root@MyVPS:$DIR# \n"
    run_user_cmd
}

run_user_cmd() {
    read -p "user@MyVPS:$DIR# " CMD2
    eval "$CMD2"
    
    # Update DIR after executing command
    DIR=$PWD
    if [ "$PWD" = "/root"* ]; then
        DIR="~${PWD#/root}"
    fi
    
    printf "root@MyVPS:$DIR# \n"
    run_cmd
}

run_cmd
