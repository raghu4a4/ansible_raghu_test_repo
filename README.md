# README #
Ansible folder consits for 2 playbooks 
1) db_setup_install.yml 
### this playbook calls different roles based on the tags selected during calling the playbook
### first it will add the remote host to empty group and calls the roles on that group

### db_setup role: 
    - Role to setup Oracle user Profile, Maintainace Scripts
    - Crontab and auto start/stop scripts in oracle
### db_db_install: 
    - Performs installation on the Remote Server
### db_create: 
    - Creates the databases with sql scripts 
### db_checklist: 
	- Creates the db checklist 
	- validates the values obtained to the facts
	- if validations are failed triggers email to dba team about the failure
	- finally creates checklist in pdf format
	- uses custom plugin filter - "parse_tabular.py" which helps to change the tabular type of data to 
	  simple json based on regex we provide to match 

2) cloudendure.yml
### cloud_endure role:
   this playbook is used to rollout cloudendure agent on given server
   Evaluate windows or linux host by name validation
   add to empty host group
   evaluate again server os by logging into server - double check
   check if already agent is already installed
   if installed skip later steps else perform install
   delete the install file finally 
