. /home/oracle/.profile	
export recipient1=vertex_dbas@vrtx.com   #E-mail Recipient 1
export LOGDIR=/oraback
export LOGFILE=$LOGDIR/logfile_clear_archive_`date +'%Y%m%d_%H%M%S'`.log
echo "##########################################################" >$LOGFILE
echo "##FLASHBACK RECOVERY AREA USAGE AND LOG APPLIED STATUS BEFORE CLEANUP###"                                                                                         >>$LOGFILE
echo "==========================================================" >>$LOGFILE
sqlplus -s "/ as sysdba" <<! >>$LOGFILE
set echo on
set pages 100
set line 200
select * from v\$flash_recovery_area_usage;
prompt "Max archive applied status"
prompt "--------------------------"
select thread#,max(sequence#) from v\$archived_log where applied='YES' group by                                                                                         thread#;
exit;
!

echo "##########################################################" >>$LOGFILE
echo "#################RMAN delete log files   #################" >>$LOGFILE
echo "==========================================================" >>$LOGFILE
rman target / <<! >>$LOGFILE
run {
allocate channel ch1 device type disk;
delete noprompt force archivelog all completed before 'sysdate -5';
release channel ch1;
}
exit;
!

echo "##########################################################" >>$LOGFILE
echo "##########FLASHBACK RECOVERY AREA USAGE STATUS AFTER CLEANUP############"                                                                                         >>$LOGFILE
echo "==========================================================" >>$LOGFILE
sqlplus -s "/ as sysdba" <<! >>$LOGFILE
set echo on
set pages 100 line 200
select * from v\$flash_recovery_area_usage;
exit;
!


####### Checking Log file for any errors #######
#grep "RMAN-" $LOGFILE
#if [ "$?" -ne "1" ]; then
#  cat $LOGFILE|mailx -s "TRI-RPT:VERTEX:`hostname`.$ORACLE_SID.Cleared archive l                                                                                        ogs-ISSUES" $recipient1
#else
#  mv $LOGDIR/clear_archive.sql $LOGDIR/clear_archive.sql.`date +'%Y%m%d_%H%M%S'`
#  find $LOGDIR -name "logfile_clear_archive_*.log" -type f -exec gzip {} \;
#  find $LOGDIR -name "logfile_clear_archive_*.log*"  -type f -mtime 7 -exec rm -                                                                                        f {} \;
#fi

