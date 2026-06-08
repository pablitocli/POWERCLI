
#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\bin\include\Export-HtmlReport.ps1


Write-Host "BUSQUEDA DE CONFIGURACIONES Y RECURSOS DEL CLUSTER " -backgroundcolor "blue"
#connect-viserver 10.2.0.210  -user zeni\administrador -password traNsaccioN

$outputhostHTML  = "E:\ScriptsV2\exports\Infra-ESXI-ZENI.html"
$ReportTitle="INFRAESTRUCTURA ZENI"
$Propsh = @()
$Resultshost= @()


###############################################################################################
write-host "############# INVENTARIO HOSTS ###################" -foregroundcolor green
$datacenters=get-datacenter
foreach ($datacenter in $datacenters){
	$clusters= get-datacenter $datacenter | get-cluster
	foreach ($clus in $clusters)
		{
			Write-Host "Recolectando informacion del host del cluster: <"$clus.Name"> "
			$vmhosts= get-cluster -name $clus | get-vmhost
			foreach ($vmhost in $vmhosts)
								{
								Write-Host "Recolectando informacion del host: <"$vmhost.Name"> "
								$info= get-vmhost $vmhost
								$v=$info | get-view
							$serial=$v.Hardware.SystemInfo.OtherIdentifyingInfo | where {$_.IdentifierType.Key -eq "ServiceTag"}
							$biosversion=$v.hardware.biosinfo.biosversion
							$biosdate=$v.hardware.biosinfo.releasedate
							$mem= $info.memorytotalGB
							$usadamem=$info.MemoryUsageGB
							$porc= ( $info.MemoryUsageGB * 100 ) / $info.memorytotalGB 
							$gnic= get-vmhostnetworkadapter -vmhost $vmhost -name vmk0
							$Services= $info | get-vmhostservice
							$ntpservices= $services | where {$_.key -eq "ntpd"}
							$SSHservices= $services | where {$_.key -eq "TSM"} 
							$SHELLservices= $services | where {$_.key -eq "TSM-SSH"}
							$ntp= Get-VMHostNtpServer -VMHost $vmhost
							$ntpserver= $ntp -join ", "
							get-vmhost $vmhost | %{$dts = get-view $_.ExtensionData.configManager.DateTimeSystem}
							#get host time
							$time = $dts.QueryDateTime().tolocaltime()
							#calculate time difference in secconds
							$timedife = ( $time - [DateTime]::Now).TotalSeconds							
							$nexus=get-vmhost $vmhost | Get-VirtualPortGroup -Distributed
							if ($nexus -eq $null)
							{
							$na="NO"
							$nombre_nexus="NO TIENE"
							$des_nexus="NO TIENE"
							$vds="NO TIENE"
							}
							else
							{
							$na="SI"
							$nombre_nexus= get-vmhost $vmhost | Get-VirtualPortGroup -Distributed | where {$_.virtualswitch -like "VSM*"} | select virtualswitch | select-object -index 1
							$vds=Get-VirtualSwitch -vmhost $vmhost -name $nombre_nexus.virtualswitch
							$des_nexus=$vds.ExtensionData.Summary.Description
							
							}
							$vsw=get-vmhostnetworkadapter $vmhost -name vmnic*
							$vnics=$vsw.name
							foreach ($vnic in $vnics)
									{
									$esxcli=get-vmhost $vmhost | get-view
									$nic=get-vmhostnetworkadapter $vmhost -name $vnic
									$vnic_pci=$nic.ExtensionData.Pci
									$data=$esxcli.Hardware.PciDevice | where { $_.id -like $vnic} | select VendorName, DeviceName
									$nic=get-vmhost $vmhost | ? { $_.Version -gt 5} | get-esxcli | select @{N="HostName"; E={$_.system.hostname.get().FullyQualifiedDomainName}},@{N="Driver";E={$_.network.nic.get($vnic).DriverInfo.Driver}},@{N="Firmware";E={$_.network.nic.get($vnic).DriverInfo.FirmwareVersion}},@{N="DriverVersion";E={$_.network.nic.get($vnic).DriverInfo.Version}}
									}
									$hbas=Get-VMHostHba -vmhost $vmhost -type "FibreChannel" | select model, status
									foreach ($hba in $hbas)
									{
									$hba_model=$hba.model
									$hba_status=$hba.status
									$esxcli = Get-EsxCli -VMHost $vmhost
									if($hba_model -like "Brocade*") {$qdhba= $esxcli.system.module.parameters.list("bfa") | where {$_.Name -eq "bfa_lun_queue_depth"}}
									ELSE {$qdhba= $esxcli.system.module.parameters.list("qlnativefc") | where {$_.Name -eq "ql2xmaxqdepth"}}
									if ($qdhba.value -eq "") {$qdhba="SIN VALOR"} else {$qdhba=$qdhba.value}
													
							$Propsh = @{
								DATACENTER= $datacenter
								CLUSTER = $clus.name
								HOST = $vmhost
								IP = $gnic.ip
								MODELO=$info.model
								SERIAL=$serial.IdentifierValue
								BIOS_VERSION=$biosversion
								BIOS_FECHA=$biosdate
								VERSION=$info.version
								BUILD=$info.build
								CPU=$info.processortype 
								CORES=$info.numcpu
								MEMORIA= "{0:N2}" -f $mem
								MEMORIA_USADA= "{0:N2}" -f $usadamem
								MEMORIA_PORC= "{0:N2}" -f $porc
								HORA_EQUIPO=$time
								DIFERENCIA_TIEMPO= "{0:N2}" -f $timedife
								NTP_SERVER=$ntpserver
								NTP_POLITICA=$ntpservices.policy
								NTP_ESTADO=$ntpservices.running
								SSH_POLITICA=$SSHservices.policy
								SSH_ESTADO=$SSHservices.running
								ESX_SHELL_POLITICA=$SHELLservices.policy
								ESX_SHELL_ESTADO=$SHELLservices.running
								#TIENE_1000V=$na
								#EQUIPO_NEXUS=$vds
								#MODELO_NEXUS=$des_nexus
								VMNIC_Driver=$nic.driver
								VMNIC_Firmware=$nic.firmware
								VMNIC_DriverVersion=$nic.driverversion
								HBA_MODEL=$hba_model
								HBA_STATUS=$hba_status
								#QUEUDEPTH=$qdhba
								
															}
							write-host $propsh								
							$Resultshost += New-Object PSObject -Property $Propsh
								}
							$nic=0
							$na=""
							$nombre_nexus=""
							$des_nexus=""
							
								}
		}
}
Write-Host "Creacion de archivos con la informacion de los hosts "
$objetos="DATACENTER","CLUSTER","HOST","IP","MODELO","BIOS_VERSION","BIOS_FECHA","SERIAL","VERSION","BUILD","CPU","CORES","MEMORIA","MEMORIA_USADA","MEMORIA_PORC","HORA_EQUIPO","DIFERENCIA_TIEMPO","NTP_SERVER","NTP_POLITICA","NTP_ESTADO","SSH_POLITICA","SSH_ESTADO","ESX-SHELL_POLITICA","ESX-SHELL_ESTADO","TIENE_1000V","EQUIPO_NEXUS","MODELO_NEXUS","VMNIC_Driver","VMNIC_Firmware","VMNIC_DriverVersion","HBA_MODEL","HBA_STATUS","QUEUDEPTH"

$Resultshost | Select-Object $objetos | Export-Csv $outputhostHTML -NoTypeInformation

write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
###############################################################################################
$InputObject = @{Object = $Resultshost }
Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $outputhostHTML



Invoke-Item $outputhostHTML


Pop-Location

