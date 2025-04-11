#!/bin/bash

CONFIG="/etc/hysteria/config.yaml"
TMP_SCRIPT=$(mktemp)
REMOTE_URL="https://get.hy2.sh/"

# 下载远程脚本并检查是否成功
download_script() {
    if ! curl -fsSL "$REMOTE_URL" -o "$TMP_SCRIPT"; then
        echo "网络异常，无法下载远程脚本，退出。"
        rm -f "$TMP_SCRIPT"
        exit 1
    fi
}

# 生成YAML配置文件的函数
generate_config() {
    clear
    echo "=============================="
    echo "   请输入配置参数"
    echo "=============================="

    # 获取用户输入
    read -p "监听端口 (默认: 443): " port
    port=${port:-443}
    
    read -p "密码: " password
    read -p "邮箱: " email
    read -p "Cloudflare上指向本机的域名: " domain
    read -p "CloudflareApiToken: " token
    read -p "伪装网站 (默认：https://quic.nginx.org/): " url
    url=${url:-https://quic.nginx.org/}

    # 创建YAML配置文件
    cat > "$CONFIG" <<EOF
hop: $hop
listen: :$port
speedTest: true
acme:
  domains:
    - $domain
  email: $email
  type: dns
  dns:
    name: cloudflare
    config:
      cloudflare_api_token: $token
auth:
  type: password
  password: $password
masquerade:
  type: proxy
  proxy:
    url: $url
    rewriteHost: true
EOF

    echo "配置文件生成完毕！"
    read -n1 -r -p "按任意键返回主菜单..."
}

# 展示配置信息
show_config() {
    clear
    if [ ! -f "$CONFIG" ]; then
        echo "未找到配置文件（$CONFIG）"
    else
        echo "=============================="
        echo "配置文件：$CONFIG"
        echo "=============================="
        
        # 检查 yq 是否安装
        if ! command -v yq &> /dev/null; then
            echo "未找到 yq 命令，无法读取配置信息"
        else
            domain=$(yq -r .acme.domains[0] "$CONFIG")
            port=$(yq -r .listen "$CONFIG" | cut -c2-)
            password=$(yq -r .auth.password "$CONFIG")
            link="hysteria2://$password@$domain:$port/?insecure=0&sni=$domain"
            
            echo "域名: $domain"
            echo "端口: $port"
            echo "密码: $password"
            echo "=============================="
            echo "$link"
            echo "=============================="
            
            # 检查 qrencode 是否安装
            if ! command -v qrencode &> /dev/null; then
                echo "未找到 qrencode 命令，无法生成二维码"
            else
                echo "$link" | qrencode -t ANSIUTF8
            fi
        fi
    fi

    read -n1 -r -p "按任意键返回主菜单..."
}

# 安装/升级 Hysteria2
install_or_upgrade() {
    clear
    echo "正在安装或升级 Hysteria2..."
    bash "$TMP_SCRIPT"
    sysctl -w net.core.rmem_max=16777216
    sysctl -w net.core.wmem_max=16777216
    local dir="/etc/systemd/system/hysteria-server.service.d/"
    mkdir -p "$dir"
    cat > "$dir/priority.conf" <<EOF
[Service]
CPUSchedulingPolicy=rr
CPUSchedulingPriority=99
EOF
    read -n1 -r -p "操作完成，请按任意键返回主菜单..."
}

# 卸载 Hysteria2
uninstall() {
    clear
    echo "正在卸载 Hysteria2..."
    bash "$TMP_SCRIPT" --remove
    read -n1 -r -p "操作完成，请按任意键返回主菜单..."
}

# 启动服务
start_service() {
    clear
    systemctl daemon-reload
    systemctl enable hysteria-server.service
    systemctl restart hysteria-server.service
    echo "服务启动完毕！"
    read -n1 -r -p "按任意键返回主菜单..."
}

# 主菜单
main_menu() {
    while true; do
        clear
        echo "=============================="
        echo "   Hysteria2 管理脚本菜单"
        echo "=============================="
        echo "0. 卸载 Hysteria2"
        echo "1. 安装或升级 Hysteria2"
        echo "2. 生成配置文件"
        echo "3. 启动服务"
        echo "4. 显示配置信息"
        echo "5. 退出"
        echo "=============================="
        read -p "请输入选择 (0/1/2/3/4/5): " choice

        case $choice in
            0) uninstall ;;
            1) install_or_upgrade ;;
            2) generate_config ;;
            3) start_service ;;
            4) show_config ;;
            5) 
                echo "退出脚本..."
                rm -f "$TMP_SCRIPT"
                clear
                exit 0
                ;;
            *)
                echo "无效选择，请输入 0-5。"
                read -n1 -r -p "按任意键返回主菜单..."
                ;;
        esac
    done
}

# 脚本开始
download_script
main_menu
