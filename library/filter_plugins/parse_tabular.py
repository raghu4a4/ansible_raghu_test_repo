import re
import pprint as pp

# this is to parse tabular cli output with re named capturing groups
# And it is built for Ansible filter plugin
# the input regex must be named regex such as (?P<interface>\S+)\s+(?P<ip>\S+)
# output is a list of dict
'''
Playbook Example:
---
- name: parse cli outouput of "show ip interface brief"

  hosts: localhost
  gather_facts: false
  vars:
    tabular_text: |-
      TenGigabitEthernet2/1  unassigned      YES unset  up                    up
      TenGigabitEthernet2/2  unassigned      YES unset  down                  down
      TenGigabitEthernet2/3  unassigned      YES NVRAM  up                    up
      TenGigabitEthernet3/2  unassigned      YES NVRAM  administratively down down
      Te3/2.1                unassigned      YES unset  administratively down down
      Te3/2.1030             32.180.0.9      YES NVRAM  administratively down down
      Te3/2.1903             32.180.0.21     YES NVRAM  administratively down down
      Te3/2.1905             unassigned      YES unset  administratively down down
      TenGigabitEthernet3/3  unassigned      YES NVRAM  up                    up
      GigabitEthernet5/1     unassigned      YES NVRAM  administratively down down
      GigabitEthernet5/2     199.199.199.2   YES NVRAM  up                    up

  tasks:
  - name: Get parsed txt
    set_fact:
      output_data: "{{ tabular_text | parse_tabular('(?P<interface>\\S+)\\s+(?P<ip>\\S+)\\s+(?P<is_ok>\\S+)\\s+(?P<method>\\S+)\\s+(?P<status>(administratively )?\\S+)\\s+(?P<protocol>\\S+$

  - name: display var output_data
    debug:
      msg: "{{ output_data | to_nice_json }}"


Run playbook output:
PLAY [parse cli outouput of "show ip interface brief"] **********************************************************************************************************

TASK [Get parsed txt] ***********************************************************************************************************************************************************************
ok: [localhost]

TASK [display var output_data] **************************************************************************************************************************************************************
ok: [localhost] =>
  msg: |-
    [
        {
            "interface": "TenGigabitEthernet2/1",
            "ip": "unassigned",
            "is_ok": "YES",
            "method": "unset",
            "protocol": "up",
            "status": "up"
        },
        {
            "interface": "TenGigabitEthernet2/2",
            "ip": "unassigned",
            "is_ok": "YES",
            "method": "unset",
            "protocol": "down",
            "status": "down"
        },
        {
            "interface": "TenGigabitEthernet2/3",
            "ip": "unassigned",
            "is_ok": "YES",
            "method": "NVRAM",
            "protocol": "up",
            "status": "up"
        },
        {
            "interface": "TenGigabitEthernet3/2",
            "ip": "unassigned",
            "is_ok": "YES",
            "method": "NVRAM",
            "protocol": "down",
            "status": "administratively down"
        },
        {
            "interface": "Te3/2.1",
            "ip": "unassigned",
            "is_ok": "YES",
            "method": "unset",
            "protocol": "down",
            "status": "administratively down"
        },
        {
            "interface": "Te3/2.1030",
            "ip": "32.180.0.9",
            "is_ok": "YES",
            "method": "NVRAM",
            "protocol": "down",
            "status": "administratively down"
        },
        {
            "interface": "Te3/2.1903",
            "ip": "32.180.0.21",
            "is_ok": "YES",
            "method": "NVRAM",
            "protocol": "down",
            "status": "administratively down"
        },
        {
            "interface": "Te3/2.1905",
            "ip": "unassigned",
            "is_ok": "YES",
            "method": "unset",
            "protocol": "down",
            "status": "administratively down"
        },
        {
            "interface": "TenGigabitEthernet3/3",
            "ip": "unassigned",
            "is_ok": "YES",
            "method": "NVRAM",
            "protocol": "up",
            "status": "up"
        },
        {
            "interface": "GigabitEthernet5/1",
            "ip": "unassigned",
            "is_ok": "YES",
            "method": "NVRAM",
            "protocol": "down",
            "status": "administratively down"
        },
        {
            "interface": "GigabitEthernet5/2",
            "ip": "199.199.199.2",
            "is_ok": "YES",
            "method": "NVRAM",
            "protocol": "up",
            "status": "up"
        }
    ]

PLAY RECAP **********************************************************************************************************************************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0


'''
#
'''
Example in python code:
invar = 
TenGigabitEthernet2/1  unassigned      YES unset  up                    up
TenGigabitEthernet2/2  unassigned      YES unset  down                  down
TenGigabitEthernet2/3  unassigned      YES NVRAM  up                    up
TenGigabitEthernet2/4  unassigned      YES NVRAM  up                    up
TenGigabitEthernet3/1  unassigned      YES unset  up                    up
TenGigabitEthernet3/2  unassigned      YES NVRAM  administratively down down
Te3/2.1                unassigned      YES unset  administratively down down
Te3/2.1030             32.180.0.9      YES NVRAM  administratively down down
Te3/2.1040             32.180.0.13     YES NVRAM  administratively down down
Te3/2.1903             32.180.0.21     YES NVRAM  administratively down down
Te3/2.1905             unassigned      YES unset  administratively down down
Te3/2.3333             unassigned      YES unset  administratively down down
TenGigabitEthernet3/3  unassigned      YES NVRAM  up                    up
TenGigabitEthernet3/4  unassigned      YES unset  up                    up
GigabitEthernet5/1     unassigned      YES NVRAM  administratively down down
GigabitEthernet5/2     199.199.199.2   YES NVRAM  up                    up

regex_str = '(?P<interface>\S+)\s+(?P<ip>\S+)\s+(?P<is_ok>\S+)\s+(?P<method>\S+)\s+(?P<status>(administratively )?\S+)\s+(?P<protocol>\S+)'
out = parse_tabular(invar, regex_str)
pp.pprint(out)

out = [{'interface': 'TenGigabitEthernet2/1',
  'ip': 'unassigned',
  'is_ok': 'YES',
  'method': 'unset',
  'protocol': 'up',
  'status': 'up'},
 {'interface': 'TenGigabitEthernet2/2',
  'ip': 'unassigned',
  'is_ok': 'YES',
  'method': 'unset',
  'protocol': 'down',
  'status': 'down'},]
'''


def parse_tabular_version_1(data_str='', regex_str=''):
    if not (isinstance(data_str, str) and isinstance(regex_str, str)):
        return ['input type error']

    p = re.compile(regex_str, re.MULTILINE)
    m = p.finditer(data_str)
    out = []
    for d in m:
        t = d.groupdict()
        for k, v in t.items():
            t[k] = v.strip()
        out.append(t)
    return out

def parse_tabular(data_str='', regex_str=''):
    if not (isinstance(data_str, str) and isinstance(regex_str, str)):
        return ['input type error']

    lines = data_str.split('\n')
    p = re.compile(regex_str)
    out = []
    for line in lines:

        m = p.search(line)

        if m:
            t = m.groupdict()
            for k, v in t.items():
                t[k] = v.strip()
            out.append(t)
    return out


class FilterModule(object):
    filter_map = {
        'parse_tabular': parse_tabular,
    }
    def filters(self):
        return self.filter_map
