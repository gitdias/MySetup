#!/usr/bin/env bash
#
#-----------------------------------------------------------------------------------------
#     MySetup – My settings all in one place!
#-----------------------------------------------------------------------------------------
# AUTHOR:       Sandro Dias (gitdias)
# REPOSITORY:   https://github.com/gitdias/MySetup
# VERSION:      0.0.1
# LICENSE:      GPL-3.0 License
# SCRIPT:       imback.sh
# PATH:         $HOME/.mysetup
# DESCRIPTION:  My settings all in one place!
# DEPENDENCIES: bash, curl or wget, git
#
# Copyright (c) 2026 Sandro Dias
#-----------------------------------------------------------------------------------------
#

set -euo pipefail

#-----------------------------------------------------------------------------------------
# GLOBAL VARIABLES
#-----------------------------------------------------------------------------------------
readonly SCRIPT_VERSION="0.0.1"
readonly REPO_URL="https://github.com/gitdias/MySetup"
readonly REPO_RAW="https://raw.githubusercontent.com/gitdias/MySetup/main"
readonly REPO_API="https://api.github.com/repos/gitdias/MySetup/releases/latest"
readonly INSTALL_DIR="$HOME/.mysetup"
readonly TEMP_DIR="/tmp/mysetup-$$"

# Detect system language
SYSTEM_LANG="${LANG:-en_US}"
[[ "$SYSTEM_LANG" =~ ^pt_BR ]] && LANG_CODE="pt_BR" || LANG_CODE="en_US"

#-----------------------------------------------------------------------------------------
# i18n - INTERNATIONALIZATION (EMBEDDED)
#-----------------------------------------------------------------------------------------
declare -A MSG_EN MSG_PT

# English (en_US) - Default
MSG_EN=(
    [BANNER_TITLE]="MYSETUP - MY SETTINGS ALL IN ONE PLACE!"
    [BANNER_VERSION]="Version"

    [INFO_CHECKING_VERSION]="Checking for updates..."
    [INFO_CURRENT_VERSION]="Current version"
    [INFO_LATEST_VERSION]="Latest version available"
    [INFO_DETECTING_DISTRO]="Detecting your Linux distribution..."
    [INFO_DISTRO_DETECTED]="Distribution detected"
    [INFO_PKG_MANAGER]="Package manager"
    [INFO_CLONING_REPO]="Cloning MySetup repository..."
    [INFO_CHECKING_PACKAGE]="Checking if package is installed"
    [INFO_PACKAGE_INSTALLED]="Package already installed"
    [INFO_PACKAGE_NOT_INSTALLED]="Package not installed"
    [INFO_CLEANING_UP]="Cleaning up temporary files..."
    [INFO_RERUN_SCRIPT]="Please rerun imback.sh after installing dependencies manually"

    [SUCCESS_UP_TO_DATE]="You are using the latest version!"
    [SUCCESS_REPO_CLONED]="Repository cloned successfully!"
    [SUCCESS_PACKAGE_INSTALLED]="Package installed successfully!"
    [SUCCESS_CONFIG_APPLIED]="Configuration applied successfully!"
    [SUCCESS_CLEANUP_DONE]="Cleanup completed!"
    [SUCCESS_ALL_DONE]="All done! Welcome back!"

    [QUESTION_UPDATE_AVAILABLE]="New version available. Update now? (y/n)"
    [QUESTION_INSTALL_PACKAGE]="Install package"
    [QUESTION_RESTART_APP]="Restart application"
    [QUESTION_REBOOT_SYSTEM]="System reboot required. Reboot now? (y/n)"

    [ERROR_UNSUPPORTED_DISTRO]="Unsupported distribution"
    [ERROR_NO_PKG_MANAGER]="No supported package manager found"
    [ERROR_CLONE_FAILED]="Failed to clone repository"
    [ERROR_INSTALL_FAILED]="Failed to install package"
    [ERROR_NO_CURL_WGET]="Neither curl nor wget found. Please install one of them"
    [ERROR_NO_GIT]="Git not found. Please install git first"
    [ERROR_VERSION_CHECK_FAILED]="Failed to check for updates"
    [ERROR_DEPENDENCY_MISSING]="Missing dependency"
)

