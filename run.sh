#!/bin/bash

# Function to check if Python3 is available
check_python() {
    PYTHON=$(which python3)
    if [ -z "$PYTHON" ]; then
        echo "Python 3 not found. Please install Python 3 and try again."
        exit 1
    fi
}

# Function to check if a Python package is installed
check_package() {
    $PYTHON -c "import $1" 2>/dev/null
    return $?
}

# Function to install required packages
install_packages() {
    echo "Installing required packages..."
    $PYTHON -m pip install --upgrade pip
    $PYTHON -m pip install asyncio websockets aiohttp
}

# Check and install required packages if needed
install_requirements() {
    for package in asyncio websockets aiohttp; do
        if ! check_package $package; then
            install_packages
            break
        fi
    done
}

# Set installation directory in current path
INSTALL_DIR="kaioagent-cli"

# Fixed URLs for kaioagent.py downloads
LATEST_URL="https://github.com/siliconuy/kagcli-releases/releases/latest/download/kaioagent.py"

# Function to get version from kaioagent.py
get_version() {
    local file=$1
    if [ -f "$file" ]; then
        version=$(grep "^VERSION = " "$file" | cut -d'"' -f2)
        echo "$version"
    else
        echo "unknown"
    fi
}

# Function to download and install kaioagent.py
download_and_install() {
    mkdir -p "${INSTALL_DIR}"
    echo "Downloading latest kaioagent.py..."
    if curl -s -L -o "${INSTALL_DIR}/kaioagent.py" "${LATEST_URL}"; then
        chmod +x "${INSTALL_DIR}/kaioagent.py"
        # Save version information
        version=$(get_version "${INSTALL_DIR}/kaioagent.py")
        echo "$version" > "${INSTALL_DIR}/.version"
        echo "Successfully downloaded version $version"
        return 0
    else
        echo "Failed to download kaioagent.py"
        return 1
    fi
}

# Main installation/update logic
main() {
    check_python
    install_requirements

    if [ -d "${INSTALL_DIR}" ]; then
        if [ -f "${INSTALL_DIR}/.version" ]; then
            CURRENT_VERSION=$(cat "${INSTALL_DIR}/.version")
        else
            CURRENT_VERSION="unknown"
        fi
        
        echo "Detected existing installation (version ${CURRENT_VERSION})."
        read -p "Do you want to check for updates? (Y/n) " response
        case "$response" in
            [Nn]* )
                echo "Keeping current version."
                ;;
            * )
                echo "Checking for updates..."
                # Download to a temporary file to check version
                mkdir -p "${INSTALL_DIR}/temp"
                if curl -s -L -o "${INSTALL_DIR}/temp/kaioagent.py" "${LATEST_URL}"; then
                    NEW_VERSION=$(get_version "${INSTALL_DIR}/temp/kaioagent.py")
                    rm -rf "${INSTALL_DIR}/temp"
                    
                    if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
                        echo "New version available: $NEW_VERSION"
                        read -p "Do you want to update? (Y/n) " update_response
                        case "$update_response" in
                            [Nn]* )
                                echo "Keeping current version."
                                ;;
                            * )
                                echo "Updating to version $NEW_VERSION..."
                                download_and_install
                                ;;
                        esac
                    else
                        echo "You have the latest version ($CURRENT_VERSION)."
                    fi
                else
                    echo "Failed to check for updates. Keeping current version."
                fi
                ;;
        esac
    else
        echo "No existing installation found. Installing..."
        download_and_install
    fi

    # Run the Python script
    echo "Starting KaioAgent client..."
    $PYTHON "${INSTALL_DIR}/kaioagent.py"
}

main
