#!/bin/bash

# Colores para mensajes
RED="\e[31m"
GREEN="\e[32m"
NC="\e[0m"

# Función para mostrar ayuda
function mostrar_ayuda() {
    echo -e "${GREEN}Uso:${NC} sudo ./AutoSamba.sh [opciones]\n"
    echo "Opciones:"
    echo "  -i        Instala y configura automáticamente el servidor Samba"
    echo "  -u        Administra usuarios del Directorio Activo"
    echo "  -s        Administra carpetas compartidas del Directorio Activo"
    echo "  -h        Muestra esta ayuda"
    echo "  -f        Instala la configuracion personal de consola de Linoreki"
    exit 0
}

# Verificar si se ejecuta como root
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}Por favor, ejecuta este script como root.${NC}"
    exit 1
fi
function shell_config() {
    echo "Configurando la consola de Linoreki/Muxutruk"
    sudo apt install fish tmux -y
    chsh -s /usr/bin/fish
    sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply Muxutruk2
    echo "[!] Presiona CTRL + B + I para instalar la configuración en tmux"
    echo "Configuración de consola de Linoreki completada."
}
# Función para listar adaptadores de red
function listar_adaptadores() {
    echo -e "${GREEN}Adaptadores de red detectados:${NC}"
    ip -o link show | awk -F': ' '{print NR". "$2}'
}

# Función para administrar usuarios en el AD
function administrar_usuarios_ad() {
    echo -e "${GREEN}Administración de usuarios del Directorio Activo...${NC}"
    echo "Opciones:"
    echo "  1. Crear un usuario"
    echo "  2. Cambiar la contraseña de un usuario"
    echo "  3. Asignar un usuario a un grupo"
    echo "  4. Eliminar un usuario"
    echo "  5. Listar usuarios y grupos AD"
    echo "  6. Crear Grupos"
    echo "  7. eliminar Grupos"
    read -p "Selecciona una opción: " OPCION_USUARIO

    case $OPCION_USUARIO in
        1)
            read -p "Ingresa el nombre del nuevo usuario: " USERNAME
            read -s -p "Ingresa la contraseña para el usuario: " PASSWORD
            echo
            samba-tool user create "$USERNAME" "$PASSWORD" --given-name="$USERNAME"
            echo -e "${GREEN}Usuario $USERNAME creado exitosamente en el AD.${NC}"
            ;;
        2)
            read -p "Ingresa el nombre del usuario: " USERNAME
            read -s -p "Ingresa la nueva contraseña: " PASSWORD
            echo
            samba-tool user setpassword "$USERNAME" --newpassword="$PASSWORD"
            echo -e "${GREEN}Contraseña del usuario $USERNAME actualizada exitosamente.${NC}"
            ;;
        3)
            samba-tool user list
            read -p "Ingresa el nombre del usuario: " USERNAME
            samba-tool group list
            read -p "Ingresa el nombre del grupo: " GROUPNAME
            samba-tool group addmembers "$GROUPNAME" "$USERNAME"
            echo -e "${GREEN}Usuario $USERNAME añadido al grupo $GROUPNAME exitosamente.${NC}"
            ;;
        4)
            read -p "Ingresa el nombre del usuario a eliminar: " USERNAME
            samba-tool user delete "$USERNAME"
            echo -e "${GREEN}Usuario $USERNAME eliminado del AD exitosamente.${NC}"
            ;;
        5)
            samba-tool user list
            samba-tool group list
            ;;
        6)
            read -p "Ingresa el nombre del grupo que deseas crear: " GROUPNAME
            samba-tool group create "$GROUPNAME"
            echo -e  "${GREEN}grupo $GROUPNAME creado exitosamente.${NC}"
            ;;
        7)
            read -p "Ingresa el nombre del grupo a eliminar: " GROUPNAME
            samba-tool group delete "$GROUPNAME"
            echo -e "${GREEN}grupo $GROUPNAME eliminado del AD exitosamente.${NC}"
            ;;
        *)
            echo -e "${RED}Opción no válida.${NC}"
            ;;
    esac
}

