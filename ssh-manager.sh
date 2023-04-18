
readonly KNOWN_HOSTS="$HOME/.ssh/known_hosts"
readonly CONFIG_DIR="$HOME/.sshmanager"

# Exit Code
readonly FILE_NOT_EXISTS=1
readonly PERMISSION_ERROR=2
readonly UNKNOWN_ERROR=125
readonly SUCCESS=0

# Color codes
readonly RED="\e[1;31m"
readonly GREEN="\e[1;32m"
readonly YELLOW="\e[1;33m"
readonly PLANE="\e[0m"


PrintBanner() {
    echo -e $YELLOW

    clear ; cat << EOF
      █████████ █████████ █████   █████    ██████   ██████                                                    
 ███░░░░░█████░░░░░██░░███   ░░███    ░░██████ ██████                                                     
░███    ░░░███    ░░░ ░███    ░███     ░███░█████░███  ██████ ████████   ██████   ███████ ██████ ████████ 
░░████████░░█████████ ░███████████     ░███░░███ ░███ ░░░░░██░░███░░███ ░░░░░███ ███░░██████░░██░░███░░███
 ░░░░░░░░██░░░░░░░░███░███░░░░░███     ░███ ░░░  ░███  ███████░███ ░███  ███████░███ ░██░███████ ░███ ░░░ 
 ███    ░█████    ░███░███    ░███     ░███      ░███ ███░░███░███ ░███ ███░░███░███ ░██░███░░░  ░███     
░░████████░░█████████ █████   █████    █████     ████░░███████████ ████░░███████░░██████░░██████ █████    
 ░░░░░░░░░ ░░░░░░░░░ ░░░░░   ░░░░░    ░░░░░     ░░░░░ ░░░░░░░░░░░ ░░░░░ ░░░░░░░░ ░░░░░███░░░░░░ ░░░░░     
                                                                                 ███ ░███                 
                                                                                ░░██████                  
                                                                                 ░░░░░░   
EOF

echo -e $PLANE
}

InfoMenu() {
    local CREATOR="Organ13at0r"
    local GIT_REPOSITORY="https://github.com/Organ13at0r/ssh-manager.git"
    local VERSION="0.1.0"

    PrintBanner

    printf "%bCreator:%b %s\n" $GREEN $PLANE $CREATOR
    printf "%bGit:%b %s\n" $GREEN $PLANE $GIT_REPOSITORY
    printf "%bVersion:%b %s\n\n" $GREEN $PLANE $VERSION

    read -n1 -p "Press any key to continue..." && MainMenu
}

# [Working with hosts]
HostsMenu() {
    local ENTRY_MENU_LINE=("List" "Add" "Delete" "Ping" "Connect" "Copy-File-To" "Copy-File-From" "Set-Secure-SSHD" "Quit")
    local PS3="SSH Manager/Hosts >> "

    PrintBanner

    select USER_CHOOSE in ${ENTRY_MENU_LINE[@]}; do
        case "$REPLY" in
            [Ll]ist             | [Ll]   | 1 ) GetHosts ;;
            [Aa]dd              | [Aa]   | 2 ) : ;;
            [Dd]elete           | [Dd]   | 3 ) : ;;
            [Pp]ing             | [Pp]   | 4 ) PingHost ;;
            [Cc]onnect          | [Cc]   | 5 ) ConnectToHost ;;
            [Cc]opy-file-to              | 6 ) : ;;
            [Cc]opy-file-from            | 7 ) : ;;
            [Ss]et-secure-sshd  | [Ss]   | 8 ) : ;;
            [Qq]uit             | [Qq]   | 9 ) clear ; MainMenu ;;
            *                                ) printf "%s\n" "$REPLY: does not exist. Try again." ;;
        esac
    done
}

GetHosts() {
    
    if [[ -e $KNOWN_HOSTS ]]; then  # Check if file exists.
        if [[ -r $KNOWN_HOSTS ]]; then  # Check if file has read permission.
            for HOST in $(cat $KNOWN_HOSTS | awk '{print $1}' | uniq); do
                printf "Host: %s\n" $HOST
            done
        else
            printf "%bError:%b PERMISSION_ERROR\n" $RED $PLANE ; exit $PERMISSION_ERROR
        fi
    else
        printf "%bError:%b FILE_NOT_EXISTS\n" $RED $PLANE ; exit $FILE_NOT_EXISTS
    fi 
    
}

