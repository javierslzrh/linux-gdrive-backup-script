## Linux GDrive Backup Script
#### Este script realiza backups de carpetas y bases de datos MySQL y los almacena en Google Drive. Tambien es capaz de transferirlos a otro equipo automaticamente via SSH.

### Requerimientos
* [GDrive](https://github.com/prasmussen/gdrive)
* rsync

### Instalación
Para instalar; primero cree la siguiente carpeta 
```
mkdir -p /opt/autobackup/
```

Luego descargue el script
```
wget https://raw.githubusercontent.com/javierslzrh/linux-gdrive-backup-script/master/autobackup.sh -O /opt/autobackup/autobackup.sh
```

Otorgue al script permiso de ejecución
```
chmod +x /opt/autobackup/autobackup.sh
```

### Configuración
Edite el script y configure los parametros siguientes
```
MYSQL_USER=user #Usuario de la base de datos MySQL
MYSQL_PASS=pass #Contraseña del usuario de base de datos
DATE_FORMAT="%Y%m%d%H%M%S" #Formato de la fecha para los respaldos
TMP_DIR=/tmp #Directorio temporal
FOLDER_NAME=$(date +"%Y%m%d") #Nombre de las carpetas de respaldo (en GDrive y Directorio remoto)
DRIVE_BACKUP_DIR="0B-QdsaEfa_cYx0eDMFlr32wwRzA" #ID de la Carpeta para los respaldos en GDrive
REMOTE_DIRECTORY="user@ip:/path/to/backups/" #Directorio remoto al cual se enviaran los respaldos.
```

### Uso
| Parametro | Uso                       | Descripción                              | Ejemplo                                                         |
|-----------|---------------------------|------------------------------------------|-----------------------------------------------------------------|
|-f         |-f file_name:folder_name   | Especifica una carpeta a respaldar       | /opt/autobackup/autobackup.sh -f myfolder:/home/myuser/myfolder |
|-d         |-d file_name:database_name | Especifica una base de datos a respaldar | /opt/autobackup/autobackup.sh -d mydb:mybd                      |

Se pueden repetir los parametros tantas veces sea necesario.

### Automatización
La mejor forma de utilizar este script es programar su ejecución periodica de acuerdo a las necesidades de uso. Para ello, puede usar el cron de Linux.

Ejemplo:

Esta seria la entrada del cron para el respaldo diario de una base de datos y una carpeta
```
0 0 * * * /opt/autobackup/autobackup.sh -f myapp:/var/www/myapp -d mydb:myappdb 2>&1 | while read line; do echo `/bin/date` "$line" >> /var/log/autobackup.log
```
