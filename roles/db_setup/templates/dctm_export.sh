#!/usr/bin/ksh
ORACLE_SID=dctmprd
export ORACLE_SID
ORACLE_HOME=/app/oracle/product/12.1.0.2/db; export ORACLE_HOME
PATH=$PATH:$ORACLE_HOME/bin; export PATH
LOG=`echo $ORACLE_SID`_export_`date +%m%d%y`.log; export LOG
EXPDIR=/oraback/export/dctmprd/; export EXPDIR
EXPFILE=`echo $ORACLE_SID`_export_exp_`date +%m%d%y%H`.dmp; export EXPFILE
SCHEMAS_TO_EXPORT=`cat /app/oracle/admin/maint/schemas_to_export.txt`; export SCHEMAS_TO_EXPORT
cd $EXPDIR
#rm -f exp_pipe
#mkfifo exp_pipe
#gzip < exp_pipe > $EXPFILE.Z &
$ORACLE_HOME/bin/expdp "'/ as sysdba'" dumpfile=$EXPFILE log=$LOG SCHEMAS=$SCHEMAS_TO_EXPORT DIRECTORY=EXPORT_DIR
SUB=$SUB`tail -1 $LOG`; export SUB gzip $EXPFILE
cat $LOG |mailx -s "${SUB}" vertex_dbas@vrtx.com  DocCompliance_Admins@vrtx.com
exit
