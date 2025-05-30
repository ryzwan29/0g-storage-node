#!/bin/bash

show_menu() {
    echo -e "\033[1;32m
██████╗ ██╗   ██╗██████╗ ██████╗ ██████╗ ██████╗  █████╗ 
██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗╚════██╗██╔══██╗
██████╔╝ ╚████╔╝ ██║  ██║██║  ██║██║  ██║ █████╔╝╚██████║
██╔══██╗  ╚██╔╝  ██║  ██║██║  ██║██║  ██║██╔═══╝  ╚═══██║
██║  ██║   ██║   ██████╔╝██████╔╝██████╔╝███████╗ █████╔╝
╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝ ╚════╝ 
    \033[0m"
    echo -e "\033[1;34m====================================================\033[1;34m"
    echo -e "\033[1;34m@Ryddd29 | Testnet, Node Runer, Developer, Retrodrop\033[1;34m"
    echo
    echo "> 1. Fast Install (Recommended)"
    echo "> 2. Manual Menu"
    echo
}

show_submenu() {
    echo "===== Manual Installation Menu ====="
    echo "> 1. Install 0g-storage-node"
    echo "> 2. Update 0g-storage-node"
    echo "> 3. Turbo Mode (Reset Config.toml & Systemctl)"
    echo "> 4. Select RPC Endpoint"
    echo "> 5. Set Miner Key"
    echo "> 6. Snapshot Install"
    echo "> 7. Node Run & Show Logs"
    echo "> 8. Exit to Main Menu"
    echo "> 9. Exit (Ctrl+C)"
    echo "===================================="
}

install_node() {
    echo "Installing 0g-storage-node..."
    rm -rf $HOME/0g-storage-node
    sudo apt-get update
    sudo apt-get install -y cargo git clang cmake build-essential openssl pkg-config libssl-dev
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    git clone -b v1.0.0 https://github.com/0glabs/0g-storage-node.git
    cd $HOME/0g-storage-node
    git stash
    git fetch --all --tags
    git checkout 347cd3e
    git submodule update --init
    cargo build --release
    rm -rf $HOME/0g-storage-node/run/config.toml
    curl -o $HOME/0g-storage-node/run/config.toml https://raw.githubusercontent.com/ryzwan29/0g-storage-node/refs/heads/main/run/config.toml
    sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    echo "Installation completed."
}

update_node() {
    echo "Updating 0g-storage-node..."
    sudo systemctl stop zgs
    cp $HOME/0g-storage-node/run/config.toml $HOME/0g-storage-node/run/config.toml.backup
    cd $HOME/0g-storage-node
    git stash
    git fetch --all --tags
    git checkout 347cd3e
    git submodule update --init
    cargo build --release
    cp $HOME/0g-storage-node/run/config.toml.backup $HOME/0g-storage-node/run/config.toml
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    echo "Node update completed."
}

reset_config_systemctl() {
    echo "Resetting Config.toml and Systemctl (Turbo Mode)..."
    rm -rf $HOME/0g-storage-node/run/config.toml
    curl -o $HOME/0g-storage-node/run/config.toml https://raw.githubusercontent.com/ryzwan29/0g-storage-node/refs/heads/main/run/config.toml
    sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    echo "Config.toml and Systemctl reset completed."
}

select_rpc() {
    echo "Select an RPC Endpoint:"
    echo "1. https://evmrpc-testnet.0g.ai"
    read -p "Enter your choice (1): " rpc_choice
    case $rpc_choice in
        1) rpc="https://evmrpc-testnet.0g.ai" ;;
        *) echo "Invalid choice. Using default."; rpc="https://evmrpc-testnet.0g.ai" ;;
    esac
    sed -i "s|^blockchain_rpc_endpoint = .*|blockchain_rpc_endpoint = \"$rpc\"|g" ~/0g-storage-node/run/config.toml
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    echo "RPC Endpoint set to $rpc."
}

set_miner_key() {
    echo "Please enter your Miner Key:"
    read miner_key
    sed -i "s|^miner_key = .*|miner_key = \"$miner_key\"|g" ~/0g-storage-node/run/config.toml
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    echo "Miner Key updated."
}
snapshot_install() {
    echo "Installing snapshot (Turbo Mode)..."
    source <(curl -s https://raw.githubusercontent.com/zstake-xyz/test/refs/heads/main/0g_zgs_standard_snapshot.sh)
    echo "Snapshot installation completed."
}

run_and_show_logs() {
    echo "Starting node and displaying logs for 3 minutes (with colors)..."
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    sudo systemctl start zgs

    logfile="$HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)"

    if [ ! -f "$logfile" ]; then
        echo "Log file not found: $logfile"
        return
    fi

    timeout 180 tail -f "$logfile" | awk '
    /INFO/ {print "\033[0;32m" $0 "\033[0m"; next}
    /WARN/ {print "\033[1;33m" $0 "\033[0m"; next}
    /ERROR/ {print "\033[0;31m" $0 "\033[0m"; next}
    {print $0}
    '

    echo -e "\nLog monitoring ended. Returning to main menu..."
}

fast_install() {
    install_node
    update_node
    select_rpc
    set_miner_key
    snapshot_install
    run_and_show_logs
}

while true; do
    show_menu
    read -p "Select an option (1-2): " main_choice
    case $main_choice in
        1) fast_install ;;
        2)
            while true; do
                show_submenu
                read -p "Select an option (1-8): " sub_choice
                case $sub_choice in
                    1) install_node ;;
                    2) update_node ;;
                    3) reset_config_systemctl ;;
                    4) select_rpc ;;
                    5) set_miner_key ;;
                    6) snapshot_install ;;
                    7) run_and_show_logs ;;
                    8) break ;;
                    9) echo "Exiting..."; exit 0 ;;
                    *) echo "Invalid option. Please try again." ;;
                esac
                echo ""
            done
            ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    echo ""
done
