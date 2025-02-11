#!/bin/bash

LOGFILE="/var/log/samba_check.log"
DOMAIN=$(hostname -d)
SERVER=$(hostname -f)
SHORTNAME=$(hostname -s)

clear

# Función para registrar y mostrar mensajes con estado
echo_log() {
    local MESSAGE="$1"
    local STATUS="$2"
    if [ "$STATUS" == "OK" ]; then
        echo -e "\e[32m✔ $MESSAGE\e[0m" | tee -a "$LOGFILE"
    elif [ "$STATUS" == "ERROR" ]; then
        echo -e "\e[31m✖ $MESSAGE\e[0m" | tee -a "$LOGFILE"
    else
        echo -e "[ $(date '+%Y-%m-%d %H:%M:%S') ] $MESSAGE" | tee -a "$LOGFILE"
    fi
}

echo_log "Iniciando comprobaciones de Samba..." "INFO"

# 01 - Verificar el nivel del dominio
echo_log "Verificando el nivel del dominio..." "INFO"
if sudo samba-tool domain level show | tee -a "$LOGFILE"; then
    echo_log "Nivel de dominio verificado correctamente." "OK"
else
    echo_log "Error al verificar el nivel de dominio." "ERROR"
fi

# Verificar resolución de nombres e IP
echo_log "Verificando resolución de nombres e IP..." "INFO"
PING_SUCCESS=true
for HOST in "$DOMAIN" "$SERVER" "$SHORTNAME"; do
    if [ -n "$HOST" ]; then
        if ping -c 3 "$HOST" &>/dev/null; then
            echo_log "Ping exitoso a $HOST." "OK"
        else
            echo_log "Error al hacer ping a $HOST." "ERROR"
            PING_SUCCESS=false
        fi
    else
        echo_log "El valor de HOST está vacío, verifique la configuración del sistema." "ERROR"
        PING_SUCCESS=false
    fi
done

if [ "$PING_SUCCESS" == true ]; then
    echo_log "Resolución de nombres e IP correcta." "OK"
else
    echo_log "Error en la resolución de nombres e IP." "ERROR"
fi

# 02 - Verificar DNS
echo_log "Verificando registros DNS..." "INFO"
if host -t SRV _ldap._tcp."$DOMAIN" && host -t SRV _kerberos._udp."$DOMAIN" && host -t A "$SERVER"; then
    echo_log "Registros DNS verificados correctamente." "OK"
else
    echo_log "Error en la verificación de registros DNS." "ERROR"
fi

# 03 - Verificar Kerberos
echo_log "Verificando autenticación Kerberos..." "INFO"
if sudo smbclient -L "$SERVER" -U administrator && sudo samba-tool testparm; then
    echo_log "Autenticación Kerberos verificada correctamente." "OK"
else
    echo_log "Error en la autenticación Kerberos." "ERROR"
fi

# 04 - Verificar roles del controlador de dominio
echo_log "Verificando roles del controlador de dominio..." "INFO"
if sudo samba-tool fsmo show; then
    echo_log "Roles del controlador de dominio verificados correctamente." "OK"
else
    echo_log "Error al verificar los roles del controlador de dominio." "ERROR"
fi

# 05 - Verificar carpetas compartidas
echo_log "Verificando carpetas compartidas..." "INFO"
if [ -d "/etc/samba/erabiltzaileak" ]; then
    echo_log "La carpeta /etc/samba/erabiltzaileak existe." "OK"
else
    echo_log "ERROR: La carpeta /etc/samba/erabiltzaileak no existe." "ERROR"
fi
sudo systemctl restart samba-ad-dc

# 06 - Verificar usuarios
echo_log "Verificando usuarios en el dominio..." "INFO"
if sudo samba-tool user list | tee -a "$LOGFILE"; then
    echo_log "Usuarios en el dominio verificados correctamente." "OK"
else
    echo_log "Error al verificar los usuarios en el dominio." "ERROR"
fi

# 07 - Verificar perfiles móviles
echo_log "Verificando perfiles móviles..." "INFO"
if [ -d "/etc/samba/profilak" ]; then
    echo_log "La carpeta /etc/samba/profilak existe." "OK"
else
    echo_log "ERROR: La carpeta /etc/samba/profilak no existe." "ERROR"
fi
sudo systemctl restart samba-ad-dc

# 08 - Verificar recursos compartidos
echo_log "Verificando recursos compartidos..." "INFO"
if smbclient -L localhost -U % | tee -a "$LOGFILE"; then
    echo_log "Recursos compartidos verificados correctamente." "OK"
else
    echo_log "Error al verificar los recursos compartidos." "ERROR"
fi

# 09 - Verificar autenticación
echo_log "Verificando autenticación de usuarios..." "INFO"
if sudo smbclient //localhost/netlogon -U administrator -c 'ls' | tee -a "$LOGFILE"; then
    echo_log "Autenticación de usuarios verificada correctamente." "OK"
else
    echo_log "Error en la autenticación de usuarios." "ERROR"
fi

echo_log "Comprobaciones finalizadas. Revisa el log en $LOGFILE." "INFO"
