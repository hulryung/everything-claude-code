#!/bin/bash

# Everything Claude Code - Installation Script
# https://github.com/affaanmustafa/everything-claude-code
# Language-agnostic version with multi-language support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directory
CLAUDE_DIR="$HOME/.claude"
CLAUDE_JSON="$HOME/.claude.json"

# Backup directory with timestamp
BACKUP_DIR="$CLAUDE_DIR/backups/$(date +%Y%m%d_%H%M%S)"

# Available languages
AVAILABLE_LANGUAGES=("typescript" "python" "go" "rust" "java" "csharp" "ruby" "php" "swift" "cpp")

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        Everything Claude Code - Universal Installer          ║"
    echo "║     Language-agnostic configurations for Claude Code         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running from the correct directory
check_source_files() {
    if [[ ! -d "$SCRIPT_DIR/agents" ]] || [[ ! -d "$SCRIPT_DIR/commands" ]]; then
        print_error "Source files not found. Please run this script from the repository directory."
        exit 1
    fi
}

# Create backup of existing configurations
create_backup() {
    local has_backup=false

    if [[ -d "$CLAUDE_DIR/agents" ]] || [[ -d "$CLAUDE_DIR/commands" ]] || \
       [[ -d "$CLAUDE_DIR/skills" ]] || [[ -d "$CLAUDE_DIR/rules" ]] || \
       [[ -f "$CLAUDE_DIR/CLAUDE.md" ]] || [[ -f "$CLAUDE_DIR/settings.json" ]]; then

        print_step "Creating backup of existing configurations..."
        mkdir -p "$BACKUP_DIR"

        for item in agents commands skills rules CLAUDE.md settings.json; do
            if [[ -e "$CLAUDE_DIR/$item" ]]; then
                cp -r "$CLAUDE_DIR/$item" "$BACKUP_DIR/"
                has_backup=true
            fi
        done

        if [[ "$has_backup" == true ]]; then
            print_success "Backup created at: $BACKUP_DIR"
        fi
    fi
}

