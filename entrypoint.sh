#!/bin/bash
set -e

sysctl -p > /dev/null 2>&1 || true

chown -R oracle:oinstall $ORACLE_BASE 
chown -R oracle:oinstall /u01/app/oracle-product
rm -fr $ORACLE_BASE/product
ln -s /u01/app/oracle-product $ORACLE_BASE/product

/u01/app/oraInventory/orainstRoot.sh > /dev/null 2>&1
echo | $ORACLE_BASR/product/11.2.0/db_1/root.sh> /dev/null 2>&1 || true

#setting correct timezone, as UTC is not supported by Oracle EM
echo y | cp -f /usr/share/zoneinfo/${TZ}  /etc/localtime


start_listener(){
 gosu oracle echo "LISTENER = (DESCRIPTION_LIST = (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = $(hostname))(PORT = 1521))))" > $ORACLE_HOME/network/admin/listener.ora
 gosu oracle echo "" > $ORACLE_HOME/network/admin/sqlnet.ora
 gosu oracle lsnrctl start
}

reload_listener(){
 gosu oracle lsnrctl reload
}

create_database(){
 gosu oracle dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname ${ORACLE_SID} -sid ${ORACLE_SID} -responseFile NO_VALUE -characterSet AL32UTF8  -emConfiguration LOCAL -automaticMemoryManagement false -memoryPercentage $INIT_MEM_PST -redoLogFileSize 100 -databaseType MULTIPURPOSE -sysPassword oracle -systemPassword oracle -dbsnmpPassword oracle
}

start_database(){
 gosu oracle sqlplus -silent /nolog << EOF
 connect sys/oracle as sysdba;
 startup;
 exit;
EOF
}

shutdown_database(){
 if [ "$SW_ONLY" != "true" ]; then
  gosu oracle  sqlplus -silent /nolog << EOF
   connect sys/oracle as sysdba;
   shutdown immediate;
   exit;
EOF
 fi
} 

set_http_port(){
 gosu oracle sqlplus -silent /nolog << EOF
 connect sys/oracle as sysdba;
 EXEC DBMS_XDB.sethttpport(8080);
 exit;
EOF
}

_run_script(){
 gosu oracle sqlplus -silent /nolog << EOF
 connect sys/oracle as sysdba;
 @$1
 exit;
EOF
}


run_init_scripts(){
exec="Init scripts in /oracle.init.d/"
    for f in /oracle.init.d/*; do
	    case "$f" in
		*.sh)     echo "$exec: Running $f"; . "$f" || true ;;
		*.sql)    echo "$exec: Running $f"; _run_script "$f" || true ; echo ;;
		*)        echo "$exec: Ignoring $f" ;;
	    esac
	    echo
    done
}

case "$1" in
	'')	
		if [ "$SW_ONLY" == "true" ]; then
                	echo "Software only mode, nothing has been installed, enviroment is ready"
                        echo "Init scripts nevertheless will be run"
                  	echo "Oracle home is: ${ORACLE_HOME}"
                  	echo "Oracle base is: ${ORACLE_BASE}" 
                else
                 	if [ "$(ls -A $ORACLE_BASE/oradata/$ORACLE_SID)" ]; then
                  		echo "Found database files in $ORACLE_BASE/oradata/$ORACLE_SID. Trying to start database"
                  		echo "Restoring configuration from $ORACLE_BASE/dbs"
                  		echo "$ORACLE_SID:$ORACLE_HOME:N" > /etc/oratab
                  		chown oracle:oinstall /etc/oratab
	          		chmod 664 /etc/oratab
                  		rm -rf $ORACLE_HOME/dbs
                  		ln -s $ORACLE_BASE/dbs $ORACLE_HOME/dbs
                  		start_listener
      		  		start_database           
                 	else
                  		echo "No databases found in $ORACLE_BASE/oradata/$ORACLE_SID. About to create a new database instance"
                  		# preserving oracle configuratioin for future run
                  		touch /etc/oratab
                  		chown oracle:oinstall /etc/oratab
                  		chmod 664 /etc/oratab
		  		mv $ORACLE_HOME/dbs $ORACLE_BASE/dbs
                  		ln -s $ORACLE_BASE/dbs $ORACLE_HOME/dbs
                  		echo "Starting database listener" 
                  		start_listener
                  		create_database  
                  		reload_listener
                  		echo "Database has been created in $ORACLE_BASE/oradata/$ORACLE_SID"
                  		echo "SYS and SYSTEM passwords are set to [oracle]" 
                 	fi 
                 	echo "Setting HTTP port to 8080"
                 	set_http_port
                 	echo "Please login to http://<ip_address>:8080/em to use enterprise manager"
                 	echo "User: sys; Password oracle; Sysdba: true" 
                fi 
		
		echo "Fixing permissions..."
		chown -R oracle:oinstall /u01 
		
		echo "Running init scripts..."
		run_init_scripts
		echo "Done with scripts we are ready to go"		

		while [ "$END" == '' ]; do
		       chown -R oracle:oinstall /u01/app/oracle/dbs
			sleep 1
			trap "shutdown_database" INT TERM
		done
		;;
         
	*)
		echo "Nothing has been configured. Please run '/entrypoint.sh' to install or start db"
		$1
		;;
esac

