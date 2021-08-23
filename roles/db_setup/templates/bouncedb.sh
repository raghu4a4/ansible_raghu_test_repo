#!/bin/sh

ORACLE_SID=$1; export ORACLE_SID
ORACLE_HOME=$2; export ORACLE_HOME
$ORACLE_HOME/bin/sqlplus <<EOF
connect / as sysdba
shutdown abort
startup 
