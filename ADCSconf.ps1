Configuration ADCSConfiguration{
	param(
		[PsCredential] $credential)
		
	Import-DSCResource -ModuleName PSDesiredStateConfiguration
	Import-DSCResource -ModuleName xComputerManagement
	Import-DSCResource -ModuleName XAdcsDeployment
	
	Node 'ADCSconf'{
		WindowsFeature ADCS-Cert-Authority{
			Ensure = 'Present'
			Name = 'ADCS-Cert-Authority'
			DependsOn = '[xComputer]Domain-join'
			}
		xADCSCertificationAuthority ADCS-Setup{
			Credential = $credential
			Ensure = 'Present'
			CAType = 'EnterpriseRootCA'
			HashAlgorithmName = 'SHA256'
			DependsOn = '[WindowsFeature]ADCS-Cert-Authority'
		}
		xComputer Domain-join{
			Name = 'test'
			DomainName = 'sharedhomelab.com'
			Credential = $credential
		}
	}
}

$cd =@{
	AllNodes = @(
		@{
			NodeName = 'ADCSconf'
			PSDscAllowPlainTextPassword = $true
			PSDscAllowDomainUser = $true
		}
	)
}