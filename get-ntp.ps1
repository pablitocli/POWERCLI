#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\bin\include\Export-HtmlReport.ps1



Write-Host "VERIFICACION DE SERVICIO NTP EN LOS NODOS VMWARE" -backgroundcolor "blue"
$datacenter = "BUETY-DMZI"
$output = '$datacenter.csv'
$ReportTitle= "VERIFICACION DE SERVICIO NTP EN LOS NODOS VMWARE"
$outputhostHTML  = "E:\scriptsv2\$datacenter.html"
$Results = @()

$servers = Get-datacenter $datacenter | Get-VMHost
ForEach ($server in $servers) 
{ 
	$ntp= Get-VMHostNtpServer -VMHost $server
	$esxcli=get-vmhost $server | Get-EsxCli
	$hora=$esxcli.system.time.get()
		$props= @{
		HOST =$server.name 
		HORA=$hora
		NTP= $NTP -join "/" 
		}
$Results += New-Object PSObject -Property $Props
}
$Results | Export-Csv $output -NoTypeInformation

		

$InputObject = 	@{
				   Title  = "VERIFICACION DE SERVICIO NTP EN LOS NODOS VMWARE";
				   Object = $Results | Select-Object HOST,NTP,HORA}
				
				
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $outputhostHTML
		$outputhostHTML | Invoke-Item



		
		