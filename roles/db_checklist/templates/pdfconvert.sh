#!/bin/bash
vim /tmp/{{ outputfile }} -c "hardcopy > {{ outputfile }}.ps | q"

ps2pdf {{ outputfile }}.ps
