from Setup import clone
def main():
	name = input("Enter your username for the ESXi machine > ")
	pswd = input("Enter your password for the ESXi machine > ")
	deploy = clone(name,pswd)
	deploy.check_other_clones()
main()