#!/bin/bash

${ORACLE_SRC_INSTALL_DIR}/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -force -responseFile $1 | 
while read l ; 
do 
	  echo "$l" ; 
done

