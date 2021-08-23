### Change the <DBSID> to the correct database SID
#
ORACLE_BASE={{ ORACLE_BASE }}; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/{% if ORACLE_VER == "12.2.0.1" %}12.2.0.1{% else %}{{ ORACLE_VER }}{% endif %}/db; export ORACLE_HOME
ORACLE_SID={{ ORACLE_SID }}; export ORACLE_SID

AGENT_HOME=/app/oracle/product/agent13c/agent_inst; export AGENT_HOME
PATH=$PATH:$HOME/bin:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch
export PATH

unset USERNAME
EDITOR=vi; export EDITOR
alias pso='ps -fu oracle'
alias oh='cd $ORACLE_HOME'
alias ohbin='cd $ORACLE_HOME/bin'
alias dbs='cd $ORACLE_HOME/dbs'
alias sid='echo $ORACLE_SID'
alias setsid='. /home/oracle/admin/maint/set_sid.sh'
alias ls-ltr='ls -ltr'
alias diag='cd /app/oracle/diag/rdbms'
alias tns='cd $ORACLE_HOME/network/admin'
alias agent='cd $AGENT_HOME/bin; export ORACLE_HOME=$AGENT_HOME; export PATH=$ORACLE_HOME/bin:$PATH'
#Agent will stop, clearstate, start and upload
alias agent_restart='cd $AGENT_HOME/bin; ./emctl status agent; ./emctl stop agent; ./emctl clearstate agent; ./emctl start agent; ./emctl upload agent;'

PATH=$HOME:$ORACLE_HOME:$ORACLE_HOME/bin:$ORACLE_HOME/ctx/bin:/usr/local/bin:/usr/ccs/bin:/usr/sbin:/usr/bsd:/sbin:/usr/bin:/usr/bin/X11:$PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/ctx/lib:$ORACLE_HOME/JRE/lib/sparc/native_threads:/usr/lib:/lib;export LD_LIBRARY_PATH

HOSTNAME=$(uname -n)
HISTSIZE=50

stty erase ^H

#export PS1="\[\e]0;\u@\h [${TWO_TASK:-$ORACLE_SID}]\a\]\u@\h:\w\$ "
export PS1="\[\e]0;\u@\h [${TWO_TASK:-$ORACLE_SID}]\a\]\u@\h \W]:$ "

cd /app/oracle

