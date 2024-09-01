#!/bin/bash

set -e

# Получаем IP-адрес автоматически
ip_address=$(hostname -I | awk '{print $1}')

# Установка конфигурации APT для автоматического подтверждения
echo -e "\033[32mНастройка автоматического подтверждения для APT...\033[0m"
sudo tee /etc/apt/apt.conf.d/90forceyes > /dev/null <<EOF
APT::Get::Assume-Yes "true";
EOF


# Установка vsftpd
echo -e "\033[32mОбновление списка пакетов...\033[0m"
sudo apt update -qq

echo -e "\033[32mУстановка vsftpd...\033[0m"
if ! dpkg -l | grep -q vsftpd; then
    sudo apt install -y vsftpd
else
    echo -e "\033[33mvsftpd уже установлен.\033[0m"
fi


# Конфигурация vsftpd
echo -e "\033[32mНастройка конфигурации vsftpd...\033[0m"
sudo tee /etc/vsftpd.conf > /dev/null <<EOF
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
EOF

# Конфигурация пользователей, которым запрещен FTP доступ
echo -e "\033[32mНастройка списка пользователей для запрещенного доступа...\033[0m"
sudo tee /etc/ftpusers > /dev/null <<EOF
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
EOF

# Создание и настройка файла списка пользователей для vsftpd
echo -e "\033[32mСоздание списка пользователей для vsftpd...\033[0m"
echo "root" | sudo tee /etc/vsftpd.user_list > /dev/null

# Перезапуск vsftpd, чтобы применить изменения
echo -e "\033[32mПерезапуск службы vsftpd...\033[0m"
sudo systemctl restart vsftpd

echo -e "\033[32mНастройка завершена!\033[0m"
echo -e "\033[32mСоздана С любовью!\033[0m"