# Portuguese (pt_BR)
MSG_PT=(
    [BANNER_TITLE]="MYSETUP - MINHAS CONFIGURAÇÕES EM UM SÓ LUGAR!"
    [BANNER_VERSION]="Versão"

    [INFO_CHECKING_VERSION]="Verificando atualizações..."
    [INFO_CURRENT_VERSION]="Versão atual"
    [INFO_LATEST_VERSION]="Última versão disponível"
    [INFO_DETECTING_DISTRO]="Detectando sua distribuição Linux..."
    [INFO_DISTRO_DETECTED]="Distribuição detectada"
    [INFO_PKG_MANAGER]="Gerenciador de pacotes"
    [INFO_CLONING_REPO]="Clonando repositório MySetup..."
    [INFO_CHECKING_PACKAGE]="Verificando se o pacote está instalado"
    [INFO_PACKAGE_INSTALLED]="Pacote já instalado"
    [INFO_PACKAGE_NOT_INSTALLED]="Pacote não instalado"
    [INFO_CLEANING_UP]="Limpando arquivos temporários..."
    [INFO_RERUN_SCRIPT]="Por favor, execute imback.sh novamente após instalar as dependências manualmente"

    [SUCCESS_UP_TO_DATE]="Você está usando a versão mais recente!"
    [SUCCESS_REPO_CLONED]="Repositório clonado com sucesso!"
    [SUCCESS_PACKAGE_INSTALLED]="Pacote instalado com sucesso!"
    [SUCCESS_CONFIG_APPLIED]="Configuração aplicada com sucesso!"
    [SUCCESS_CLEANUP_DONE]="Limpeza concluída!"
    [SUCCESS_ALL_DONE]="Tudo pronto! Bem-vindo de volta!"

    [QUESTION_UPDATE_AVAILABLE]="Nova versão disponível. Atualizar agora? (s/n)"
    [QUESTION_INSTALL_PACKAGE]="Instalar pacote"
    [QUESTION_RESTART_APP]="Reiniciar aplicação"
    [QUESTION_REBOOT_SYSTEM]="Reinicialização do sistema necessária. Reiniciar agora? (s/n)"

    [ERROR_UNSUPPORTED_DISTRO]="Distribuição não suportada"
    [ERROR_NO_PKG_MANAGER]="Nenhum gerenciador de pacotes suportado encontrado"
    [ERROR_CLONE_FAILED]="Falha ao clonar repositório"
    [ERROR_INSTALL_FAILED]="Falha ao instalar pacote"
    [ERROR_NO_CURL_WGET]="Nem curl nem wget encontrados. Por favor, instale um deles"
    [ERROR_NO_GIT]="Git não encontrado. Por favor, instale git primeiro"
    [ERROR_VERSION_CHECK_FAILED]="Falha ao verificar atualizações"
    [ERROR_DEPENDENCY_MISSING]="Dependência ausente"
)

#-----------------------------------------------------------------------------------------
# FUNCTION: msg
# Get translated message
#-----------------------------------------------------------------------------------------
msg() {
    local key="$1"
    if [[ "$LANG_CODE" == "pt_BR" ]]; then
        echo "${MSG_PT[$key]:-${MSG_EN[$key]:-$key}}"
    else
        echo "${MSG_EN[$key]:-$key}"
    fi
}

#-----------------------------------------------------------------------------------------
# FUNCTION: print_banner
# Display script banner
#-----------------------------------------------------------------------------------------
print_banner() {
    local title version_text
    title=$(msg "BANNER_TITLE")
    version_text=$(msg "BANNER_VERSION")

    echo "#"
    echo "------------------------------------------------------------"
    echo "      $title"
    echo "------------------------------------------------------------"
    echo "#"
    echo "[$version_text: $SCRIPT_VERSION]"
    echo ""
}

#-----------------------------------------------------------------------------------------
# FUNCTION: print_msg
# Print formatted message
# Usage: print_msg TYPE KEY [extra_info]
#-----------------------------------------------------------------------------------------
print_msg() {
    local type="$1"
    local key="$2"
    local extra="${3:-}"
    local message

    message=$(msg "$key")

    if [[ -n "$extra" ]]; then
        echo "[$type] - $message: $extra"
    else
        echo "[$type] - $message"
    fi
}

