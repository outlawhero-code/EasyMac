#!/bin/bash

# Color definitions
RED='\033[0;31m' # bad
GREEN='\033[0;32m' # good
YELLOW='\033[0;33m' # warning
BLUE='\033[0;34m' # info
NC='\033[0m' # No Color

# Function to check if script requires sudo
check_permissions() {
    local action=$1
    local prompt=$2
    local expected_result=$3

    echo -e "${BLUE}Checking permissions for ${prompt}${NC}"
    
    if [ "$expected_result" == "sudo" ]; then
        echo -e "${BLUE}Script requires sudo privileges${NC}"
        echo -e "${YELLOW}Please enter your password when prompted:${NC}"
        return 0
    fi
}

# Function to handle sudo prompts
handle_sudo() {
    local action=$1
    local prompt=$2
    local expected_result=$3
    local user_input=$4

    if [ "$expected_result" == "sudo" ]; then
        echo -e "${BLUE}Running sudo command for ${prompt}${NC}"
        sudo $action
        return 0
    fi
}

# Function to display error messages
display_error() {
    local error_message=$1
    echo -e "${RED}Error: ${error_message}${NC}"
}

# Function to display success messages
display_success() {
    local success_message=$1
    echo -e "${GREEN}Success: ${success_message}${NC}"
}

# Option 1 - Function to uninstall Papercut
uninstall_papercut() {
    local success=false
    local error=false
    local prompt="Uninstall Papercut"

    if [ -d "/Applications/PaperCut Print Deploy Client/" ]; then
        check_permissions "sudo /Applications/PaperCut Print Deploy Client/Uninstall.command" "$prompt" "sudo"
        handle_sudo "sudo /Applications/PaperCut Print Deploy Client/Uninstall.command" "$prompt" "sudo" ""
        success=true
    else
        display_error "PaperCut Print Deploy Client not installed"
        error=true
    fi

    if [! "$success" ]; then
        display_error "Failed to uninstall Papercut"
        return 1
    fi

    display_success "Uninstall complete"
    return 0
}

# Option 2 - Function to rename device based on serial
rename_device() {
    local success=false
    local error=false
    local prompt="Rename the Mac"

    echo -e "${BLUE}Current hostname: ${BLUE}$(hostname)${NC}"
    read -p "Would you like to rename this machine? " confirm_rename

    if [[ "$confirm_rename" == "yes" ]]; then
        echo ""
        read -p "What prefix would you like to have before the serial number? " prefix
        SERIAL=$(ioreg -l | grep IOPlatformSerialNumber | awk '{print $4}' | sed '/"//g')

        if [ -n "$prefix" ]; then
            echo "Currently renaming the Mac to $prefix-$SERIAL"
            check_permissions "sudo scutil --set ComputerName \"$prefix-$SERIAL\"" "$prompt" "sudo"
            handle_sudo "sudo scutil --set ComputerName \"$prefix-$SERIAL\"" "$prompt" "sudo" ""
            handle_sudo "sudo scutil --set LocalHostName \"$prefix-$SERIAL\"" "$prompt" "sudo" ""
            handle_sudo "sudo scutil --set HostName \"$prefix-$SERIAL\"" "$prompt" "sudo" ""
            success=true
        else
            display_error "Invalid prefix"
            error=true
        fi
    else
        display_error "Renaming cancelled"
        error=true
    fi

    if [! "$success" ]; then

        display_error "Failed to rename device"
        return 1
    fi

    display_success "Rename complete"
    return 0
}

# Option 3 - Function to check boot currently logged in users
user_inquiry() {
    local success=false
    local error=false
    local prompt="Check and boot active users"

    echo "The users currently logged into this system are: "
    who
    echo ""

    read -p "Would you like boot anyone from the system? (yes/no): " confirm

    if [[ "$confirm" == "yes" ]]; then
        read -p "Who would you like to boot? " bootuser

        if [ -n "$bootuser" ]; then
            check_permissions "sudo pkill -9 -u $bootuser" "$prompt" "sudo"
            handle_sudo "sudo pkill -9 -u $bootuser" "$prompt" "sudo" ""
            sleep 1
            handle_sudo "sudo pkill -9 -u $bootuser" "$prompt" "sudo" ""
            success=true
        else
            display_error "Invalid user"
            error=true
        fi
    else
        display_error "User inquiry cancelled"
        error=true
    fi

    if [! "$success" ]; then
        display_error "Failed to check and boot users"
        return 1
    fi

    display_success "User inquiry complete"
    return 0
}

