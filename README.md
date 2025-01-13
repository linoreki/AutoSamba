# AutoSamba

**AutoSamba** es un script automatizado desarrollado por **Linoreki** para simplificar la instalación, configuración y administración de un servidor Samba y Directorio Activo (Active Directory) en sistemas basados en Ubuntu Server. Este script proporciona opciones para configurar servidores, administrar usuarios del AD y gestionar carpetas compartidas, todo desde una interfaz de línea de comandos intuitiva.

---

## Características principales

- **Instalación automática del servidor Samba:** Instala y configura todos los servicios necesarios, incluido Samba, Kerberos y Winbind.
- **Configuración de red simplificada:** Detecta adaptadores de red y configura `netplan` de manera interactiva.
- **Administración de usuarios del Directorio Activo:**
  - Crear usuarios.
  - Cambiar contraseñas.
  - Asignar usuarios a grupos.
  - Eliminar usuarios.
- **Gestión de carpetas compartidas en el AD:** Configura carpetas compartidas con permisos basados en grupos del AD.

---

## Requisitos

1. Ubuntu Server 20.04 o superior.
2. Acceso como usuario con privilegios de `root`.
3. Conexión a Internet para descargar actualizaciones y paquetes necesarios.

---

## Instalación y uso

### Clonación del repositorio

```bash
# Clona el repositorio de AutoSamba desde GitHub
git clone https://github.com/Linoreki/AutoSamba.git
cd AutoSamba
```

### Ejecución del script

El script requiere permisos de `root`. Se recomienda ejecutarlo con `sudo`.

```bash
sudo ./AutoSamba.sh [opciones]
```

### Opciones disponibles

- `-i` : Instala y configura automáticamente el servidor Samba.
- `-u` : Administra usuarios del Directorio Activo.
- `-s` : Gestiona carpetas compartidas del Directorio Activo.
- `-h` : Muestra la ayuda detallada.
- `-f` : Instala la configuración de consola Linoreki/Muxutruk.

---

## Ejemplos de uso

### 1. Instalación del servidor Samba

```bash
sudo ./AutoSamba.sh -i
```
El script solicitará la siguiente información:
- Si desea configurar el `netplan` (y/n).
- Nombre del dominio (por ejemplo, `elorrieta.local`).
- Nombre del servidor (hostname).
- Dirección del nameserver (por ejemplo, `127.0.0.1`).

Tras la instalación, el servidor Samba estará configurado como un Controlador de Dominio (DC).

### 2. Administración de usuarios del Directorio Activo

```bash
sudo ./AutoSamba.sh -u
```
El script permite:
1. Crear un usuario.
2. Cambiar la contraseña de un usuario.
3. Asignar un usuario a un grupo.
4. Eliminar un usuario.

Selecciona la opción deseada y sigue las instrucciones interactivas.

### 3. Gestión de carpetas compartidas en el AD

```bash
sudo ./AutoSamba.sh -s
```
El script solicitará:
- Nombre de la carpeta compartida.
- Ruta absoluta para la carpeta (por ejemplo, `/srv/samba/share`).
- Grupo del AD que tendrá acceso.

Una vez configurada, reiniciará los servicios de Samba para aplicar los cambios.

---

## Detalles técnicos

### Servicios instalados
- Samba.
- Kerberos.
- Winbind.
- NTP para sincronización horaria.

### Archivos configurados
- `/etc/samba/smb.conf`: Configuración principal de Samba.
- `/etc/krb5.conf`: Configuración de Kerberos.
- `/etc/netplan/00-installer-config.yaml`: Configuración de red.

---

## Contribuciones

Se aceptan contribuciones para mejorar este script. Por favor, crea un [pull request](https://github.com/Linoreki/AutoSamba/pulls) o abre un [issue](https://github.com/Linoreki/AutoSamba/issues) para reportar errores o sugerir mejoras.

---

## Licencia

Este proyecto está licenciado bajo la [Licencia MIT](https://opensource.org/licenses/MIT).

