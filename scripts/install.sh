#!/bin/bash
set -e

# ============================================================================
# Configuration
# ============================================================================
GITHUB_REPO="Gouryella/drip"
INSTALL_DIR="${INSTALL_DIR:-}"
VERSION="${VERSION:-}"
BINARY_NAME="drip"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Language (default: en)
LANG_CODE="${LANG_CODE:-en}"

# ============================================================================
# Internationalization
# ============================================================================
declare -A MSG_EN
declare -A MSG_ZH

# English messages
MSG_EN=(
    ["banner_title"]="Drip Client - One-Click Installer"
    ["select_lang"]="Select language / 选择语言"
    ["lang_en"]="English"
    ["lang_zh"]="中文"
    ["checking_os"]="Checking operating system..."
    ["detected_os"]="Detected OS"
    ["unsupported_os"]="Unsupported operating system"
    ["checking_arch"]="Checking system architecture..."
    ["detected_arch"]="Detected architecture"
    ["unsupported_arch"]="Unsupported architecture"
    ["checking_deps"]="Checking dependencies..."
    ["deps_ok"]="Dependencies check passed"
    ["downloading"]="Downloading Drip client"
    ["download_failed"]="Download failed"
    ["download_ok"]="Download completed"
    ["select_install_dir"]="Select installation directory"
    ["option_user"]="User directory (no sudo required)"
    ["option_system"]="System directory (requires sudo)"
    ["option_current"]="Current directory"
    ["option_custom"]="Custom path"
    ["enter_custom_path"]="Enter custom path"
    ["installing"]="Installing binary..."
    ["install_ok"]="Installation completed"
    ["updating_path"]="Updating PATH..."
    ["path_updated"]="PATH updated"
    ["path_note"]="Please restart your terminal or run: source ~/.bashrc"
    ["config_title"]="Client Configuration"
    ["configure_now"]="Configure client now?"
    ["enter_server"]="Enter server address (e.g., tunnel.example.com:8443)"
    ["server_required"]="Server address is required"
    ["enter_token"]="Enter authentication token"
    ["token_required"]="Token is required"
    ["skip_verify"]="Skip TLS certificate verification? (for self-signed certs)"
    ["config_saved"]="Configuration saved"
    ["install_complete"]="Installation completed!"
    ["usage_title"]="Usage"
    ["usage_http"]="Expose HTTP service on port 3000"
    ["usage_tcp"]="Expose TCP service on port 5432"
    ["usage_config"]="Show/modify configuration"
    ["usage_daemon"]="Run as background daemon"
    ["run_test"]="Test connection now?"
    ["test_running"]="Testing connection..."
    ["test_success"]="Connection successful"
    ["test_failed"]="Connection failed"
    ["yes"]="y"
    ["no"]="n"
    ["press_enter"]="Press Enter to continue..."
    ["windows_note"]="For Windows, please download the .exe file from GitHub Releases"
    ["already_installed"]="Drip is already installed"
    ["current_version"]="Current version"
    ["update_now"]="Update to the latest version?"
    ["updating"]="Updating..."
    ["update_ok"]="Update completed"
    ["verify_install"]="Verifying installation..."
    ["verify_ok"]="Verification passed"
    ["verify_failed"]="Verification failed"
    ["insecure_note"]="Only use --insecure for development/testing"
)