# Option 4 - Function to change a users password
change_password() {
    local success=false
    local error=false
    local prompt="Change a user's password"

    echo "These are all the user accounts on the system: "
    dscl. list /Users | grep -v "^_"
    echo ""

    echo -e "You are currently logged in as: ${BLUE}$(whoami)${NC}"
    echo ""

    read -p "Which user's password do you want to change? " changepw

    if [ -n "$changepw" ]; then
        echo ""

        if dscl. list /Users | grep -v "^_" | grep -q "^${changepw}$"; then
            echo -e "You are intending to change the password for user: ${BLUE}$changepw${NC}"
            read -p "Please confirm this process? (yes/no): " confirm

            if [[ "$confirm" == "yes" ]]; then
                handle_sudo "/usr/bin/pwpolicy -a $(whoami) -u $changepw -setpassword" "$prompt" "sudo" ""
                success=true
            else
                display_error "Password change cancelled"
                error=true
            fi
        else
            display_error "User not found"
            error=true
        fi
    else
        display_error "Invalid user"
        error=true
    fi

    if [! "$success" ]; then
        display_error "Failed to change password"
        return 1
    fi

    display_success "Password change complete"
    return 0
}

# Option 5 - Delete a user's account
delete_account() {
    local success=false
    local error=false
    local prompt="Delete a specific user account"

    dscl. list /Users | grep -v "^_"
    read -p "What user account would you like to delete? " deleteuser

    echo ""

    if [ -n "$deleteuser" ]; then
        echo -e "You are intending to delete the account for ${BLUE}$deleteuser${NC}"
        read -p "Please confirm this process? (yes/no): " confirm

        if [[ "$confirm" == "yes" ]]; then
            handle_sudo "sudo sysadminctl -deleteUser \"$deleteuser\"" "$prompt" "sudo" ""
            success=true
        else
            display_error "Account deletion cancelled"
            error=true
        fi
    else
        display_error "Invalid user"
        error=true
    fi

    if [! "$success" ]; then
        display_error "Failed to delete account"
        return 1
    fi

    display_success "Account deletion complete"
    return 0
}

# Option 6 - Create a user account with local admin rights
create_account() {
    local success=false
    local error=false
    local prompt="Create a user account with local admin rights"

    echo "You are intending to create a user account with local admin rights."
    echo ""

    read -p "What is the username? " username
    read -p "What is the user's first name? (case sensitive) " firstname
    read -p "What is the user's last name? (case sensitive) " lastname
    read -p "What password would you like to use? " password

    if [ -n "$username" ] && [ -n "$firstname" ] && [ -n "$lastname" ] && [ -n "$password" ]; then
        echo ""

        if dscl. list /Users | grep -v "^_" | grep -q "^${username}$"; then
            echo ""

            if dscl. list /Users | grep -v "^_" | grep -q "^${firstname}$"; then
                echo ""

                if dscl. list /Users | grep -v "^_" | grep -q "^${lastname}$"; then
                    echo "User account created successfully."
                    success=true
                else
                    display_error "Last name not found"
                    error=true
                fi
            else
                display_error "First name not found"
                error=true
            fi
        else
            display_error "Username not found"
            error=true
        fi
    else
        display_error "Invalid input"
        error=true
    fi

    if [! "$success" ]; then
        display_error "Failed to create user account"
        return 1
    fi

    display_success "User account created successfully"
    return 0
}

