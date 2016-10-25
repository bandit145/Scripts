from pyVim.connect import SmartConnect
from pyVmomi import vim
import ssl
import getpass


context = ssl.SSLContext(ssl.PROTOCOL_TLSv1)
context.verify_mode = ssl.CERT_NONE
server = 'vcenter.meme.com'
user = input('Enter username ')
password = getpass.getpass('Enter password')

connect = SmartConnect(host=server,user=user,pwd=password, sslContext=context)
content = connect.RetrieveContent()
for child in content.rootFolder.childEntity:
	if hasattr(child,'vmFolder'):
		datacenter = child
		vmfolder = datacenter.vmFolder
		vmlist = vmfolder.childEntity
		for vm in vmlist:
			if 'meme-rootca001' in vm.summary.config.name:
				print(vim.vm.ConfigInfo(name='meme-rootca001')) 
