#!/bin/bash

# Проверка прав
if [[ $EUID -ne 0 ]]; then
   echo "Запустите от root"
   exit 1
fi

# Запрос данных
read -p "Введите логин: " PROXY_USER
read -s -p "Введите пароль: " PROXY_PASS
echo
read -p "Введите порт: " PROXY_PORT

# Установка (если еще не стоит)
apt-get update && apt-get install -y dante-server curl

# Пытаемся получить только IPv4 адрес сервера
SERVER_IP=$(curl -s -4 ifconfig.me)
# Определяем основной сетевой интерфейс
INTERFACE=$(ip -4 route get 8.8.8.8 | awk '{print $5; exit}')

# Настройка конфига /etc/danted.conf
cat <<EOF > /etc/danted.conf
logoutput: syslog
user.privileged: root
user.unprivileged: nobody

# Слушать только на IPv4
internal: 0.0.0.0 port = $PROXY_PORT
# Выходить в интернет только через IPv4
external: $INTERFACE

socksmethod: username
clientmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: error
    method: username
}
EOF

# Удаляем пользователя, если он был, и создаем заново
userdel $PROXY_USER 2>/dev/null
useradd -r -s /bin/false $PROXY_USER
echo "$PROXY_USER:$PROXY_PASS" | chpasswd

# Перезапуск
systemctl restart danted

# Ссылки
TG_LINK="https://t.me/socks?server=$SERVER_IP&port=$PROXY_PORT&user=$PROXY_USER&pass=$PROXY_PASS"
RAW_LINK="socks5://$PROXY_USER:$PROXY_PASS@$SERVER_IP:$PROXY_PORT"

clear
echo "=================================================="
echo "✅ SOCKS5 IPv4 прокси запущен!"
echo "=================================================="
echo "IP сервера: $SERVER_IP"
echo "Порт:       $PROXY_PORT"
echo "Пользователь: $PROXY_USER"
echo "=================================================="
echo ""
echo "🔹 Ссылка для Telegram:"
echo "$TG_LINK"
echo ""
echo "🔹 Обычная ссылка (SOCKS5):"
echo "$RAW_LINK"
echo ""
echo "=================================================="