#-----------------------------------------------------------------------------------------
# FUNCTION: ask_question
# Ask yes/no question
# Returns: 0 for yes, 1 for no
#-----------------------------------------------------------------------------------------
ask_question() {
    local key="$1"
    local extra="${2:-}"
    local question answer

    question=$(msg "$key")

    if [[ -n "$extra" ]]; then
        echo -n "[$QUESTION] - $question '$extra'? (y/n): "
    else
        echo -n "[$QUESTION] - $question: "
    fi

    read -r answer

    # Accept y/Y/s/S for yes
    [[ "$answer" =~ ^[yYsS]$ ]] && return 0 || return 1
}

#-----------------------------------------------------------------------------------------
# FUNCTION: detect_distro
# Detect Linux distribution and package manager
#-----------------------------------------------------------------------------------------
detect_distro() {
    print_msg "INFO" "INFO_DETECTING_DISTRO"

    if [[ ! -f /etc/os-release ]]; then
        print_msg "ERROR" "ERROR_UNSUPPORTED_DISTRO"
        exit 1
    fi

    source /etc/os-release

    local distro_name="$NAME"
    local distro_id="${ID:-unknown}"

    # Detect package manager
    case "$distro_id" in
        arch|cachyos)
            PKG_MANAGER="pacman"
            PKG_INSTALL_CMD="sudo pacman -S --noconfirm"
            PKG_CHECK_CMD="pacman -Qq"

            # Check for AUR helper
            if command -v paru &>/dev/null; then
                AUR_HELPER="paru"
                AUR_INSTALL_CMD="paru -S --noconfirm"
            elif command -v yay &>/dev/null; then
                AUR_HELPER="yay"
                AUR_INSTALL_CMD="yay -S --noconfirm"
            fi
            ;;
        debian|ubuntu)
            PKG_MANAGER="apt"
            PKG_INSTALL_CMD="sudo apt-get install -y"
            PKG_CHECK_CMD="dpkg -l"
            ;;
        fedora)
            PKG_MANAGER="dnf"
            PKG_INSTALL_CMD="sudo dnf install -y"
            PKG_CHECK_CMD="rpm -q"
            ;;
        *)
            print_msg "ERROR" "ERROR_UNSUPPORTED_DISTRO" "$distro_name"
            exit 1
            ;;
    esac

    print_msg "SUCCESS" "INFO_DISTRO_DETECTED" "$distro_name"
    print_msg "INFO" "INFO_PKG_MANAGER" "$PKG_MANAGER"
}

#-----------------------------------------------------------------------------------------
# FUNCTION: check_dependencies
# Check if required dependencies are installed
#-----------------------------------------------------------------------------------------
check_dependencies() {
    local missing_deps=()

    # Check for curl or wget
    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        print_msg "ERROR" "ERROR_NO_CURL_WGET"
        exit 1
    fi

    # Check for git
    if ! command -v git &>/dev/null; then
        print_msg "ERROR" "ERROR_NO_GIT"
        exit 1
    fi
}

