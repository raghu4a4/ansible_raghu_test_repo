source /home/oracle/.profile

echo 
echo "======================="
echo This report was run on:
echo "======================="
date

echo 
echo
echo "========== Server Name =========="
hostname

echo
echo
echo "========== Oracle Home =========="
grep -i /app /etc/oratab

sqlplus / as sysdba @/net/bos1pfiler1/vol/bos1_nas_library/orastage/Checklists/checklist.sql

echo 
echo
echo "========== Listener Status =========="
lsnrctl status | grep Start
lsnrctl status | grep Version

echo
echo
echo "===== The listener is monitoring the database(s) and service(s)"
lsnrctl status | grep Service

echo 
echo
echo "========== OEM Status =========="
$AGENT_HOME/bin/emctl status agent

echo
echo
echo "========== OEM Targets Monitored =========="
$AGENT_HOME/bin/emctl config agent listtargets


