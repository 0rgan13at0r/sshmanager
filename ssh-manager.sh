
readonly KNOWN_HOSTS="$HOME/.ssh/known_hosts"
readonly CONFIG_DIR="$HOME/.sshmanager"

# Exit codes
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
            [Aa]dd              | [Aa]   | 2 ) clear ; AddHost ;;
            [Dd]elete           | [Dd]   | 3 ) DeleteHost ;;
            [Pp]ing             | [Pp]   | 4 ) PingHost ;;
            [Cc]onnect          | [Cc]   | 5 ) ConnectToHost ;;
            [Cc]opy-file-to              | 6 ) clear ; CopyFile --to ;;
            [Cc]opy-file-from            | 7 ) clear ; CopyFile --from ;;
            [Ss]et-secure-sshd  | [Ss]   | 8 ) SetSecureSSHD ;;
            [Qq]uit             | [Qq]   | 9 ) clear ; MainMenu ;;
            *                                ) printf "%s\n" "$REPLY: does not exist. Try again." ;;
        esac
    done
}

AddHost() {
    local KEYNAME=:
    local BITS=:
    local KEYTYPE="rsa"

    PrintBanner

    until [[ $KEYNAME =~ ^[a-zA-Z0-9\-]+$ ]]; do
        read -rep "Enter a key-file name: " KEYNAME
    done

    KEYNAME="$HOME/.ssh/$KEYNAME"

    until [[ $BITS =~ ^(1024|2048|3072|4096)$ ]]; do
        read -rep "Enter a key-size in bits [1024,2048,3072,4096]: " BITS
    done

    echo -e $GREEN
        ssh-keygen -t $KEYTYPE -b $BITS -P "" -f $KEYNAME
    echo -e $PLANE
}

DeleteHost() {
    :
}

CopyFile() {
    local HOST=:
    local PORT=:
    local USERNAME=:
    local FILE_SOURCE=:
    local FILE_DESTINATION=:

    until [[ $HOST =~ ^([0-9]{1,3}\.){3}|[Ll]ist ]]; do
        read -rep "Type any host or type [list] to see available hosts in your config: " HOST

        [[ $HOST =~ [Ll]ist ]] && GetHosts && CopyFile $1 # See available hosts in user's config
    done

    GetFileMetadata

    TryLoadConfig $HOST && {
        if [[ "$1" == "--from" ]]; then
            scp -P $PORT ${USERNAME}@${HOST}:${FILE_SOURCE} $FILE_DESTINATION && HostsMenu || echo "File not found" && exit $FILE_NOT_EXISTS
        else
            scp -P $PORT $FILE_SOURCE ${USERNAME}@${HOST}:${FILE_DESTINATION} && HostsMenu || echo "File not found" && exit $FILE_NOT_EXISTS
        fi
    }

    GetHostAdditionalInfo

    echo -e "Host: $HOST\nPort: $PORT\nUsername: $USERNAME" | base64 > "${CONFIG_DIR}/$HOST.conf" # Create config
    
    if [[ "$1" == "--from" ]]; then
            scp -P $PORT ${USERNAME}@${HOST}:${FILE_SOURCE} $FILE_DESTINATION && HostsMenu
    else
        scp -P $PORT $FILE_SOURCE ${USERNAME}@${HOST}:${FILE_DESTINATION} && HostsMenu
    fi
}

GetFileMetadata() {
    read -rep "Enter a source of file: " FILE_SOURCE
    read -rep "Enter a destination of file: " FILE_DESTINATION
}

SetSecureSSHD() {
    :
}

GetHosts() {
    CheckKNOWN_HOST
    
    for HOST in $(cat $KNOWN_HOSTS | awk '{print $1}' | uniq); do
        printf "Host: %s\n" $HOST
    done
}

CheckKNOWN_HOST() {
    [[ -e $KNOWN_HOSTS ]] || {  # Check if file does exist
        printf "%bError:%b %s does not exist\n" $RED $PLANE $KNOWN_HOSTS && exit $FILE_NOT_EXISTS
    }

    [[ -r $KNOWN_HOSTS ]] || {  # Check if file has the read-perm
        printf "%bError:%b %s does not have the read permission\n" $RED $PLANE $KNOWN_HOSTS && exit $PERMISSION_ERROR
    }
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

    TryLoadConfig $HOST && {
        ssh ${USERNAME}@${HOST} -p $PORT && exit $SUCCESS || printf "Something has been wrong" && exit $UNKNOWN_ERROR
    }

    GetHostAdditionalInfo

    echo -e "Host: $HOST\nPort: $PORT\nUsername: $USERNAME" | base64 > "${CONFIG_DIR}/$HOST.conf" # Create config
    ssh ${USERNAME}@${HOST} -p $PORT && exit $SUCCESS || printf "Something has been wrong" && exit $UNKNOWN_ERROR
}

GetHostAdditionalInfo() {
    until [[ $PORT =~ ^[0-9]+$ ]] && [[ $PORT -ge 1 ]] && [[ $PORT -le 65535 ]]; do
        read -rep "Type server's port: " PORT
    done

    until [[ $USERNAME =~ ^[a-zA-Z0-9]+$ ]]; do
        read -rp "Type an username: " -e -i $(whoami) USERNAME
    done
}

TryLoadConfig() {
    HOST="$1"

    ls -l $CONFIG_DIR | grep $HOST &> /dev/null && {
        PORT=$(cat "${CONFIG_DIR}/${HOST}.conf" | base64 -d | grep Port | awk '{print $2}')
        USERNAME=$(cat "${CONFIG_DIR}/${HOST}.conf" | base64 -d | grep Username | awk '{print $2}')
    }
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

# --------------------MAIN POINT---------------------
InitUserSpace

# [BAR]
printf "\n["
for _ in {1..100}; do
    printf "#" ; sleep 0.001
done ; printf "]\n" ; sleep 0.5
#-------------------------------------

MainMenu
# ---------------------------------------------------