# Option 7 - Prune Inactive User Accounts
prune_users() {
    local success=false
    local error=false
    local prompt="Prune Inactive User Accounts"

    echo "========================================"
    echo "     Pruning Inactive User Accounts"
    echo "========================================"
    echo ""

    # List of users to exclude from deletion
    EXCLUDE_USERS=("Atlas" "berklgre" "daemon" "nobody" "root" "Support")

    # Date 30 days ago in epoch time
    THIRTY_DAYS_AGO=$(date -v-30d +%s)

    # Temporary file to store users to delete
    TEMP_FILE=$(mktemp)

    # Get all non-system users
    while read user; do
        # Check if user is in exclusion list
        if [[ " ${EXCLUDE_USERS[@]} " =~ " ${user} " ]]; then
            continue
        fi
        
        # Get last login info
        last_login=$(last -1 "$user" | head -1 | grep -v 'wtmp begins')

        # Check if user never logged in
        if [[ -z "$last_login" ]]; then
            echo "Will delete: $user - Never logged in"
            echo "$user" >> "$TEMP_FILE"
            continue
        fi
        
        # Extract the login date from last command output
        login_date=$(echo "$last_login" | awk '{print $4, $5, $6}')

        # Check if login shows "still logged in" - these are recent
        if echo "$last_login" | grep -q "still logged in"; then
            continue
        fi
        
        # Convert login date to epoch time
        login_epoch=$(date -j -f "%b %d %H:%M" "$login_date" +%s 2>/dev/null)

        # If date conversion failed, skip this user
        if [[ -z "$login_epoch" ]]; then
            continue
        fi
        
        # Check if last login was more than 30 days ago
        if [[ $login_epoch -lt $THIRTY_DAYS_AGO ]]; then
            echo "Will delete: $user - Last login: $login_date"
            echo "$user" >> "$TEMP_FILE"
        fi
    done< <(dscl. list /Users | grep -v '^_')

    # Display summary
    echo ""
    echo "Users to be deleted:"
    echo "--------------------"

    if [[ -s "$TEMP_FILE" ]]; then
        cat "$TEMP_FILE" | while read user; do
            echo "  - $user"
        done
        
        echo ""
        read -p "Do you want to proceed with deleting these users? (yes/no): " confirm

        if [[ "$confirm" == "yes" ]]; then
            while read user; do
                echo "Deleting user: $user"
                sudo sysadminctl -deleteUser "$user"
            done< "$TEMP_FILE"
            echo -e "${GREEN}User deletion complete!${NC}"
        elif [[ "$confirm" == "no" ]]; then
            echo -e "${YELLOW}(No users to delete)${NC}"
        else
            echo -e "${RED}Invalid response, operation cancelled.${NC}"
        fi
    else
        echo -e "${YELLOW}(No users to delete)${NC}"
    fi

    # Clean up temp file
    rm "$TEMP_FILE"
    echo ""
}

# Option 8 - Function to check FileVault encryption status
check_filevault() {
    local success=false
    local error=false
    local prompt="Check FileVault Encryption Status"

    echo "========================================"
    echo "  Checking FileVault Encryption Status"
    echo "========================================"
    echo ""

    # Check if FileVault is enabled
    FV_STATUS=$(fdesetup status)

    # Check if FileVault is On
    if echo "$FV_STATUS" | grep -q "FileVault is On"; then
        echo ""
        echo -e "${BLUE}FileVault is enabled on this machine.${NC}"
        echo ""

        read -p "Do you want disable Filevault and its notifications? (yes/no): " confirm

        if [[ "$confirm" == "yes" ]]; then
            echo "Disabling FileVault..."
            sudo fdesetup disable
            echo "Disabling FileVault setup notification prompts..."
            sudo defaults write /Library/Preferences/com.apple.MCXNotifications.plist FileVaultSetup -bool FALSE
            killall NotificationCenter 2>/dev/null || true
            echo ""
            echo -e "${GREEN}FileVault and its notification prompts have been disabled.${NC}"
            echo ""
        elif [[ "$confirm" == "no" ]]; then
            echo -e "You have chosen ${BLUE}NOT${NC} to disable FileVault and its notification prompts."
        else
            echo -e "${RED}Invalid response. No changes made.${NC}"
        fi
    elif echo "$FV_STATUS" | grep -q "FileVault is Off"; then
        echo ""
        echo -e "${GREEN}FileVault is NOT enabled. Disk is not encrypted.${NC}"
        echo ""
        sudo defaults write /Library/Preferences/com.apple.MCXNotifications.plist FileVaultSetup -bool FALSE
        killall NotificationCenter 2>/dev/null || true
        echo -e "${GREEN}FileVault notification prompts have been disabled.${NC}"
        echo ""
    fi
}

