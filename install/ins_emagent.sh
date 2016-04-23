#!/bin/bash

# Fix sysman/lib/ins_emagent.mk
 
cd ${ORACLE_SRC_INSTALL_DIR}/stage/Components
 
jar_file=
for i_file in $( ls ./oracle.sysman.agent/*/1/DataFiles/filegroup*.jar ); do
	unzip -l ${i_file} sysman/lib/ins_emagent.mk 2>&1 1>/dev/null
	[[ $? -eq 0 ]] && jar_file=${i_file} && break
done
 
unzip ${jar_file} sysman/lib/ins_emagent.mk 2>&1 1>/dev/null
if [[ $? -eq 0 ]]; then
	sed -i -e 's/\$(MK_EMAGENT_NMECTL)/\$(MK_EMAGENT_NMECTL) -lnnz11/g' sysman/lib/ins_emagent.mk
	jar -uvf  ${jar_file} sysman/lib/ins_emagent.mk
fi