PingHost() {
    local HOST=:
    local PACKAGE_COUNT=5

    until [[ $HOST =~ ^([0-9]{1,3}\.){3}|[Ll]ist ]]; do
        read -rep "Type any host or type [list] to see available hosts in your config: " HOST
    done

    [[ $HOST =~ [Ll]ist ]] && GetHosts && PingHost  # See available hosts in user's config

    if ping -c $PACKAGE_COUNT $HOST &> /dev/null; then
        printf "[%s] %b- available%b\n" $HOST $GREEN $PLANE
    else 
        printf "[%s] %b- not available%b\n" $HOST $RED $PLANE
    fi
}

ConnectToHost() {
    local PORT=:
    local HOST=:
    local USERNAME=:
    
    until [[ $HOST =~ ^([0-9]{1,3}\.){3}|[Ll]ist ]]; do
        read -rep "Type any host or type [list] to see available hosts in your config: " HOST

        [[ $HOST =~ [Ll]ist ]] && GetHosts && ConnectToHost  # See available hosts in user's config
    done

    if ls -l $CONFIG_DIR | grep $HOST &> /dev/null; then    # If host config exists then loading it
        LoadConfig $HOST
    fi

    until [[ $PORT =~ ^[0-9]+$ ]] && [[ $PORT -ge 1 ]] && [[ $PORT -le 65535 ]]; do
        read -rep "Type server's port: " PORT
    done

    until [[ $USERNAME =~ ^[a-zA-Z0-9]+$ ]]; do
        read -rp "Type an username: " -e -i $(whoami) USERNAME
    done

    echo -e "Host: $HOST\nPort: $PORT\nUsername: $USERNAME" | base64 > "${CONFIG_DIR}/$HOST.conf" # Create config

    ssh ${USERNAME}@${HOST} -p $PORT && exit $SUCCESS || printf "Something has been wrong" && exit $UNKNOWN_ERROR
}

LoadConfig() {
    local HOST="$1"
    local PORT=:
    local USERNAME=:

    PORT=$(cat "${CONFIG_DIR}/${HOST}.conf" | base64 -d | grep Port | awk '{print $2}')
    USERNAME=$(cat "${CONFIG_DIR}/${HOST}.conf" | base64 -d | grep Username | awk '{print $2}')

    ssh ${USERNAME}@${HOST} -p $PORT && exit $SUCCESS || printf "Something has been wrong" && exit $UNKNOWN_ERROR
}
# -----------------------------------------------------------

InitUserSpace() {
    local SLEEP_TIME=2

    [[ -e $CONFIG_DIR ]] || {
        printf "%b[INITIALISATION]%b\n" $YELLOW $PLANE ; sleep $SLEEP_TIME
        printf "%bCreating config directory...%b [%s]\n\n" $YELLOW $PLANE $CONFIG_DIR ; sleep $SLEEP_TIME
        mkdir $CONFIG_DIR

        read -n1 -p "Press any key to continue..."
    }
}

MainMenu() {
    local ENTRY_MENU_LINE=("Hosts" "Info" "Quit")
    local SLEEP=1
    local PS3="SSH Manager >> "

    PrintBanner

    select USER_CHOOSE in ${ENTRY_MENU_LINE[@]}; do
        case "$REPLY" in
            [Hh]osts | [Hh] | 1  ) clear ; HostsMenu ;;
            [Ii]nfo  | [Ii] | 2  ) clear ; InfoMenu ;;
            [Qq]uit  | [Qq] | 3  ) printf "\n%bExiting...%b\n" $YELLOW $PLANE ; sleep $SLEEP ; exit $SUCCESS ;;
            *                    ) printf "%s\n" "$REPLY: does not exist. Try again." ;; 
        esac
    done
}

InitUserSpace

# [BAR]
printf "\n["
for _ in {1..100}; do
    printf "#" ; sleep 0.001
done ; printf "]\n" ; sleep 0.5
#-------------------------------------

MainMenu