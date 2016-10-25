[DSCLocalconfigurationManager()]
configuration LCMConfig
{
	Node "ADCSlocal"
	{

	settings
	{
		RefreshMode = 'Pull'
	}
	ConfigurationRepositoryWeb = 'webserver'
	{
		ServerURL = 'server'
		RegestrationKey = 'regkey'
		ConfigurationNames = @('ADCSconf')
	}
	ResourceRepositoryWeb = 'webserver'
	{
		
	}	
	ReportServerWeb = 'webserver'
	{
		ServerURL = 'server'
		RegestrationKey = 'regkey'
	}	
	
	}
}