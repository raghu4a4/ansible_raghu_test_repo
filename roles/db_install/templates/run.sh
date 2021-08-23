#!/bin/bash

/bin/yes | /usr/sbin/runuser -l oracle -c "{{ run_Installer }} {{install_params}} {{ tmp_path }}/{{ response_file }}"
