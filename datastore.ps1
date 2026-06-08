add-pssnapin VMware.VimAutomation.Core
#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1
connect-viserver SSBUETYVMW01 -alllinked -user ypf\ys00837 -password VcoPS3011

$fecha= get-date -format "ddMMyyyy"
write-host "###############################################################" -foregroundcolor BLUE
D:
cd\
cd inventario
md $fecha
cd $fecha
md datastore


##VARIABLES!!
$OutputFileName	= "D:\inventario\$fecha\host\datastore-ESXI.html"
$ReportTitle	= "Recursos Infraestructura VMWare DATASTORES"
$Propsd = @()
$Resultsstore = @()
##CSV DE SALIDA
$outputstore = "DataESXi.csv"

##CONEXION VCENTER SERVER
connect-viserver SSBUETYVMW01 -ALLLINKED

##RECOPILACIÓN DE INFORMACION
$dcenters=get-datacenter BUETY

####COMIENZO INVENTARIO DATASTORES!!!
write-host "############# INVENTARIO DATASTORE ###################" -foregroundcolor green

foreach ($dcenter in $dcenters)
	{
		write-host "############# INVENTARIANDO DATACENTER <"$Dcenter"> ###################" -foregroundcolor green
		$clusters=get-datacenter $dcenter | get-cluster	
		
			foreach($cluster in $clusters)
			{
				write-host "############# INVENTARIANDO CLUSTER <"$CLUSTER"> ###################" -foregroundcolor green
				$vmhosts= get-cluster $cluster | get-vmhost
				
				foreach ($vmhost in $vmhosts)
						{
						$dstores= get-vmhost $vmhost | get-datastore
						foreach ($dstore in $dstores)
						{
						$store= get-datastore $dstore | Where {$_.Name -notlike "*Local*"}
						write-host "############# INVENTARIANDO CLUSTER <"$STORE.NAME"> ###################" -foregroundcolor green
						if($store.state -eq "Available"){
								$freegb= $store.freespacegb
								$capacitygb= $store.capacitygb
								$usedgb= $store.capacitygb - $store.freespacegb
								$version= $store.type
								$ver_vmfs=$store.extensiondata.info.vmfs.majorversion
								$vmfs=$version + $ver_vmfs
								$sioc=$store.StorageIOControlEnabled
								$freeporcentaje= ($store.FreeSpaceGB * 100)/$store.CapacityGB
								$lunids = $store.extensiondata.Info.Vmfs.Extent.diskname
								foreach ($lunid in $lunids){
								$esxcli= get-vmhost $vmhost | get-esxcli
								$psp= $esxcli.storage.nmp.device.list($lunid)
								$Propsd = @{
									vCenter = $cluster.Uid.Split(':@')[1]
									Datacenter = $dcenter
									Datastore = $store.name
									Cluster=$cluster.name
									Version=$vmfs
									Espacio_Usado="{0:N2}" -f $usedgb
									Espacio_Libre="{0:N2}" -f $freegb
									Espacio_Total="{0:N2}" -f $capacitygb
									Porcentaje_Libre= "{0:N2}" -f $freeporcentaje
									Estado=$store.extensiondata.overallstatus
									SIOC=$sioc
									LUNID= $lunid
									Nodo=$vmhost.name
									PSP=$psp.PathSelectionPolicy
									}
									$Resultsstore += New-Object PSObject -Property $Propsd
									}
									
							}
						}
						}
			}			
	}

$Resultsstore | Export-Csv $outputstore -NoTypeInformation

###########################################################################################################################

$InputObject =  @{ 
				   
					 Object = $Resultsstore | Select-object vCenter,Datacenter,Cluster,Datastore,Version,Espacio_Total,Espacio_Usado,Espacio_Libre,Porcentaje_Libre,Estado,SIOC,LUNID,Nodo,PSP
				}
				
					
Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName
Invoke-Item $OutputFileName

Pop-Location