# Install a specific component
install_component() {
    local component=$1
    local source_dir="$SCRIPT_DIR/$component"
    local target_dir="$CLAUDE_DIR/$component"

    if [[ -d "$source_dir" ]]; then
        mkdir -p "$target_dir"
        cp -r "$source_dir"/* "$target_dir/"
        local count=$(find "$source_dir" -type f | wc -l)
        print_success "Installed $component ($count files)"
    else
        print_warning "Source directory not found: $source_dir"
    fi
}

# Install language-specific skills
install_language_skills() {
    local languages=("$@")

    if [[ ${#languages[@]} -eq 0 ]]; then
        return
    fi

    local skills_dir="$CLAUDE_DIR/skills/languages"
    mkdir -p "$skills_dir"

    for lang in "${languages[@]}"; do
        local source_file="$SCRIPT_DIR/skills/languages/${lang}.md"
        if [[ -f "$source_file" ]]; then
            cp "$source_file" "$skills_dir/"
            print_success "Installed language skill: $lang"
        else
            print_warning "Language skill not found: $lang"
        fi
    done
}

# Install CLAUDE.md
install_claude_md() {
    if [[ -f "$SCRIPT_DIR/examples/user-CLAUDE.md" ]]; then
        cp "$SCRIPT_DIR/examples/user-CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
        print_success "Installed CLAUDE.md (user-level configuration)"
    fi
}

# Install hooks
install_hooks() {
    if [[ -f "$SCRIPT_DIR/hooks/hooks.json" ]]; then
        if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
            print_warning "settings.json already exists."
            echo -e "    Hooks configuration saved to: ${CYAN}$CLAUDE_DIR/hooks.json.example${NC}"
            cp "$SCRIPT_DIR/hooks/hooks.json" "$CLAUDE_DIR/hooks.json.example"
            echo "    Please manually merge hooks into your settings.json"
        else
            cp "$SCRIPT_DIR/hooks/hooks.json" "$CLAUDE_DIR/settings.json"
            print_success "Installed hooks to settings.json"
        fi
    fi
}

# Show MCP configuration instructions
show_mcp_instructions() {
    echo ""
    print_step "MCP Server Configuration"
    echo -e "    MCP servers require API keys and manual configuration."
    echo -e "    Reference file copied to: ${CYAN}$CLAUDE_DIR/mcp-servers.example.json${NC}"
    echo ""
    echo -e "    To configure MCP servers:"
    echo -e "    1. Open ${CYAN}~/.claude.json${NC}"
    echo -e "    2. Add desired servers from the example file"
    echo -e "    3. Replace ${YELLOW}YOUR_*_HERE${NC} placeholders with actual values"
    echo ""

    if [[ -f "$SCRIPT_DIR/mcp-configs/mcp-servers.json" ]]; then
        cp "$SCRIPT_DIR/mcp-configs/mcp-servers.json" "$CLAUDE_DIR/mcp-servers.example.json"
    fi
}

# Language selection menu
select_languages() {
    echo ""
    echo -e "${CYAN}Select programming languages to install (space to toggle, enter to confirm):${NC}"
    echo ""

    local selected=()
    local options=("${AVAILABLE_LANGUAGES[@]}")
    local checked=()

    # Initialize all as unchecked
    for i in "${!options[@]}"; do
        checked[$i]=false
    done

    # Simple selection
    echo "Available languages:"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    echo "  a) All languages"
    echo "  n) None (skip language-specific skills)"
    echo ""

    read -p "Enter choices (e.g., '1 2 3' or 'a' for all): " choices

    if [[ "$choices" == "a" ]] || [[ "$choices" == "A" ]]; then
        selected=("${options[@]}")
    elif [[ "$choices" != "n" ]] && [[ "$choices" != "N" ]] && [[ -n "$choices" ]]; then
        for choice in $choices; do
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#options[@]} ]]; then
                selected+=("${options[$((choice-1))]}")
            fi
        done
    fi

    SELECTED_LANGUAGES=("${selected[@]}")
}

# Interactive menu for selective installation
show_menu() {
    echo ""
    echo -e "${CYAN}Select installation type:${NC}"
    echo ""
    echo "  1) Full installation (recommended)"
    echo "     - All components + language selection"
    echo ""
    echo "  2) Core only (language-agnostic)"
    echo "     - Universal patterns without language-specific skills"
    echo ""
    echo "  3) Custom selection"
    echo "     - Choose individual components"
    echo ""
    echo "  4) Cancel"
    echo ""
    read -p "Enter your choice [1-4]: " choice
    echo ""
}

# Custom selection menu
custom_selection() {
    local install_agents=false
    local install_commands=false
    local install_skills=false
    local install_rules=false
    local install_claude_md_flag=false
    local install_hooks_flag=false

    echo -e "${CYAN}Select components (y/n):${NC}"
    echo ""

    read -p "  Install agents? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && install_agents=true

    read -p "  Install commands? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && install_commands=true

    read -p "  Install skills (universal patterns)? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && install_skills=true

    read -p "  Install rules? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && install_rules=true

    read -p "  Install CLAUDE.md (user config)? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && install_claude_md_flag=true

    read -p "  Install hooks? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && install_hooks_flag=true

    echo ""

    [[ "$install_agents" == true ]] && install_component "agents"
    [[ "$install_commands" == true ]] && install_component "commands"

    if [[ "$install_skills" == true ]]; then
        # Install base skills (without languages subdirectory first)
        mkdir -p "$CLAUDE_DIR/skills"
        for file in "$SCRIPT_DIR/skills"/*.md; do
            if [[ -f "$file" ]]; then
                cp "$file" "$CLAUDE_DIR/skills/"
            fi
        done
        print_success "Installed skills (universal patterns)"

        # Ask about language-specific skills
        read -p "  Install language-specific skills? [y/N]: " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            select_languages
            install_language_skills "${SELECTED_LANGUAGES[@]}"
        fi
    fi

    [[ "$install_rules" == true ]] && install_component "rules"
    [[ "$install_claude_md_flag" == true ]] && install_claude_md
    [[ "$install_hooks_flag" == true ]] && install_hooks
}

# Full installation
full_installation() {
    install_component "agents"
    install_component "commands"

    # Install base skills
    mkdir -p "$CLAUDE_DIR/skills"
    for file in "$SCRIPT_DIR/skills"/*.md; do
        if [[ -f "$file" ]]; then
            cp "$file" "$CLAUDE_DIR/skills/"
        fi
    done
    print_success "Installed skills (universal patterns)"

    # Language selection
    select_languages
    install_language_skills "${SELECTED_LANGUAGES[@]}"

    install_component "rules"
    install_claude_md
    install_hooks
    show_mcp_instructions
}

# Core only installation (no language-specific skills)
core_installation() {
    install_component "agents"
    install_component "commands"

    # Install base skills without languages
    mkdir -p "$CLAUDE_DIR/skills"
    for file in "$SCRIPT_DIR/skills"/*.md; do
        if [[ -f "$file" ]]; then
            cp "$file" "$CLAUDE_DIR/skills/"
        fi
    done
    print_success "Installed skills (universal patterns)"

    install_component "rules"
    install_claude_md
    install_hooks
    show_mcp_instructions
}

# Show post-installation summary
show_summary() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    Installation Complete!                       ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Installed to: ${CYAN}$CLAUDE_DIR${NC}"
    echo ""

    if [[ ${#SELECTED_LANGUAGES[@]} -gt 0 ]]; then
        echo -e "${CYAN}Installed language skills:${NC}"
        for lang in "${SELECTED_LANGUAGES[@]}"; do
            echo "  - $lang"
        done
        echo ""
    fi

    echo -e "${YELLOW}Important:${NC}"
    echo "  - Read the guide before using: https://x.com/affaanmustafa"
    echo "  - Customize CLAUDE.md for your preferences"
    echo "  - Configure MCP servers with your API keys"
    echo ""
    echo -e "${CYAN}Directory structure:${NC}"
    echo "  ~/.claude/"
    echo "  ├── agents/           # Specialized subagents"
    echo "  ├── commands/         # Slash commands"
    echo "  ├── skills/           # Universal patterns"
    echo "  │   └── languages/    # Language-specific patterns"
    echo "  ├── rules/            # Mandatory guidelines"
    echo "  ├── CLAUDE.md         # User-level config"
    echo "  └── settings.json     # Hooks configuration"
    echo ""
    echo -e "${CYAN}Quick start:${NC}"
    echo "  - Use /plan to create implementation plans"
    echo "  - Use /tdd for test-driven development"
    echo "  - Use /code-review for code reviews"
    echo ""
    echo -e "${CYAN}Supported languages (skills):${NC}"
    echo "  TypeScript/JavaScript, Python, Go, Rust, Java/Kotlin,"
    echo "  C#/.NET, Ruby, PHP, Swift, C/C++"
    echo ""
    echo -e "${CYAN}Hooks auto-format & lint support:${NC}"
    echo "  TS/JS, Python, Go, Rust, Ruby, Java, Kotlin, C#, PHP, Swift, C/C++"
    echo ""
}

# Uninstall function
uninstall() {
    echo ""
    print_warning "This will remove all Everything Claude Code configurations."
    read -p "Are you sure? [y/N]: " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        create_backup

        for item in agents commands skills rules; do
            if [[ -d "$CLAUDE_DIR/$item" ]]; then
                rm -rf "$CLAUDE_DIR/$item"
                print_success "Removed $item"
            fi
        done

        print_warning "CLAUDE.md and settings.json preserved (may contain custom settings)"
        print_success "Uninstallation complete. Backup saved to: $BACKUP_DIR"
    else
        print_step "Uninstallation cancelled."
    fi
}

# Main function
main() {
    print_banner
    check_source_files

    # Initialize
    SELECTED_LANGUAGES=()

    # Parse command line arguments
    if [[ "$1" == "--uninstall" ]] || [[ "$1" == "-u" ]]; then
        uninstall
        exit 0
    fi

    if [[ "$1" == "--full" ]] || [[ "$1" == "-f" ]]; then
        mkdir -p "$CLAUDE_DIR"
        create_backup
        full_installation
        show_summary
        exit 0
    fi

    if [[ "$1" == "--core" ]] || [[ "$1" == "-c" ]]; then
        mkdir -p "$CLAUDE_DIR"
        create_backup
        core_installation
        show_summary
        exit 0
    fi

    if [[ "$1" == "--lang" ]] || [[ "$1" == "-l" ]]; then
        shift
        SELECTED_LANGUAGES=("$@")
        mkdir -p "$CLAUDE_DIR"
        create_backup
        full_installation
        show_summary
        exit 0
    fi

    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./install.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -f, --full           Full installation with language selection (interactive)"
        echo "  -c, --core           Core installation (language-agnostic only)"
        echo "  -l, --lang LANGS     Full installation with specific languages"
        echo "                       Example: ./install.sh -l typescript python"
        echo "  -u, --uninstall      Remove installed configurations"
        echo "  -h, --help           Show this help message"
        echo ""
        echo "Available languages: ${AVAILABLE_LANGUAGES[*]}"
        echo ""
        echo "Without options, runs interactive installer."
        exit 0
    fi

    # Interactive mode
    show_menu

    mkdir -p "$CLAUDE_DIR"

    case $choice in
        1)
            create_backup
            full_installation
            show_summary
            ;;
        2)
            create_backup
            core_installation
            show_summary
            ;;
        3)
            create_backup
            custom_selection
            show_mcp_instructions
            show_summary
            ;;
        4)
            print_step "Installation cancelled."
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please run the script again."
            exit 1
            ;;
    esac
}

main "$@"