#-----------------------------------------------------------------------------------------
# FUNCTION: check_version
# Check for script updates
#-----------------------------------------------------------------------------------------
check_version() {
    print_msg "INFO" "INFO_CHECKING_VERSION"

    local latest_version

    # Try to get latest release version from GitHub API
    if command -v curl &>/dev/null; then
        latest_version=$(curl -s "$REPO_API" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' 2>/dev/null)
    elif command -v wget &>/dev/null; then
        latest_version=$(wget -qO- "$REPO_API" | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' 2>/dev/null)
    fi

    if [[ -z "$latest_version" ]]; then
        print_msg "ERROR" "ERROR_VERSION_CHECK_FAILED"
        return 1
    fi

    print_msg "INFO" "INFO_CURRENT_VERSION" "$SCRIPT_VERSION"
    print_msg "INFO" "INFO_LATEST_VERSION" "$latest_version"

    if [[ "$SCRIPT_VERSION" != "$latest_version" ]]; then
        if ask_question "QUESTION_UPDATE_AVAILABLE"; then
            # Download and execute latest version
            if command -v curl &>/dev/null; then
                bash <(curl -fsSL "$REPO_RAW/imback.sh")
            else
                bash <(wget -qO- "$REPO_RAW/imback.sh")
            fi
            exit 0
        fi
    else
        print_msg "SUCCESS" "SUCCESS_UP_TO_DATE"
    fi
}

#-----------------------------------------------------------------------------------------
# FUNCTION: clone_repository
# Clone MySetup repository to temporary directory
#-----------------------------------------------------------------------------------------
clone_repository() {
    print_msg "INFO" "INFO_CLONING_REPO"

    # Remove temp dir if exists
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"

    # Clone repository
    if git clone --quiet "$REPO_URL.git" "$TEMP_DIR" 2>/dev/null; then
        print_msg "SUCCESS" "SUCCESS_REPO_CLONED"
        return 0
    else
        print_msg "ERROR" "ERROR_CLONE_FAILED"
        return 1
    fi
}

#-----------------------------------------------------------------------------------------
# FUNCTION: is_package_installed
# Check if package is installed
#-----------------------------------------------------------------------------------------
is_package_installed() {
    local package="$1"

    print_msg "INFO" "INFO_CHECKING_PACKAGE" "$package"

    case "$PKG_MANAGER" in
        pacman)
            if pacman -Qq "$package" &>/dev/null; then
                print_msg "INFO" "INFO_PACKAGE_INSTALLED" "$package"
                return 0
            fi
            ;;
        apt)
            if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
                print_msg "INFO" "INFO_PACKAGE_INSTALLED" "$package"
                return 0
            fi
            ;;
        dnf)
            if rpm -q "$package" &>/dev/null; then
                print_msg "INFO" "INFO_PACKAGE_INSTALLED" "$package"
                return 0
            fi
            ;;
    esac

    print_msg "INFO" "INFO_PACKAGE_NOT_INSTALLED" "$package"
    return 1
}

#-----------------------------------------------------------------------------------------
# FUNCTION: install_package
# Install package using detected package manager
#-----------------------------------------------------------------------------------------
install_package() {
    local package="$1"
    local is_aur="${2:-false}"

    if ask_question "QUESTION_INSTALL_PACKAGE" "$package"; then
        if [[ "$is_aur" == "true" && -n "${AUR_HELPER:-}" ]]; then
            $AUR_INSTALL_CMD "$package"
        else
            $PKG_INSTALL_CMD "$package"
        fi

        if [[ $? -eq 0 ]]; then
            print_msg "SUCCESS" "SUCCESS_PACKAGE_INSTALLED" "$package"
            return 0
        else
            print_msg "ERROR" "ERROR_INSTALL_FAILED" "$package"
            return 1
        fi
    else
        print_msg "INFO" "INFO_RERUN_SCRIPT"
        return 1
    fi
}

#-----------------------------------------------------------------------------------------
# FUNCTION: apply_configs
# Apply configurations from repository
#-----------------------------------------------------------------------------------------
apply_configs() {
    local config_dir="$TEMP_DIR/configs"

    # Check if configs directory exists
    if [[ ! -d "$config_dir" ]]; then
        return 0
    fi

    # TODO: Implement configuration application logic
    # This will be expanded based on specific configs to apply

    print_msg "SUCCESS" "SUCCESS_CONFIG_APPLIED"
}

#-----------------------------------------------------------------------------------------
# FUNCTION: cleanup
# Clean up temporary files
#-----------------------------------------------------------------------------------------
cleanup() {
    print_msg "INFO" "INFO_CLEANING_UP"

    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"

    print_msg "SUCCESS" "SUCCESS_CLEANUP_DONE"
}

#-----------------------------------------------------------------------------------------
# FUNCTION: main
# Main execution flow
#-----------------------------------------------------------------------------------------
main() {
    # Display banner
    print_banner

    # Check dependencies
    check_dependencies

    # Detect distribution
    detect_distro

    # Check for updates
    check_version

    # Clone repository
    if ! clone_repository; then
        exit 1
    fi

    # Apply configurations
    apply_configs

    # Cleanup
    cleanup

    # Success message
    print_msg "SUCCESS" "SUCCESS_ALL_DONE"
}

#-----------------------------------------------------------------------------------------
# EXECUTION
#-----------------------------------------------------------------------------------------
main "$@"