# Función para administrar carpetas compartidas en el AD
function administrar_carpetas_ad() {
    echo -e "${GREEN}Administración de carpetas compartidas del Directorio Activo...${NC}"
    read -p "Ingresa el nombre de la carpeta compartida: " SHARED_FOLDER
    read -p "Ingresa el directorio absoluto para la carpeta (por ejemplo, /srv/samba/share): " FOLDER_PATH
    read -p "Ingresa los permisos de la carpeta(por ejemplo, 2770): " PERMISIONS
    echo -e "Lista de grupos en el AD.${NC}"
    samba-tool group list
    read -p "${GREEN}Ingresa el grupo del AD que tendrá acceso: " GROUPNAME

    mkdir -p "$FOLDER_PATH"
    chmod "$PERMISIONS" "$FOLDER_PATH"
    chgrp "$GROUPNAME" "$FOLDER_PATH"

    cat << EOF >> /etc/samba/smb.conf
[$SHARED_FOLDER]
   path = $FOLDER_PATH
   valid users = @$GROUPNAME
   guest ok = no
   writable = yes
   browsable = no
   read only = no
EOF

    echo -e "${GREEN}Carpeta compartida $SHARED_FOLDER configurada exitosamente con acceso para el grupo $GROUPNAME.${NC}"
    systemctl restart smbd
}

# Leer las opciones
while getopts "iushf" opt; do
    case ${opt} in
        i)
            echo -e "${GREEN}Iniciando configuración...${NC}"

            # Variables de configuración
            read -p "¿Quieres configurar el netplan? (y/n): " CONFIG_NETPLAN
            read -p "Ingresa el nombre del dominio (por ejemplo, elorrieta.local): " DOMAIN_NAME
            read -p "Ingresa el nombre del servidor (hostname): " HOSTNAME
            read -p "Ingresa la dirección del nameserver (por ejemplo, 127.0.0.1): " NAMESERVER

            # Actualizar hostname
            echo "Configurando el nombre del host..."
            echo "$HOSTNAME" > /etc/hostname

            # Configuración de netplan (si aplica)
            if [[ "$CONFIG_NETPLAN" == "y" || "$CONFIG_NETPLAN" == "Y" ]]; then
                echo "Configurando netplan..."
                listar_adaptadores
                read -p "Selecciona el número del adaptador de red que deseas configurar: " ADAPTADOR_NUM
                ADAPTADOR=$(ip -o link show | awk -F': ' "NR==${ADAPTADOR_NUM} {print \$2}")

                read -p "Ingresa tu dirección IP (por ejemplo, 192.168.1.100): " IP
                read -p "Ingresa tu gateway: " GATEWAY

                cat << EOF > /etc/netplan/50-cloud-init.yaml
network:
    ethernets:
      $ADAPTADOR_NUM:
        addresses:
        - $IP/24
        nameservers:
          addresses:
            - $NAMESERVER
        routes:
            - to: default
              via: $GATEWAY
    version: 2
EOF
                netplan apply
            fi
            # Configuración de hostname
            if [[ "$CONFIG_HOSTNAME" == "y" || "$CONFIG_HOSTNAME" == "Y" ]]; then
                echo "Configurando Hostname..."
                echo "$HOSTNAME" > /etc/hostname
            fi           

            # Actualizar e instalar paquetes necesarios
            echo "Actualizando los paquetes..."
            apt-get update

            echo "Configurando la zona horaria..."
            dpkg-reconfigure -f noninteractive tzdata

            echo "Instalando servicios necesarios..."
            apt install -y ntp samba smbclient krb5-config krb5-user winbind

            # Configuración de Samba
            echo "Renombrando la configuración antigua de Samba..."
            mv /etc/samba/smb.conf /etc/samba/smb.conf.old

            echo "Provisionando el dominio Samba..."
            samba-tool domain provision --use-rfc2307 --realm=${DOMAIN_NAME^^} --domain=${DOMAIN_NAME%%.*} --server-role=dc

            echo "Configurando Kerberos..."
            cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
            sed -i 's/false/true/g' /etc/krb5.conf

            echo "Configurando la cuenta de administrador para no expirar..."
            samba-tool user setexpiry administrator --noexpiry

            echo "Deteniendo y deshabilitando servicios innecesarios..."
            systemctl stop smbd nmbd winbind systemd-resolved
            systemctl disable smbd nmbd winbind systemd-resolved

            echo "Activando el servicio de controlador de dominio Samba..."
            systemctl unmask samba-ad-dc
            systemctl start samba-ad-dc
            systemctl enable samba-ad-dc

            echo "Verificando configuración de resolv.conf..."
            echo -e "#domain ${DOMAIN_NAME}\nnameserver ${NAMESERVER}" > /etc/resolv.conf

            echo "Autenticando al administrador..."
            kinit administrator@${DOMAIN_NAME^^}
            klist

            echo -e "${GREEN}La instalación y configuración han finalizado correctamente.${NC}"
            ;;
        u)
            administrar_usuarios_ad
            ;;
        s)
            administrar_carpetas_ad
            ;;
        h)
            mostrar_ayuda
            ;;
        f)
            shell_config
            ;;
        *)
            echo -e "${RED}Opción no reconocida.${NC}"
            mostrar_ayuda
            ;;
    esac
    exit 0
done

mostrar_ayuda
