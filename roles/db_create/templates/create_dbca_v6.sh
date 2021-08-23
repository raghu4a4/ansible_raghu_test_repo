#!/bin/bash
/usr/bin/yes | /sbin/runuser -l oracle -c "/app/oracle/product/{{ ORACLE_VER }}/db/bin/dbca -silent -createDatabase -responseFile {{ tmp_path }}/dbca_{{ ORACLE_VER }}.rsp"