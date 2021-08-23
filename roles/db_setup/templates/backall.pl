#!/usr/bin/perl -w
# $Id: dbshut.sh.pp 16-apr-2004.12:51:39 dfriedma Exp $
# Copyright (c) 1991, 2004, Oracle Corporation.  All rights reserved.  
#
ORATAB=/etc/oratab

CUT=/usr/bin/cut
ECHO=/bin/echo
LOGMSG="/usr/bin/logger -puser.alert"
SLEEP=/bin/sleep

# that ORACLE
#

cat $ORATAB | while read LINE
do
    case $LINE in
        \#*)                ;;        #comment-line in oratab
        *)
#       Proceed only if last field is 'Y'.
#       Entries whose last field is not Y or N are not DB entry, ignore them.
        if [ "`echo $LINE | awk -F: '{print $NF}' -`" = "Y" ] ; then
            ORACLE_SID=`echo $LINE | awk -F: '{print $1}' -`
            if [ "$ORACLE_SID" = '*' ] ; then
                ORACLE_SID=""
            fi
#           For ASM instances, we have a dependency on the CSS service.
#           Wait here for it to become available before instance startup.
            if [ `$ECHO $ORACLE_SID | $CUT -b 1` != '+' ]; then
              echo $ORACLE_SID
              /home/oracle/admin/maint/obacknew.pl -c $ORACLE_SID SNAPON
            fi
        fi
        ;;
    esac
done

