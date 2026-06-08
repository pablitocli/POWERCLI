
#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\bin\include\Export-HtmlReport.ps1



Write-Host "VERIFICACION DE SERVIDORES APAGADOS" -backgroundcolor "blue"


$outputhostHTML  = "E:\PRDV2\exports\html\ssbuetmvmw01.html"
$outputhostCSV  = "E:\PRDV2\exports\csv\ssbuetmvmw01.csv"
$outputLUNCSV = "E:\PRDV2\exports\lun\ssbuetmvmw01.csv"
$ReportTitle="ssbuetmvmw01"
$clusters= get-cluster
$vms= get-vm

#############################################################################################################################################################################################
############################## VERIFICACIÓN DEL SERVIDOR ####################################################################################################################################
#############################################################################################################################################################################################
$C=0

$Resultsv=@()
$Propsv = @()
foreach ($cluster in $clusters){
$vms= get-cluster $cluster | get-vm
		foreach ($vm in $vms){
				
			
		#############################################################################################################################################################################################
		############################## TOMA DE INFORMACION DEL SERVIDOR #############################################################################################################################
		#############################################################################################################################################################################################
				Write-Host "TOMANDO INFORMACION DEL SERVIDOR <"$vm.name">" -foregroundcolor "white" -backgroundcolor "blue"
				$vmx=get-vm $vm
				$ip= $vmx.Guest.IPAddress | where {([IPAddress]$_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork}
				$state=$vm.powerstate

				Write-Host "GUARDANDO INFORMACION DEL SERVIDOR <"$vm.name"> " -foregroundcolor "black" -backgroundcolor "YELLOW"
			
				$Propsv = @{
								Cluster=$cluster.name
								vm=$vmx.name
								ESTADO=$STATE
								IP=$ip -join "/"
								
							}
				$Resultsv += New-Object PSObject -Property $Propsv
				}
}
		
		
#############################################################################################################################################################################################
############################## GUARDADO DE INFORMACION DEL SERVIDOR #########################################################################################################################
#############################################################################################################################################################################################	
		$Resultsv | Select-Object Cluster,Vm,ESTADO,IP| Export-Csv $outputhostCSV  -NoTypeInformation
		

$InputObject = 	@{
				   Title  = "Servidores dentro del Datatore";
				   Object = $Resultsv | Select-Object Cluster,Vm,ESTADO,IP }
				
				
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $outputhostHTML
		$outputhostHTML | Invoke-Item
