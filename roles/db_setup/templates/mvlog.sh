#!/bin/bash

ORACLE_SID=$1; export ORACLE_SID

TIMESTAMP=`/bin/date '+%Y%m%d%H%M'`
#LOGFILE=${HOME}'/admin/'${ORACLE_SID}'/bdump/alert_'${ORACLE_SID}'.'${TIMESTAMP}
LOGFILE='/app/oracle/diag/rdbms/'${ORACLE_SID}'/'${ORACLE_SID}'/trace/alert_'${ORACLE_SID}'.'${TIMESTAMP}
#mv ~/admin/$ORACLE_SID/bdump/alert_$ORACLE_SID.log $LOGFILE 
mv /app/oracle/diag/rdbms/$ORACLE_SID/$ORACLE_SID/trace/alert_$ORACLE_SID.log $LOGFILE 