# Option 9 - Function to check for macOS updates
check_updates() {
    local success=false
    local error=false
    local prompt="Check for macOS Updates"

    echo "========================================"
    echo "       Checking for macOS Updates"
    echo "========================================"
    echo ""

    # Check for available updates
    echo "Searching for available software updates..."
    UPDATE_OUTPUT=$(softwareupdate -l 2>/dev/null)

    # Extract only macOS updates (lines starting with "* Label:" and containing "macOS")
    UPDATE_LABEL=$(echo "$UPDATE_OUTPUT" | grep "^\* Label:" | grep "macOS" | head -1 | sed '/^\* Label: //')

    if [[ -z "$UPDATE_LABEL" ]]; then
        echo -e "${YELLOW}(No macOS updates found)${NC}"
        echo ""
        # Optionally show what other updates are available
        OTHER_UPDATES=$(echo "$UPDATE_OUTPUT" | grep "^\* Label:" | sed '/^\* Label: //')
        if [[ -n "$OTHER_UPDATES" ]]; then
            echo "Other available updates (non-macOS):"
            echo "$OTHER_UPDATES"
        fi
    else
        echo "Found macOS update: $UPDATE_LABEL"
        echo ""
    fi

    # Check if update is available
    if echo "$UPDATE_LABEL" | grep -q "macOS"; then
        echo ""
        read -p "Would you like to reboot after the update? (yes/no): " update_confirm

        if [[ "$update_confirm" == "yes" ]]; then
            echo ""
            echo -e "The system will ${YELLOW}restart${NC} after installation..."
            echo ""
            sudo softwareupdate -i "$UPDATE_LABEL" --restart
        elif [[ "$update_confirm" == "no" ]]; then
            echo ""
            echo -e "The system will ${YELLOW}NOT${NC} restart after installation..."
            echo "To restart and complete the update, you will need to run this update again with the restart function."
            echo ""
            sudo softwareupdate -i "$UPDATE_LABEL"
        else
            echo -e "${RED}Update cancelled.${NC}"
        fi
    else
        echo -e "${YELLOW}(No macOS updates found)${NC}"
    fi
}

# Option 10 - Function to check for specifically defined macOS update name
specific_update() {
    local success=false
    local error=false
    local prompt="Check for specifically defined macOS update name"

    echo "========================================"
    echo "       Update to a specific build"
    echo "========================================"
    echo ""

    echo "Current OS Version:"
    sw_vers
    echo ""

    read -p "What is the update name you would like to install? " update_name
    echo ""

    echo "Currently updating to $update_name"
    echo ""

    read -p "Would you like to reboot after the update? (yes/no): " confirm

    if [[ "$confirm" == "yes" ]]; then
        echo -e "The system will ${YELLOW}restart${NC} after installation..."
        echo ""
        sudo softwareupdate -i "$update_name" --restart
    elif [[ "$confirm" == "no" ]]; then
        echo -e "The system will ${YELLOW}NOT${NC} restart after installation..."
        echo "To restart and complete the update, you will need to run this update again with the restart function."
        echo ""
        sudo softwareupdate -i "$update_name"
    else
        echo -e "${RED}Update cancelled.${NC}"
    fi
}

# Main menu
show_menu() {
    clear
    echo ""
    echo "========================================"
    echo "         Mac Maintainer Toolbox"
    echo "========================================"
    echo ""
    echo "1. Uninstall Papercut"
    echo "2. Rename the Mac"
    echo "3. Check and boot active users"
    echo "4. Change a user's password"
    echo "5. Delete a user account"
    echo "6. Create a user account with local admin rights"
    echo "7. Prune inactive user accounts"
    echo "8. Manage FileVault disk encryption"
    echo "9. Check for macOS updates"
    echo ""
    echo "0. Exit and delete this script"
    echo ""
    echo ""
    echo -e "You are on machine ${BLUE}$(hostname)${NC} at ${BLUE}$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')${NC}."
    echo -e "The system has been up for ${BLUE}$(uptime | sed 's/.*up *//; s/,.*user.*//')${NC}."
    echo -e "Current macOS version is ${BLUE}$(sw_vers -productVersion)${NC}"
    echo ""
    read -p "What function would you like to perform? " choice
}

# Main script execution
while true; do
  show_menu
  
  case $choice in
    1)
      uninstall_papercut
      ;;
    2)
      rename_device
      ;;
    3)
      user_inquiry
      ;;
    4)
      change_password
      ;;
    5)
      delete_account
      ;;
    6)
      create_account
      ;;
    7)
      prune_users
      ;;
    8)
      check_filevault
      ;;
    9)
      check_updates
      ;;
    10)
      specific_update
      ;;
    0)
      echo "Deleting script and exiting..."
      sleep 2
      rm -rf mac-maintainer
      fc -p
      clear
      exit 0
      ;;
    *)
      echo "Invalid option. Please choose 1-9 or 0."
      ;;
  esac
  
  read -p "Press Enter to return to menu..."
done