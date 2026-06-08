
#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\bin\include\Export-HtmlReport.ps1



Write-Host "VERIFICACION DE SERVIDORES APAGADOS" -backgroundcolor "blue"


$outputhostHTML  = "E:\PRDV2\exports\html\ssbuetyvmw11-host.html"
$outputhostCSV  = "E:\PRDV2\exports\csv\ssbuetyvmw11-host.csv"
$outputLUNCSV = "E:\PRDV2\exports\lun\ssbuetyvmw11-host.csv"
$ReportTitle="ssbuetyvmw11-host"
$clusters= get-datacenter buetm |get-cluster 


#############################################################################################################################################################################################
############################## VERIFICACIÓN DEL SERVIDOR ####################################################################################################################################
#############################################################################################################################################################################################
$C=0

$Resultsv=@()
$Propsv = @()
foreach ($cluster in $clusters){
$vmhosts= get-cluster $cluster | get-vmhost
		foreach ($vmhost in $vmhosts)
		{
				
			
		#############################################################################################################################################################################################
		############################## TOMA DE INFORMACION DEL SERVIDOR #############################################################################################################################
		#############################################################################################################################################################################################
				Write-Host "TOMANDO INFORMACION DEL SERVIDOR <"$vmhost.name">" -foregroundcolor "white" -backgroundcolor "blue"
				$vmhostx=get-vmhost $vmhost
				$ip= $vmhostx| Get-VMHostNetworkAdapter -name vmk0
				$state=$vmhost.ConnectionState

				Write-Host "GUARDANDO INFORMACION DEL SERVIDOR <"$vmhost.name"> " -foregroundcolor "black" -backgroundcolor "YELLOW"
			
				$Propsv = @{
								Cluster=$cluster.name
								Host=$vmhost.name
								ESTADO=$STATE
								IP=$ip.ip
								
							}
				$Resultsv += New-Object PSObject -Property $Propsv
				}
}
		
		
#############################################################################################################################################################################################
############################## GUARDADO DE INFORMACION DEL SERVIDOR #########################################################################################################################
#############################################################################################################################################################################################	
		$Resultsv | Select-Object Cluster,HOST,ESTADO,IP| Export-Csv $outputhostCSV  -NoTypeInformation
		

$InputObject = 	@{
				   Title  = "Servidores ssbuetyvmw11";
				   Object = $Resultsv | Select-Object Cluster,HOST,ESTADO,IP }
				
				
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $outputhostHTML
		$outputhostHTML | Invoke-Item
