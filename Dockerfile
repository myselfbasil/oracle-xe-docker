FROM oraclelinux:8-slim AS base

ENV ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE \
    ORACLE_SID=XE \
    ORACLE_PDB=XEPDB1 \
    ORACLE_EDITION=xe \
    ORACLE_CHARACTERSET=AL32UTF8 \
    PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

RUN groupadd -g 54321 oinstall && \
    groupadd -g 54322 dba && \
    useradd -u 54321 -g oinstall -G dba oracle && \
    mkdir -p $ORACLE_BASE && \
    mkdir -p $ORACLE_BASE/oradata && \
    mkdir -p $ORACLE_BASE/scripts && \
    mkdir -p $ORACLE_BASE/product/21c/dbhomeXE && \
    chown -R oracle:oinstall $ORACLE_BASE && \
    chmod -R 775 $ORACLE_BASE

# Install required packages and Oracle prerequisites
RUN microdnf install -y \
        glibc-langpack-en \
        openssl \
        hostname \
        vi \
        which \
        sudo \
        net-tools \
        bc \
        unzip \
        tar \
        gzip && \
    microdnf clean all && \
    echo "oracle ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "Defaults !requiretty" >> /etc/sudoers

# Install Oracle Database prerequisites manually
RUN microdnf install -y \
        binutils \
        gcc \
        gcc-c++ \
        glibc \
        glibc-devel \
        ksh \
        libaio \
        libaio-devel \
        libgcc \
        libstdc++ \
        libstdc++-devel \
        libnsl \
        make \
        sysstat \
        nfs-utils \
        psmisc && \
    microdnf clean all

# Set kernel parameters
RUN echo "kernel.shmall = 2097152" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "kernel.shmmax = 4294967295" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "kernel.shmmni = 4096" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "kernel.sem = 250 32000 100 128" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "fs.file-max = 6815744" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "fs.aio-max-nr = 1048576" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "net.ipv4.ip_local_port_range = 9000 65500" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "net.core.rmem_default = 262144" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "net.core.rmem_max = 4194304" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "net.core.wmem_default = 262144" >> /etc/sysctl.d/97-oracle-database-sysctl.conf && \
    echo "net.core.wmem_max = 1048576" >> /etc/sysctl.d/97-oracle-database-sysctl.conf

# Set security limits
RUN echo "oracle soft nofile 1024" >> /etc/security/limits.conf && \
    echo "oracle hard nofile 65536" >> /etc/security/limits.conf && \
    echo "oracle soft nproc 2047" >> /etc/security/limits.conf && \
    echo "oracle hard nproc 16384" >> /etc/security/limits.conf && \
    echo "oracle soft stack 10240" >> /etc/security/limits.conf && \
    echo "oracle hard stack 32768" >> /etc/security/limits.conf

# Download and install Oracle XE
ARG ORACLE_XE_URL="https://download.oracle.com/otn-pub/otn_software/db-express/oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm"
ADD --chown=oracle:oinstall $ORACLE_XE_URL /tmp/oracle-xe.rpm

RUN yum localinstall -y /tmp/oracle-xe.rpm && \
    rm -f /tmp/oracle-xe.rpm && \
    mkdir -p $ORACLE_BASE/oradata && \
    mkdir -p $ORACLE_BASE/diag && \
    mkdir -p $ORACLE_BASE/fast_recovery_area && \
    chown -R oracle:oinstall $ORACLE_BASE

USER oracle
WORKDIR /opt/oracle

COPY --chown=oracle:oinstall scripts/ $ORACLE_BASE/scripts/
COPY --chown=oracle:oinstall entrypoint.sh $ORACLE_BASE/

RUN chmod +x $ORACLE_BASE/entrypoint.sh && \
    chmod +x $ORACLE_BASE/scripts/*.sh

VOLUME ["$ORACLE_BASE/oradata"]

EXPOSE 1521 5500

HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
    CMD $ORACLE_BASE/scripts/check_health.sh || exit 1

ENTRYPOINT ["/opt/oracle/entrypoint.sh"]