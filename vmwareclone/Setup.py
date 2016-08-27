import paramiko
import configparser
import re
import subprocess
import os

class clone:
	def __init__(self,name,pswd):
		self.config = configparser.ConfigParser()
		self.sections = self.config.read('config.ini')
		server = self.config.items('server')
		server = dict(server)
		self.address = server['address']
		self.vmname = server['vmname']
		self.regex = re.compile(r'\b'+self.vmname+r'\b')
		self.client = paramiko.client.SSHClient()
		self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
		self.client.connect(self.address, username=name, password=pswd)
		self.dir=os.getcwd()
		
		
	def ssh_clone(self,number):
		clonedrive = self.vmname
		clonedrive+=str(number)
		stdin, stdout, stderr = self.client.exec_command('vmkfstools -i /vmfs/volumes/datastore1/'+self.vmname+'/'+self.vmname+'-000001.vmdk /vmfs/volumes/datastore1/Clone/'+clonedrive+'.vmdk -d thin')
		print(stdout.readlines())
		print(stderr.readlines())
	
	def check_other_clones(self):
		stdin, stdout, stder = self.client.exec_command('cd /vmfs/volumes/datastor1 && ls')
		if 'Clone' not in stdout.readlines():
			stdin, stdout, stderr = self.client.exec_command('mkdir /vmfs/volumes/datastore1/Clone')
		stdin, stdout, stderr = self.client.exec_command('cd /vmfs/volumes/datastore1/Clone && ls')
		number = 1
		for vms in stdout.readlines():
			check = self.regex.match(self.vmname)
			if check:
				number = number +1
			else:
				number = 1
		self.ssh_clone(number)

	