# Chinese messages
MSG_ZH=(
    ["banner_title"]="Drip 客户端 - 一键安装脚本"
    ["select_lang"]="Select language / 选择语言"
    ["lang_en"]="English"
    ["lang_zh"]="中文"
    ["checking_os"]="检查操作系统..."
    ["detected_os"]="检测到操作系统"
    ["unsupported_os"]="不支持的操作系统"
    ["checking_arch"]="检查系统架构..."
    ["detected_arch"]="检测到架构"
    ["unsupported_arch"]="不支持的架构"
    ["checking_deps"]="检查依赖..."
    ["deps_ok"]="依赖检查通过"
    ["downloading"]="下载 Drip 客户端"
    ["download_failed"]="下载失败"
    ["download_ok"]="下载完成"
    ["select_install_dir"]="选择安装目录"
    ["option_user"]="用户目录（无需 sudo）"
    ["option_system"]="系统目录（需要 sudo）"
    ["option_current"]="当前目录"
    ["option_custom"]="自定义路径"
    ["enter_custom_path"]="输入自定义路径"
    ["installing"]="安装二进制文件..."
    ["install_ok"]="安装完成"
    ["updating_path"]="更新 PATH..."
    ["path_updated"]="PATH 已更新"
    ["path_note"]="请重启终端或运行: source ~/.bashrc"
    ["config_title"]="客户端配置"
    ["configure_now"]="现在配置客户端？"
    ["enter_server"]="输入服务器地址（例如：tunnel.example.com:8443）"
    ["server_required"]="服务器地址是必填项"
    ["enter_token"]="输入认证令牌"
    ["token_required"]="认证令牌是必填项"
    ["skip_verify"]="跳过 TLS 证书验证？（用于自签名证书）"
    ["config_saved"]="配置已保存"
    ["install_complete"]="安装完成！"
    ["usage_title"]="使用方法"
    ["usage_http"]="暴露本地 3000 端口的 HTTP 服务"
    ["usage_tcp"]="暴露本地 5432 端口的 TCP 服务"
    ["usage_config"]="显示/修改配置"
    ["usage_daemon"]="作为后台守护进程运行"
    ["run_test"]="现在测试连接？"
    ["test_running"]="正在测试连接..."
    ["test_success"]="连接成功"
    ["test_failed"]="连接失败"
    ["yes"]="y"
    ["no"]="n"
    ["press_enter"]="按 Enter 继续..."
    ["windows_note"]="Windows 用户请从 GitHub Releases 下载 .exe 文件"
    ["already_installed"]="Drip 已安装"
    ["current_version"]="当前版本"
    ["update_now"]="是否更新到最新版本？"
    ["updating"]="正在更新..."
    ["update_ok"]="更新完成"
    ["verify_install"]="验证安装..."
    ["verify_ok"]="验证通过"
    ["verify_failed"]="验证失败"
    ["insecure_note"]="--insecure 仅用于开发/测试环境"
)

# Get message by key
msg() {
    local key="$1"
    if [[ "$LANG_CODE" == "zh" ]]; then
        echo "${MSG_ZH[$key]:-$key}"
    else
        echo "${MSG_EN[$key]:-$key}"
    fi
}

# ============================================================================
# Output functions
# ============================================================================
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_step() { echo -e "${CYAN}[→]${NC} $1"; }

# Print banner
print_banner() {
    echo -e "${GREEN}"
    cat << "EOF"
    ____       _
   / __ \_____(_)___
  / / / / ___/ / __ \
 / /_/ / /  / / /_/ /
/_____/_/  /_/ .___/
            /_/
EOF
    echo -e "${BOLD}$(msg banner_title)${NC}"
    echo ""
}

# Extract version from a drip binary, preferring the plain output when available
get_version_from_binary() {
    local binary="$1"
    local output=""
    local version=""

    output=$("$binary" version --short 2>/dev/null || true)
    if [[ -n "$output" ]]; then
        version=$(printf '%s\n' "$output" | awk -F': ' '/Version/ {print $2; exit}')
    fi

    if [[ -z "$version" ]]; then
        output=$("$binary" version 2>/dev/null || true)
        if [[ -n "$output" ]]; then
            output=$(printf '%s\n' "$output" | sed -E $'s/\x1b\\[[0-9;]*[A-Za-z]//g')
            version=$(printf '%s\n' "$output" | sed -nE 's/.*Version:[[:space:]]*([vV]?[0-9][^[:space:]]*).*/\1/p' | head -n1)
        fi
    fi

    echo "${version:-unknown}"
}

# ============================================================================
# Language selection
# ============================================================================
select_language() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   $(msg select_lang)          ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}1)${NC} English                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}2)${NC} 中文                                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""

    read -p "Select [1]: " lang_choice < /dev/tty
    case "$lang_choice" in
        2)
            LANG_CODE="zh"
            ;;
        *)
            LANG_CODE="en"
            ;;
    esac
    echo ""
}

# ============================================================================
# System checks
# ============================================================================
check_os() {
    print_step "$(msg checking_os)"

    case "$(uname -s)" in
        Linux*)
            OS="linux"
            ;;
        Darwin*)
            OS="darwin"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS="windows"
            print_warning "$(msg windows_note)"
            ;;
        *)
            print_error "$(msg unsupported_os): $(uname -s)"
            exit 1
            ;;
    esac

    print_success "$(msg detected_os): $OS"
}

check_arch() {
    print_step "$(msg checking_arch)"

    case "$(uname -m)" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        *)
            print_error "$(msg unsupported_arch): $(uname -m)"
            exit 1
            ;;
    esac

    print_success "$(msg detected_arch): $ARCH"
}

check_dependencies() {
    print_step "$(msg checking_deps)"

    # Check for download tool
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        print_error "curl or wget is required"
        exit 1
    fi

    print_success "$(msg deps_ok)"
}

