FROM oraclelinux
MAINTAINER propan@gmail.com

ADD install /install

ENV ORACLE_BASE=/u01/app/oracle
ENV ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
ENV PATH=$ORACLE_HOME/bin:$PATH
ENV ORACLE_HOME_LISTNER=$ORACLE_HOME
ENV ORACLE_SID=orcl
ENV ORACLE_SRC_INSTALL_DIR=/install/database


#Prereq
RUN yum -y install oracle-rdbms-server-11gR2-preinstall.x86_64 && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum install -y rlwrap && \
    yum install -y java-devel unzip && \
    yum clean all && \ 
    rm -rf /var/lib/{cache,log} /var/log/lastlog && \
    curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.4/gosu-amd64' && chmod +x /usr/local/bin/gosu && \
    echo "oracle:oracle" | chpasswd && \ 
    mkdir -p $ORACLE_BASE && chown -R oracle:oinstall $ORACLE_BASE && \
    chmod -R 775 $ORACLE_BASE && \
    mkdir -p /app/oraInventory && \
    chown -R oracle:oinstall /app/oraInventory && \
    chmod -R 775 /app/oraInventory && \
    chmod -R 775 /u01 && \
    chown -R oracle:oinstall /u01 && \
    mkdir /oracle.init.d && \
    chown -R oracle:oinstall /oracle.init.d && \
    mkdir -p /u01/app/oracle-product && chown oracle:oinstall /u01/app/oracle-product && \
    ln -s /u01/app/oracle-product $ORACLE_BASE/product && \   
    curl -o /install/disk1.zip -SL 'http://10.211.55.9:8080/linux.x64_11gR2_database_1of2.zip' && \
    curl -o /install/disk2.zip -SL 'http://10.211.55.9:8080/linux.x64_11gR2_database_2of2.zip' && \
    cd /install && unzip -qq '*.zip' && rm -f /install/*.zip && source /install/ins_ctx.sh && source /install/ins_emagent.sh && \
    gosu oracle  /install/install_sw.sh /install/sw_install.rsp && \ 
    rm -fr $ORACLE_SRC_INSTALL_DIR && rm -fr /tmp/* 

ENV INIT_MEM_PST 40
ENV SW_ONLY false

ADD entrypoint.sh /entrypoint.sh

EXPOSE 1521
EXPOSE 8080
EXPOSE 5500

VOLUME ["/u01/app/oracle"]

ENTRYPOINT ["/entrypoint.sh"]
