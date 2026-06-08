#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1

# A simple example for the usage of Export-HtmlReport:
#
# A report is generated from a single PowerShell object

MD reportes\WINDOWS\$fecha
connect-viserver SSBUETYVMW01, SSBUETMVMW01 -user ypf\ys00837 -password VcoPS3011
$outputhost = "reportes\WINDOWS\$fecha\VMS-Reportes-windows.csv"
$outputhostHTML  = "reportes\WINDOWS\$fecha\VMS-Reportes-windows.html"
###############################################################################################
write-host "############# INVENTARIO HOSTS ###################" -foregroundcolor green
$clusters= get-cluster
$Resultshost = @()

foreach ($clus in $clusters)
	{
		Write-Host "Recolectando informacion del host del cluster: <"$clus.Name"> "
		$vms= get-cluster -name $clus | get-vm
		foreach ($vm in $vms){
							$ACC=0
							$vmview= get-vm $vm | get-view
							$info= get-vm $vm
							$hotmemory= $vmview.Config.MemoryHotAddEnabled
							$So=$info.ExtensionData.Guest.GuestFullName
							$toolsupdate=$vmview.Config.tools.ToolsUpgradePolicy
							$Virtualhw=$info.ExtensionData.Config.Version
							$toolstatus=$info.ExtensionData.Guest.ToolsVersionStatus
														
								foreach ($NIC in $info| Get-NetworkAdapter) {
									if ($NIC.Type -ne 'Vmxnet3')
									{
										$OldNic = $true 
										$ACC=$ACC+1
									} else {
									$OldNic = $false
										}
								}
							
							Write-Host "Guardando informacion del host: <"$vm.Name"> "
								$Propsh = @{
								Cluster=$Clus.Name
								Servidor=$info.name
								UpdateTool=$toolsupdate
								VMToolStatus=$vm.guest.extensiondata.toolsstatus
								VMToolVersion=$vm.guest.extensiondata.ToolsVersion
								SO=$SO
								E1000=$ACC
								HotMemoryAdd=$HOTMEMORY
								Estado=$info.powerstate
								VMVERSION=$Virtualhw 
								}
								$Resultshost += New-Object PSObject -Property $Propsh
							}
	}
Write-Host "Creacion de archivos con la informacion de los hosts "
$Resultshost | Select-Object CLUSTER, SERVIDOR,UPDATETOOL,VMTOOLSTATUS,VMVERSION,SO,E1000,ESTADO,HotMemoryAdd| Export-Csv $outputhost -NoTypeInformation

write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
###############################################################################################


@{Object = $Resultshost | Select-Object CLUSTER, SERVIDOR,UPDATETOOL,VMTOOLSTATUS,VMVERSION,SO,E1000,ESTADO } | Export-HtmlReport -OutputFile $outputhostHTML | Invoke-Item

Pop-Location