get_latest_version() {
    # Get latest version from GitHub API
    local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
    local version=""

    if command -v curl &> /dev/null; then
        version=$(curl -fsSL "$api_url" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' 2>/dev/null)
    else
        version=$(wget -qO- "$api_url" | grep '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' 2>/dev/null)
    fi

    if [[ -z "$version" ]]; then
        print_error "Failed to get latest version from GitHub"
        exit 1
    fi

    echo "$version"
}


check_existing_install() {
    if command -v drip &> /dev/null; then
        local current_path=$(command -v drip)
        local current_version=$(get_version_from_binary "drip")

        print_warning "$(msg already_installed): $current_path"
        print_info "$(msg current_version): $current_version"

        # Check remote version
        print_step "Checking for updates..."
        local latest_version=$(get_latest_version)

        if [[ "$current_version" == "$latest_version" ]]; then
            print_success "Already up to date ($current_version)"
            exit 0
        else
            print_info "Latest version: $latest_version"
            echo ""
            read -p "$(msg update_now) [Y/n]: " update_choice < /dev/tty
        fi

        if [[ "$update_choice" =~ ^[Nn]$ ]]; then
            exit 0
        fi

        INSTALL_DIR=$(dirname "$current_path")
        IS_UPDATE=true
    fi
}

# ============================================================================
# Download and install
# ============================================================================
get_download_url() {
    # Get latest version if not set
    if [[ -z "$VERSION" ]]; then
        VERSION=$(get_latest_version)
    fi

    local binary_name

    if [[ "$OS" == "windows" ]]; then
        binary_name="drip-${VERSION}-windows-${ARCH}.exe"
    else
        binary_name="drip-${VERSION}-${OS}-${ARCH}"
    fi

    echo "https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/${binary_name}"
}

download_binary() {
    local url=$(get_download_url)

    if [[ "$IS_UPDATE" == true ]]; then
        print_step "$(msg updating)..."
    else
        print_step "$(msg downloading)..."
    fi

    local tmp_file="/tmp/drip-download"

    if command -v curl &> /dev/null; then
        # Use -# for progress bar instead of -s (silent)
        if ! curl -f#L "$url" -o "$tmp_file"; then
            print_error "$(msg download_failed): $url"
            exit 1
        fi
    else
        # Use --show-progress to display download progress
        if ! wget --show-progress "$url" -O "$tmp_file" 2>&1 | grep -v "^$"; then
            print_error "$(msg download_failed): $url"
            exit 1
        fi
    fi

    chmod +x "$tmp_file"
    print_success "$(msg download_ok)"
}

select_install_dir() {
    if [[ -n "$INSTALL_DIR" ]]; then
        return
    fi

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   $(msg select_install_dir)                    ${CYAN}║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}1)${NC} ~/.local/bin $(msg option_user)       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}2)${NC} /usr/local/bin $(msg option_system)   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}3)${NC} ./ $(msg option_current)               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}4)${NC} $(msg option_custom)                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""

    read -p "Select [1]: " dir_choice < /dev/tty

    case "$dir_choice" in
        2)
            INSTALL_DIR="/usr/local/bin"
            NEED_SUDO=true
            ;;
        3)
            INSTALL_DIR="."
            ;;
        4)
            read -p "$(msg enter_custom_path): " INSTALL_DIR < /dev/tty
            ;;
        *)
            INSTALL_DIR="$HOME/.local/bin"
            ;;
    esac
}

install_binary() {
    print_step "$(msg installing)"

    # Create directory if needed
    if [[ ! -d "$INSTALL_DIR" ]]; then
        if [[ "$NEED_SUDO" == true ]]; then
            sudo mkdir -p "$INSTALL_DIR"
        else
            mkdir -p "$INSTALL_DIR"
        fi
    fi

    local target_path="$INSTALL_DIR/$BINARY_NAME"
    if [[ "$OS" == "windows" ]]; then
        target_path="$INSTALL_DIR/$BINARY_NAME.exe"
    fi

    # Install binary
    if [[ "$NEED_SUDO" == true ]]; then
        sudo mv /tmp/drip-download "$target_path"
        sudo chmod +x "$target_path"
    else
        mv /tmp/drip-download "$target_path"
        chmod +x "$target_path"
    fi

    print_success "$(msg install_ok): $target_path"
}

update_path() {
    # Skip if already in PATH
    if command -v drip &> /dev/null; then
        return
    fi

    # Skip for system directories (usually already in PATH)
    if [[ "$INSTALL_DIR" == "/usr/local/bin" ]] || [[ "$INSTALL_DIR" == "/usr/bin" ]]; then
        return
    fi

    print_step "$(msg updating_path)"

    local shell_rc=""
    local export_line="export PATH=\"\$PATH:$INSTALL_DIR\""

    # Determine shell config file
    if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
        if [[ "$OS" == "darwin" ]]; then
            shell_rc="$HOME/.bash_profile"
        else
            shell_rc="$HOME/.bashrc"
        fi
    elif [[ "$SHELL" == *"fish"* ]]; then
        shell_rc="$HOME/.config/fish/config.fish"
        export_line="set -gx PATH \$PATH $INSTALL_DIR"
    fi

    if [[ -n "$shell_rc" ]]; then
        # Check if already added
        if ! grep -q "$INSTALL_DIR" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# Drip client" >> "$shell_rc"
            echo "$export_line" >> "$shell_rc"
            print_success "$(msg path_updated): $shell_rc"
        fi
    fi

    print_warning "$(msg path_note)"
}

