export ORACLE_HOME=/app/oracle/product/11.2.0.4/db
export ORACLE_SID=regsys
export PATH=$PATH:$ORACLE_HOME/bin
export NLS_DATE_FORMAT='DD-MON-YY HH24:MI:SS'
export DATE=$(date +%Y-%m-%d)
set ORACLE_SID=INSTANCE SID
rman target '/' msglog /oraback/rman/rman_archive_del_regsys_$DATE.log << __EOF__
list archivelog until time 'SYSDATE-5';
delete noprompt archivelog until time 'SYSDATE-5';
crosscheck archivelog all ;
list archivelog until time 'SYSDATE-5';
exit
__EOF__
