#!/bin/bash

# Function to display the menu
show_menu() {
    echo "----------------------------------------"
    echo "MacOS Management Script"
    echo "1) Check current OS version"
    echo "2) Update all system and application software"
    echo "3) List and delete users"
    echo "4) Exit and Disconnect"
    echo "----------------------------------------"
}

# Function to get the current OS version
get_os_version() {
    sw_vers -productVersion
}

# Function to update all system and application software
update_system() {
    echo "Updating system and application software..."
    echo "This will take a few minutes. Please be patient..."
    
    # Check if there are any available updates
    if softwareupdate --list | grep -q "No updates found"; then
        echo "No new software available."
    else
        # Try to install all available updates
        if softwareupdate --all --force --quiet; then
            echo "Updates installed successfully."
        else
            echo "Error installing updates. Please try again."
        fi
    fi
}

# Function to list and delete users
manage_users() {
    echo "-------------------"
    echo "User Management"
    echo "-------------------"
    
    # List all users
    echo "Current Users:"
    dscl. list /Users | grep -v / | sort
    echo "-------------------"
    
    # Ask if user wants to delete any users
    read -p "Do you want to delete any users? (y/n): " delete_users
    
    if [ "$delete_users" = "y" ]; then
        echo "Enter user name to delete (press Ctrl+C to cancel):"
        read username
        if [! -z "$username" ]; then
            # Confirm deletion
            read -p "Are you sure you want to delete user '$username'? (y/n): " confirm_delete
            if [ "$confirm_delete" = "y" ]; then
                echo "Deleting user '$username'..."
                sudo dscl. -delete /Users/$username
                echo "User successfully deleted."
            else
                echo "Deletion cancelled."
            fi
        fi
    fi
}

# Main script
clear
echo "----------------------------------------"
echo "MacOS Management Script"
echo "----------------------------------------"

while true; do
    show_menu
    echo "----------------------------------------"
    
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            echo "Current OS Version: $(get_os_version)"
            ;;
        2)
            update_system
            ;;
        3)
            manage_users
            ;;
        4)
            echo "Exiting script and disconnecting SSH connection..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done
