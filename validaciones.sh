#!/bin/bash
#VARIABLES QUE SON USADAS EN MAS DE UNA FUNCION ESTARAN EN LA PARTE SUPERIOR DEL SCRIPT, VARIABLES QUE SOLO SE USEN EN LA FUNCION SE ENCONTRARAN EN LA FUNCION.

#VARIABLES DE CONFIGURACIÓN

#************** DATOS ZABBIX PROXY *******************
ZABBIX_SERVER_IP_1="zabbix01.nubecentral.com"
ZABBIX_SERVER_IP_2="zabbix02.nubecentral.com"
#VARIABLE PARA ALMANCENAR LOS LOGS EN ARCHIVO txt
LOG_FILE="$HOME/script_logProxyAgent.txt"
#ARCHIVO PARA GUARDAR LA VARIABLE FLAG EN EL QUE SE LEVANTARA UNA BANDERA SI YA SE EJECUTO ANTERIORMENTE EL SCRIPT POR LO TANTO NO FUNCIONARA EL SCRIPT.
flag_file="/var/tmp/mi_script_ejecutado.flag"


function log() {
  #VARIABLE PARA LA FUNCION LOG SE USO $HOME PARA QUE CUALQUIER USUARIO QUE EJECUTE EL ARCHIVO CREE UN ARCHIVO LOG EN SU DIRECTORIO Y NO TENER PROBLEMAS DE PERMISOS
  local message="$1"
  echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}


function validaciones () {
#FUNCION PARA ENGLOBAR VALIDACIONES PREVIAS ANTES DE INSTALAR EL PROXY_ZABBIX Y AGENT2

# VALIDAR QUE SE ESTE EJECUTANDO CON PERMISOS ROOT

  log "=============================="
  log "Verificacion de root"
  log "=============================="
  if [ "$(whoami)" != "root" ]; then
    log "DEBE SER ROOT PARA INICIAR ESTE SCRIPT"
    exit 1
  else
    log "INICIANDO EJECUCION DE SCRIPT"
  fi
  
# ARCHIVO PARA GUARDAR LA VARIABLE FLAG EN EL QUE SE LEVANTARA UNA BANDERA SI YA SE EJECUTO ANTERIORMENTE EL SCRIPT POR LO TANTO NO FUNCIONARA EL SCRIPT.
  flag_file="/var/tmp/mi_script_ejecutado.flag"
# Comprobamos si el archivo de marca existe
  if [ -f "$flag_file" ]; then
    echo "El script ya ha sido ejecutado anteriormente de forma exitosa. Por lo que no es necesaria ejecutar nuevamente este Script"
    exit 0  # Sale sin hacer nada si el script ya se ejecutó
  fi
  
# OBTENER LA VERSION DE UBUNTU
# REQUIRED_OS_VERSION="22.04"
#  local os_version
#  os_version=$(lsb_release -sr)
 
#  if [[ "$os_version" != "$REQUIRED_OS_VERSION" ]]; then
#    log "Error: Este script requiere Ubuntu $REQUIRED_OS_VERSION. Actualmente estás usando Ubuntu $os_version."
#    exit 1
#  else
#    log "Versión del sistema operativo válida: Ubuntu $os_version."
#  fi

#VALIDACION DE CONECTIVIDAD HACIA EL ZABBIX SERVER.

  log "=============================="
  log "Verificando conectividad a ZABBIX_SERVER_IP en el puertos 10051..."  
  log "=============================="

  # Verificar si nc está instalado
  if ! command -v nc >/dev/null; then
      log "nc no está instalado. Intentando instalar..."

    # Intentar instalar netcat usando apt
    if  apt install -y netcat; then
      log "nc instalado correctamente."
    else
      log "Error: No se pudo instalar nc. Por favor, instálelo manualmente y ejecute el script de nuevo"
      exit 1
    fi
  fi

  nc -zv $ZABBIX_SERVER_IP_1 10051 || { log "Error: No se puede conectar al puerto 10051"; exit 1; }
#  nc -zv $ZABBIX_SERVER_IP_2 10051 || { log "Error: No se puede conectar al puerto 10051"; exit 1; }
  log "Conectividad verificada."

# OBTENER LA DIRECCIÓN IP ACTUAL DEL SISTEMA
  IP_ACTUAL=$(ip route get 1 | awk '{print $(NF-2);exit}')
  if [ -z "$IP_ACTUAL" ]; then
      log "Error: No se pudo obtener la IP del servidor."
	  exit 1
  fi
  log "La ip actual del Server es: $IP_ACTUAL" 
  apt update
 

}

function Datos_cliente() {
#************** PASSWORD PARA LA DATABASE MYSQL *******************
# SOLICITUD DE LA CONTRASEÑA AL USUARIO PARA LA CREACION O EL USO DE LA BASE DE DATOS MYSQL

  echo "Ingrese la contraseña segura para la creacion de la Base de Datos, si ya tiene instalado MySQL ingrese la contraseña ya configurada"
  read -s DB_PASSWORD
  # Confirmar la contraseña
  echo "Confirme la contraseña:" 
  read -s DB_PASSWORD_CONFIRM
    
  if [ "$DB_PASSWORD" != "$DB_PASSWORD_CONFIRM" ]; then
	
    log "Las contraseñas no coinciden. Por favor, intente nuevamente."
    exit 1
	  
  fi
  log "se creo correctamente la contraseña"
  
#************** HOSTNAME PARA EL ZABBIX proxy *******************
# Solicitar al usuario que ingrese un dato
  echo "Ingrese el Numero de Oportunidad para la creacion del Proxyname:"
  read HOSTNAME_PROXY

# Validar si se ingresó un dato
  if [ -z "$HOSTNAME_PROXY" ]; then
      log "¡Error! No se ingresó ningún dato, por favor volver a intentar a ejecutar el Script"
      exit 1
    else
      log "Has ingresado la siguiente Oportunidad: $HOSTNAME_PROXY para nombrar al Proxyname"
  fi
   
}

#************** ENCRIPTACION DE ZABBIX PROXY *******************************************
# Generar una llave PSK de 32 bytes en formato hexadecimal
function key_Psk(){
PSK=$(openssl rand -hex 32)

# Mostrar la llave PSK
log "La llave PSK generada es: $PSK"

# Crear el archivo en /opt con el nombre encrypted.key
echo "$PSK" > /opt/encrypted.key
}

# CREACION DE ARCHIVO PARA IDENTIFICAR SI YA SE EJECUTO ANTERIORMENTE EL SCRIPT
function create_flag() {
  touch "$flag_file"
  log "Se ha creado el archivo de bandera. El script ha terminado exitosamente."
}

log
validaciones
Datos_cliente
key_Psk
create_flag
