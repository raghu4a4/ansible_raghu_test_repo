# File-name: set_sid.sh
#--------------------------------------------------------------------
# Set/view ORACLE_SID, ORACLE_HOME and PATH
# also it sets the following variables:
# LD_LIBRARY_PATH, TNS_ADMIN, ORA_NLS, SHLIB_PATH
#--------------------------------------------------------------------

#!/bin/ksh

echo ' '
echo '********************************************************************************'
echo ' The current ORACLE_SID value is  ' $ORACLE_SID
echo '********************************************************************************'
echo ' The following are valid instance names on this server:'
echo ' '

wcntr=0
wbeside='N'

while read LINE
do
  case $LINE in
  \#*)            ;;      #comment-line in oratab
  *)
  #       Proceed only if third field is 'Y'.
    wcntr=`expr $wcntr + 1`
    if [ $wcntr -le 9 ]
    then
       wspace=' '
    else
       wspace=''
    fi
    OSID=`echo $LINE | awk -F: '{print $1}' -`
    if [ "$ORACLE_SID" = '*' ] ; then
      echo '  *** Unknown Value ***'
    fi
    OHOME=`echo $LINE | awk -F: '{print $2}' -`
    AUTO=`echo $LINE | awk -F: '{print $3}' -`	
    ALIAS=`echo $LINE | awk -F: '{print $4}' -`
    if [ $wbeside = 'N' ]
    then
      echo " No: $wspace $wcntr  $AUTO  $OSID $ALIAS "
      wbeside='Y'
    else
      echo "    No: ${wspace} $wcntr  $AUTO  $OSID $ALIAS"
      wbeside='N'
    fi
  esac
#done < /var/opt/oracle/oratab
done < /etc/oratab

echo ' '
echo '********************************************************************************'
echo ' '
echo ' Do you want to change ORACLE_SID  [Y/N]? '

read choice
case $choice in
     Y|y) ;;
     *)   return 0;;
esac
echo ' Enter No of the SID from above list  : '
read choice
if test $choice -lt 0 || test $choice -gt $wcntr
then
   echo ' Invalid choice.... Sorry!!!'
   return 1
fi
wcntr=0
while read LINE
do
  case $LINE in
  \#*)            ;;      #comment-line in oratab
  *)
  #       Proceed only if third field is 'Y'.
  #if [ "`echo $LINE | awk -F: '{print $3}' -`" = "Y" ] ; then
    wcntr=`expr $wcntr + 1`
    if test $wcntr -eq $choice
    then
       ORACLE_SID=`echo $LINE | awk -F: '{print $1}' -`
       if [ "$ORACLE_SID" = '*' ] ; then
         ORACLE_SID=''
       fi
       ORACLE_HOME=`echo $LINE | awk -F: '{print $2}' -`
       export ORACLE_HOME ORACLE_SID
       break;
    fi
  #fi
  esac
#done < /var/opt/oracle/oratab
done < /etc/oratab


# Change PATH with new oracle home

path=`echo $PATH | sed "s/:/ /g"`
NEWPATH=$ORACLE_HOME/bin
for dirname in $path
do
  if [ `echo $dirname | grep oracle | grep bin | wc -l` -eq 0 ]
  then
     NEWPATH=`echo ${NEWPATH}:${dirname}`
  fi
done

# Change LD_LIBRARY_PATH with new oracle home

ld_path=`echo $LD_LIBRARY_PATH | sed "s/:/ /g"`
NEW_LD_PATH=$ORACLE_HOME/lib
for dirname in $ld_path
do
  if [ `echo $dirname | grep lib | wc -l` -eq 0 ]
  then
     NEW_LD_PATH=`echo ${NEW_LD_PATH}:${dirname}`
  fi
done

export PATH=$NEWPATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME/network/admin
export ORA_NLS=$ORACLE_HOME/ocommon/nls/admin/data
export SHLIB_PATH=$ORACLE_HOME/lib:/usr/lib


echo ' '
echo '********************************************************************************'
echo ' New value of ORACLE_SID is  ' $ORACLE_SID
echo ' New value of ORACLE_HOME is ' $ORACLE_HOME
echo ' New value of PATH is        ' $PATH
echo ' New value of LD_LIBRARY_PATH is ' $LD_LIBRARY_PATH
echo '********************************************************************************'
echo ' '



