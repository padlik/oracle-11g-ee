#!/bin/bash

cd ${ORACLE_SRC_INSTALL_DIR}/stage/Components
 
jar_file=
for i_file in $( ls ./oracle.ctx/11.2.0.1.0/1/DataFiles/filegroup*.jar ); do
	unzip -l ${i_file} ctx/lib/ins_ctx.mk 2>&1 1>/dev/null
	[[ $? -eq 0 ]] && jar_file=${i_file} && break
done
 
cat << __EOF__ > /tmp/memcpy_wrap.c
#include <stddef.h>
#include <string.h>
 
asm (".symver wrap_memcpy, memcpy@GLIBC_2.14");
void *wrap_memcpy(void *dest, const void *src, size_t n) {
return memcpy(dest, src, n);
}
__EOF__
unzip ${jar_file} ctx/lib/ins_ctx.mk 2>&1 1>/dev/null
if [[ $? -eq 0 ]]; then
	sed -i -e 's/\$(INSO_LINK)/\$(INSO_LINK) -Wl,--wrap=memcpy_wrap \$(ORACLE_HOME)\/ctx\/lib\/memcpy_wrap.o/g' ctx/lib/ins_ctx.mk
	gcc -c /tmp/memcpy_wrap.c -o ctx/lib/memcpy_wrap.o && rm -f /tmp/memcpy_wrap.c
	jar -uvf  ${jar_file} ctx/lib/ins_ctx.mk ctx/lib/memcpy_wrap.o
fi

