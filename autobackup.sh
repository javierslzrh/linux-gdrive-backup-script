#!/bin/bash
MYSQL_USER=
MYSQL_PASS=
DATE_FORMAT="%Y%m%d%H%M%S"
TMP_DIR=/tmp
FOLDER_NAME=$(date +"%Y%m%d")
DRIVE_BACKUP_DIR=""
REMOTE_DIRECTORY=""

declare -a DATABASES=()
declare -a FOLDERS=()

while [[ $# > 0 ]] ; do
	key="$1"
	shift

	case $key in
    	-f)
	        FOLDERS=( "${FOLDERS[@]}" "$1" )
    		shift
	    ;;
    	-d)
	    	DATABASES=( "${DATABASES[@]}" "$1" )
	    	shift
		;;
		--all-db)
			ALLDB=true
		;;
    	*)
			echo "Opcion \"$1\" desconocida"
    	;;
	esac
done

loop=0
#VALIDAR EXISTENCIA DE FICHEROS
for i in "${FOLDERS[@]}" ; do
	IFS=':' read -r -a folder <<< "$i"

	if [[ ${#folder[@]} != 2 ]] ; then
		echo "Formato del parametro -f incorrecto. Debe ser nombre_del_archivo_de_respaldo:ruta_a_respaldar. Ejemplo: mirespaldo:/home/micarpeta"
		exit
	fi

	if [ ! -r "${folder[1]}" ]; then
		echo "Advertencia: \"$i\" no es una carpeta valida."
		unset FOLDERS[$loop]
	fi
	loop=loop+1
done

loop=0
#VALIDAR EXISTENCIA DE BASES DE DATOS
for i in "${DATABASES[@]}" ; do
	IFS=':' read -r -a database <<< "$i"

	if [[ ${#database[@]} = 1 ]] ; then
		db=${database}
	elif [[ ${#database[@]} = 2 ]] ; then
		db=${database[1]}
	fi

    result=`mysqlshow --user=${MYSQL_USER} --password=${MYSQL_PASS} "$db" 2> /dev/null | grep -v Wildcard | grep -o "$db"`
	if [[ "$result" != "$db" ]]; then
		echo "Advertencia: La base de datos $db no existe"
		unset DATABASES[$loop]
	fi
	loop=loop+1
done

if [[ ${#FOLDERS[@]} = 0 && ${#DATABASES[@]} = 0 ]] ; then
	echo "Información: Nada que respaldar. Saliendo."
	exit
fi

echo "Información: Creando carpeta temporal $TMP_DIR/$FOLDER_NAME"
if [ ! -d $TMP_DIR/$FOLDER_NAME ]; then
	mkdir -p $TMP_DIR/$FOLDER_NAME
else
	rmdir --ignore-fail-on-non-empty $TMP_DIR/$FOLDER_NAME
	mkdir -p $TMP_DIR/$FOLDER_NAME
fi

for i in "${FOLDERS[@]}" ; do
	IFS=':' read -r -a folder <<< "$i"
	F_BACKUP_FILENAME=$(basename ${folder[0]}).tar.gz
	echo "Información: Respaldando carpeta ${folder[1]} en $TMP_DIR/$FOLDER_NAME/$F_BACKUP_FILENAME"
	tar -zcf ${TMP_DIR}/${FOLDER_NAME}/${F_BACKUP_FILENAME} -C ${folder[1]} .
done

for i in "${DATABASES[@]}" ; do
	IFS=':' read -r -a database <<< "$i"

	if [[ ${#database[@]} = 1 ]] ; then
    	db=${database}
		bkname=db
	elif [[ ${#database[@]} = 2 ]] ; then
		db=${database[1]}
		bkname=${database[0]}
    fi

	DB_BACKUP_FILENAME=${bkname}.sql.gz
	echo "Información: Respaldando base de datos $db en $TMP_DIR/$FOLDER_NAME/$DB_BACKUP_FILENAME"
    mysqldump -u $MYSQL_USER -p$MYSQL_PASS $db | gzip -c > ${TMP_DIR}/${FOLDER_NAME}/${DB_BACKUP_FILENAME}
done

echo "Información: Enviado ficheros al servidor de GDrive"
gFolder=`gdrive list --no-header -q "mimeType = 'application/vnd.google-apps.folder' and name = '${FOLDER_NAME}' and trashed = false and '$DRIVE_BACKUP_DIR' in parents" | awk -F " " '{print $1}'`
if [[ -z "${gFolder// }" ]] ; then
	gFolder=`gdrive mkdir -p ${DRIVE_BACKUP_DIR} ${FOLDER_NAME} | awk -F " " '{print $2}'`
fi

for file in $(find "${TMP_DIR}/${FOLDER_NAME}" -type f) ; do
	echo "Información: Cargando archivo $file"
	gdrive upload -p $gFolder --no-progress $file
done

echo "Información: Enviado ficheros al servidor de Respaldos"
rsync -aqz ${TMP_DIR}/${FOLDER_NAME} $REMOTE_DIRECTORY

echo "Información: Eliminando ficheros temporales"
rm -rf  ${TMP_DIR}/${FOLDER_NAME}

echo  "Información: Respaldo finalizado"
