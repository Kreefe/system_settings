#!/bin/bash

# Функция для проверки правильности IP-адреса
function validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        echo "\033[31mОшибка: Неверный IP-адрес."
        exit 1
    fi
}

# Установка vsftpd
echo "\033[32mОбновление списка пакетов..."
sudo apt update

echo "\033[32mУстановка vsftpd..."
sudo apt install -y vsftpd

read -p "\033[32mВведите IP-адрес для параметра pasv_address: " ip_address
validate_ip $ip_address

# Конфигурация vsftpd
echo "\033[32mНастройка конфигурации vsftpd..."
sudo bash -c "cat <<EOF > /etc/vsftpd.conf
# Разрешить локальным пользователям входить в систему
local_enable=YES

# Разрешить запись локальным пользователям
write_enable=YES

# Разрешить пользователю root входить через FTP
userlist_enable=YES
userlist_deny=NO
userlist_file=/etc/vsftpd.user_list

# Настройка разрешений для всех пользователей
chroot_local_user=NO
allow_writeable_chroot=YES

# Пассивный режим (настроить диапазон портов и IP-адрес)
pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10100
pasv_address=$ip_address

# Настройки маски прав для создаваемых файлов и директорий
local_umask=022

# Права доступа к файлам
file_open_mode=0755

# Отключить анонимный доступ
anonymous_enable=NO

# Разрешить загрузку скрытых файлов
force_dot_files=YES

# Отключить баннер сервера
ftpd_banner=Welcome to FTP service.

# Логирование всех действий
xferlog_enable=YES
xferlog_std_format=YES

# Разрешить большее количество соединений
listen=YES
listen_ipv6=NO

# Настройка доступа к домашним директориям
user_sub_token=\$USER
local_root=/

# Настройки таймаутов
idle_session_timeout=600
data_connection_timeout=120

# Настройки ограничения соединений
max_clients=10
max_per_ip=5

# Настройка PAM для входа через FTP
pam_service_name=vsftpd

# Включить TLS для шифрования (опционально)
ssl_enable=NO

# Подключение к файлу списка пользователей
userlist_file=/etc/vsftpd.user_list
EOF"

# Конфигурация пользователей, которым запрещен FTP доступ
echo "\033[32mНастройка списка пользователей для запрещенного доступа..."
sudo bash -c 'cat <<EOF > /etc/ftpusers
daemon
bin
sys
sync
games
man
lp
mail
news
uucp
nobody
EOF'

# Создание и настройка файла списка пользователей для vsftpd
echo "\033[32mСоздание списка пользователей для vsftpd..."
sudo bash -c 'echo "root" > /etc/vsftpd.user_list'

# Перезапуск vsftpd, чтобы применить изменения
echo "\033[32mПерезапуск службы vsftpd..."
sudo systemctl restart vsftpd

echo "\033[32mНастройка завершена!"
