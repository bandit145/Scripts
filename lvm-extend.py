#!/usr/bin/env python3
import argparse
import sh
import re
import sys
import os
parser = argparse.ArgumentParser(description='Expand lvm vol')
parser.add_argument('-l','--lvm',help='lvm volume to extend',required=True)
parser.add_argument('-hd','--hdd',help='hdd if you are adding manually')
parser.add_argument('-pl','--pool',help='lvm pool to add hdd to',required=True)
parser.add_argument('-f','--filesystem',help='filesystem to grow',required=True)
parser.add_argument('--xfs',help='xfs file system',action='store_true')
parser.add_argument('--ext4',help='ext4 filesystem',action='store_true')
args = parser.parse_args()
#Require system-storage-manager
#add hdd
#ssm add -p cl device (hdd)
#ssm resize /dev/cl/root -s +100%FREE (Takes all avail space)
#xfs_growfs /

#check for new disks, if they exist add them to the main lvm pool
def check_disks(hdd, pool):
	try:
		with open(sys.path[0]+'/hdds','r') as file:
			hard_drives = [x.strip() for x in file.readlines()]
		hdd_list = sh.awk(sh.grep(sh.fdisk('-l'),'^Disk /dev/s'),'{print $2}').split(':')
		hdd_list = [x.strip() for x in hdd_list if x != '\n']
		if hdd_list == hard_drives:
			return False
		for hdd in hdd_list:
			if hdd not in hard_drives:
				add_hdd(hdd, pool)
		return True
	except IOError:
		print('Could not find file that tracks hdds, does "hdds" exist in {loc}?'.format(loc=sys.path[0]))

def add_hdd(hdd,pool):
	try:
		sh.ssm('add', '-p', pool, hdd)
		with open(sys.path[0]+'/hdds','a+') as file:
			file.write(hdd+'\n')
	except sh.ErrorReturnCode_2 as error:
		print('Could not add hdd ({hdd}) to pool'.format(hdd=hdd))
		print('Did you give me the wrong hdd?')
		#print(error)
		sys.exit(2)
	except IOError:
		print('Could not find file that tracks hdds, does "hdds" exist in {loc}?'.format(loc=sys.path[0]))

def extend_volume():
	try:
		sh.ssm('resize',args.lvm, '-s', '+100%FREE')
	except sh.ErrorReturnCode_2 as error:
		print('Could not resize '+args.lvm)
		#print(error)
		sys.exit(2)
	try:
		if args.xfs:
			result = sh.xfs_growfs(args.filesystem)
		elif arg.ext4:
			pass
	except sh.ErrorReturnCode_2 as error:
		print('Could not expand filesystem ({fs})'.format(fs=args.filesystem))
		#print(error)
		sys.exit(2)

def main():
	try:
		if not args.xfs and not args.ext4:
			print('You must specify a filesystem type!')
			parser.print_help()
			sys.exit(1)
		elif args.xfs and args.ext4:
			print('You must specify one filesystem!')
			parser.print_help()
			sys.exit(1)

		if os.getuid() != 0:
			print('This script require root privs!')
			sys.exit(1)
		
		if args.hdd:
			add_hdd(args.hdd, args.pool)
			extend_volume()
		else:
			result = check_disks(args.hdd, args.pool)
			if result:
				extend_volume()
			else:
				print('No Hardrives to add!')
				sys.exit(0)

	except sh.CommandNotFound:
		print('A command was not found, please make sure "system-storage-manager is installed on this host!"')
		sys.exit(2)
	except KeyboardInterrupt:
		print('User exit')
		sys.exit(0)

main()