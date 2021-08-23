#!/bin/ksh

$ORACLE_HOME/bin/sqlplus /nolog<<!

spool $1/dbfilelocation
connect / as sysdba
set feedback off
select * from v\$instance;
set heading off
select 'gunzip -cd '||substr(file_name, instr(file_name,'/', -1)+1,length(file_name)) || '.gz > '|| file_name from dba_data_files;
select 'gunzip -cd '||substr(file_name, instr(file_name,'/', -1)+1,length(file_name)) || '.gz > '|| file_name from dba_temp_files;
select 'cp '||substr(name, instr(name,'/', -1)+1,length(name))||' '||  name from v\$controlfile;
select 'cp '||substr(member, instr(member,'/', -1)+1,length(member))||' '|| member from v\$logfile;
archive log list;
select value from v\$parameter where name = 'user_dump_dest';
exit
!