verify_installation() {
    print_step "$(msg verify_install)"

    local binary_path="$INSTALL_DIR/$BINARY_NAME"
    if [[ "$OS" == "windows" ]]; then
        binary_path="$INSTALL_DIR/$BINARY_NAME.exe"
    fi

    if [[ -x "$binary_path" ]]; then
        local version=$(get_version_from_binary "$binary_path")
        print_success "$(msg verify_ok): $version"
    else
        print_error "$(msg verify_failed)"
        exit 1
    fi
}

# ============================================================================
# Configuration
# ============================================================================
configure_client() {
    echo ""
    read -p "$(msg configure_now) [Y/n]: " config_choice < /dev/tty

    if [[ "$config_choice" =~ ^[Nn]$ ]]; then
        return
    fi

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   $(msg config_title)                          ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""

    local binary_path="$INSTALL_DIR/$BINARY_NAME"

    # Server address
    while true; do
        read -p "$(msg enter_server): " SERVER < /dev/tty
        if [[ -n "$SERVER" ]]; then
            break
        fi
        print_error "$(msg server_required)"
    done

    # Token
    while true; do
        read -p "$(msg enter_token): " TOKEN < /dev/tty
        if [[ -n "$TOKEN" ]]; then
            break
        fi
        print_error "$(msg token_required)"
    done

    # Insecure mode
    read -p "$(msg skip_verify) [y/N]: " insecure_choice < /dev/tty
    INSECURE=""
    if [[ "$insecure_choice" =~ ^[Yy]$ ]]; then
        INSECURE="--insecure"
        print_warning "$(msg insecure_note)"
    fi

    # Save configuration
    "$binary_path" config set --server "$SERVER" --token "$TOKEN" $INSECURE 2>/dev/null || true

    print_success "$(msg config_saved)"
}

# ============================================================================
# Test connection
# ============================================================================
test_connection() {
    echo ""
    read -p "$(msg run_test) [y/N]: " test_choice < /dev/tty

    if [[ ! "$test_choice" =~ ^[Yy]$ ]]; then
        return
    fi

    print_step "$(msg test_running)"

    local binary_path="$INSTALL_DIR/$BINARY_NAME"

    # Try to validate config
    if "$binary_path" config validate 2>/dev/null; then
        print_success "$(msg test_success)"
    else
        print_warning "$(msg test_failed)"
    fi
}

# ============================================================================
# Final output
# ============================================================================
show_completion() {
    local binary_path="$INSTALL_DIR/$BINARY_NAME"

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   $(msg install_complete)                                          ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${CYAN}$(msg usage_title):${NC}"
    echo ""
    echo -e "  ${GREEN}# $(msg usage_http)${NC}"
    echo -e "  ${YELLOW}$BINARY_NAME http 3000${NC}"
    echo ""
    echo -e "  ${GREEN}# $(msg usage_tcp)${NC}"
    echo -e "  ${YELLOW}$BINARY_NAME tcp 5432${NC}"
    echo ""
    echo -e "  ${GREEN}# $(msg usage_config)${NC}"
    echo -e "  ${YELLOW}$BINARY_NAME config show${NC}"
    echo -e "  ${YELLOW}$BINARY_NAME config init${NC}"
    echo ""
    echo -e "  ${GREEN}# $(msg usage_daemon)${NC}"
    echo -e "  ${YELLOW}$BINARY_NAME daemon start http 3000${NC}"
    echo -e "  ${YELLOW}$BINARY_NAME daemon list${NC}"
    echo ""
}

# ============================================================================
# Main
# ============================================================================
main() {
    clear
    print_banner
    select_language

    echo -e "${BOLD}────────────────────────────────────────────${NC}"

    check_os
    check_arch
    check_dependencies
    check_existing_install

    echo ""
    download_binary
    select_install_dir
    install_binary
    update_path
    verify_installation

    # Skip configuration for updates
    if [[ "$IS_UPDATE" != true ]]; then
        configure_client
        test_connection
    else
        echo ""
        local new_version=$(get_version_from_binary "$INSTALL_DIR/$BINARY_NAME")
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   $(msg update_ok)                                                ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        print_info "Version: $new_version"
        echo ""
        return
    fi

    show_completion
}

# Run
main "$@"
