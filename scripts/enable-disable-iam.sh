#!/bin/bash

# Manage admin IAM user activation/deactivation

echo "=== Admin IAM User Management ==="
echo ""

# Function to get admin users list (returns array)
get_admin_users() {
    local all_users=$(aws iam list-users --query 'Users[].UserName' --output text 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ -z "$all_users" ]]; then
        return 1
    fi
    
    local found_users=()
    for user in $all_users; do
        if is_admin_user "$user"; then
            found_users+=("$user")
        fi
    done
    
    # Return users via echo (bash array return workaround)
    echo "${found_users[@]}"
    return 0
}

# Function to select user from list
select_admin_user() {
    local action="$1"  # "activate" or "deactivate"
    
    echo "🔍 Finding admin users..."
    local admin_users_array=($(get_admin_users))
    
    if [[ ${#admin_users_array[@]} -eq 0 ]]; then
        echo "❌ No admin users found with required tags"
        echo "💡 Use the admin user creation script first"
        return 1
    fi
    
    echo ""
    echo "📋 Available admin users:"
    for i in "${!admin_users_array[@]}"; do
        local user="${admin_users_array[$i]}"
        local status="Unknown"
        
        # Check current key status
        local key_status=$(aws iam list-access-keys --user-name "$user" --query 'AccessKeyMetadata[0].Status' --output text 2>/dev/null)
        if [[ "$key_status" == "Active" ]]; then
            status="🟢 Active"
        elif [[ "$key_status" == "Inactive" ]]; then
            status="🔴 Inactive"
        fi
        
        echo "   $((i+1))) $user ($status)"
    done
    
    echo ""
    read -p "Select user to $action [1-${#admin_users_array[@]}]: " CHOICE
    
    # Validate choice
    if [[ ! "$CHOICE" =~ ^[0-9]+$ ]] || [[ "$CHOICE" -lt 1 ]] || [[ "$CHOICE" -gt ${#admin_users_array[@]} ]]; then
        echo "❌ Invalid choice"
        return 1
    fi
    
    # Return selected username
    echo "${admin_users_array[$((CHOICE-1))]}"
    return 0
}

# Function to check if user is admin (simple but accurate)
is_admin_user() {
    local username="$1"
    local tags=$(aws iam list-user-tags --user-name "$username" --output text 2>/dev/null)
    
    # Handle case when user has no tags
    if [[ -z "$tags" ]]; then
        return 1
    fi
    
    # Check for exact tag matches (not partial)
    echo "$tags" | grep -q "adminIAM[[:space:]]true" && \
    echo "$tags" | grep -q "Purpose[[:space:]]TerraformAdmin" && \
    echo "$tags" | grep -q "CreatedBy[[:space:]]Script"
}

# Function to show user status (simplified)
show_user_status() {
    local username="$1"
    
    if ! aws iam get-user --user-name "$username" >/dev/null 2>&1; then
        echo "❌ User '$username' does not exist"
        return 1
    fi
    
    echo "📊 Status for user: $username"
    
    # Check if admin user
    if is_admin_user "$username"; then
        echo "✅ This is an admin user (has required tags)"
    else
        echo "❌ This is NOT an admin user (missing required tags)"
    fi
    
    # Show access keys status
    echo ""
    echo "🔑 Access Keys:"
    aws iam list-access-keys --user-name "$username" --query 'AccessKeyMetadata[].{Key:AccessKeyId,Status:Status}' --output table 2>/dev/null || echo "   No access keys found"
    
    return 0
}

# Function to activate user (with security check)
activate_user() {
    local username="$1"
    
    # ВАЖНО: Проверяем что это admin пользователь
    if ! is_admin_user "$username"; then
        echo "❌ User '$username' is not an admin user"
        return 1
    fi
    
    local access_keys=$(aws iam list-access-keys --user-name "$username" --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null)
    
    if [[ -z "$access_keys" ]]; then
        echo "❌ No access keys found"
        return 1
    fi
    
    # Activate all keys
    for key_id in $access_keys; do
        if ! aws iam update-access-key --user-name "$username" --access-key-id "$key_id" --status Active 2>/dev/null; then
            echo "❌ Failed to activate key: $key_id"
            return 1
        fi
    done
    
    echo "✅ User '$username' activated"
    return 0
}

# Function to deactivate user (with security check)
deactivate_user() {
    local username="$1"
    
    # ВАЖНО: Проверяем что это admin пользователь
    if ! is_admin_user "$username"; then
        echo "❌ User '$username' is not an admin user"
        return 1
    fi
    
    local access_keys=$(aws iam list-access-keys --user-name "$username" --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null)
    
    if [[ -z "$access_keys" ]]; then
        echo "❌ No access keys found"
        return 1
    fi
    
    # Deactivate all keys
    for key_id in $access_keys; do
        if ! aws iam update-access-key --user-name "$username" --access-key-id "$key_id" --status Inactive 2>/dev/null; then
            echo "❌ Failed to deactivate key: $key_id"
            return 1
        fi
    done
    
    echo "✅ User '$username' deactivated"
    return 0
}

# Main menu
echo "Choose an action:"
echo "1) List all admin users"
echo "2) Activate user"
echo "3) Deactivate user"
echo "4) Exit"
echo ""
read -p "Enter choice [1-4]: " CHOICE

case $CHOICE in
    1)
        echo "🔍 Searching for admin IAM users..."
        local admin_users_array=($(get_admin_users))
        
        if [[ $? -ne 0 ]] || [[ ${#admin_users_array[@]} -eq 0 ]]; then
            echo "❌ No admin users found or error accessing AWS"
            echo "💡 Use the admin user creation script first"
        else
            echo ""
            echo "📋 Found admin users:"
            for user in "${admin_users_array[@]}"; do
                local key_status=$(aws iam list-access-keys --user-name "$user" --query 'AccessKeyMetadata[0].Status' --output text 2>/dev/null)
                local status="Unknown"
                if [[ "$key_status" == "Active" ]]; then
                    status="🟢 Active"
                elif [[ "$key_status" == "Inactive" ]]; then
                    status="🔴 Inactive"
                fi
                echo "   - $user ($status)"
            done
        fi
        ;;
    2)
        USERNAME=$(select_admin_user "activate")
        if [[ $? -eq 0 ]] && [[ -n "$USERNAME" ]]; then
            echo ""
            echo "⚠️  WARNING: This will give '$USERNAME' near-root privileges!"
            read -p "Are you sure you want to activate '$USERNAME'? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if activate_user "$USERNAME"; then
                    echo "🎯 User '$USERNAME' is now ACTIVE and can perform admin operations"
                    echo "📝 Remember to deactivate when finished!"
                else
                    exit 1
                fi
            else
                echo "Operation cancelled."
            fi
        fi
        ;;
    3)
        USERNAME=$(select_admin_user "deactivate")
        if [[ $? -eq 0 ]] && [[ -n "$USERNAME" ]]; then
            if deactivate_user "$USERNAME"; then
                echo "🛡️  User '$USERNAME' is now INACTIVE and cannot access AWS"
            else
                exit 1
            fi
        fi
        ;;
    4)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac