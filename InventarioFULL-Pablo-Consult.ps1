#add-pssnapin VMware.VimAutomation.Core
#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\include\Export-HtmlReport.ps1

##CONEXION VCENTER SERVER
$vcenter= write-host "vCenter Server Name"
$cred= get-credential
connect-viserver $vcenter -credential $cred

							

$fecha= get-date -format "ddMMyyyy"

write-host "###############################################################" -foregroundcolor BLUE


##VARIABLES!!
$OutputFileName	= "\Infra.html"
$ReportTitle	= "Inventario basico de Infraestructura VMWare - By PablitoCLI"
$Propsd = @()
$Propsrecuros = @()
$Resultsresc = @()
$Resultsstore = @()
$propvmcluster = @()
$ResultsrVMCLUSTER = @()
$propvmdrs = @()
$ResultsrVMdrs = @()
$Resultshost = @()
$Propsh = @()
$drsvmexceptions= @()
$VMConfigxCluster= @()
 
##CSV DE SALIDA
$outputstore = "CompletoESXi.csv"


##RECOPILACIÓN DE INFORMACION
$dcenters=get-datacenter

####COMIENZO INVENTARIO DATASTORES!!!
write-host "############# INVENTARIO DATASTORE ###################" -foregroundcolor green

foreach ($dcenter in $dcenters)
	{
		write-host "############# INVENTARIANDO DATACENTER <"$Dcenter"> ###################" -foregroundcolor green
		$clusters=get-datacenter $dcenter | get-cluster	
		$x=100
		$porc=0
			foreach($cluster in $clusters)
			{
			Write-Host "Recolectando informacion del cluster : <"$cluster.Name"> "
		$recursos= $cluster | get-vmhost
		$memusada=0
		$memtotal=0
		foreach ($recurso in $recursos){
		$memusada+= $recurso.MemoryUsageGB
		$memtotal+= $recurso.MemoryTotalGB
		}
		$porc= ($memusada * 100) / $memtotal
		if ($porc -le $x) {
		$x=$porc
		$dis= $cluster.name
		}
		$isolation= $cluster.HAIsolationResponse
		$canthost=$cluster.ExtensionData.Summary.numhosts
		$cant_host_ok=$cluster.ExtensionData.Summary.NumEffectiveHosts
		$admisioncontrol=$cluster.HAAdmissionControlEnabled
		$restartprioridad=$cluster.HARestartPriority
		$swapconfig=$cluster.VMSwapfilePolicy
		$vmmonitoring=$cluster.ExtensionData.Configuration.dasconfig.vmmonitoring
		$hostmonitoring=$cluster.ExtensionData.Configuration.dasconfig.hostmonitoring
		$hbdatastore=$cluster.ExtensionData.Configuration.DasConfig.HeartbeatDatastore
		$drsagresividad=$cluster.ExtensionData.Configuration.DrsConfig.VmotionRate
		$drsvmexceptions=$cluster.ExtensionData.Configuration.drsvmconfig
		$hbadata=""
		$i=$hbdatastore.count
		
		for($j=0; $j -lt $i; $j++){
		foreach ($data in ($cluster | get-vmhost | get-random | get-datastore)){
		$idx=$data.ExtensionData.MoRef.value
		$datahb=$hbdatastore.value[$j]
		if ($datahb -eq $idx){
		$hbadata+= $data.name
		$hbadata+=";"		
		}		
		}
		}
			
		$VMConfigxCluster=$cluster.ExtensionData.Configuration.DasVmConfig
		
		$Propsrecuros = @{
								Cluster=$cluster.Name
								HA_Estado= $cluster.HAEnabled
								HA_NIVEL= $Cluster.HAFailoverLevel
								DRS_Estado= $cluster.DrsEnabled
								DRS_Nivel= $cluster.DrsAutomationLevel
								DRS_AGRESIVIDAD=$drsagresividad
								ISOLATION= $isolation
								ADMISSION_CONTROL= $admisioncontrol
								RESTART_PRIORITY= $restartprioridad
								SWAP_CONFIG=$swapconfig
								DATASTORE_HEARTBEAT=$hbadata
								CANTIDAD_HOST=$canthost
								CANTIDAD_HOST_OK=$cant_host_ok
								MemoriaTotal="{0:n2}" -f $Memtotal
								MemoriaUsada= "{0:n2}" -f $Memusada
								"Porcentaje de Uso"=  "{0:n2}" -f $porc
								}
								$Resultsresc += New-Object PSObject -Property $Propsrecuros
			
			
			#### CONFIGURACIONES DE LAS VMS PARA EVENTOS DE HA ####
			Foreach ($VMconfig in $VMConfigxCluster){
				$v= $cluster | get-vm | where {$_.id -eq $vmconfig.key}
				$restartpriority=$VMconfig.DasSettings.RestartPriority
				$vmisolate=$VMconfig.DasSettings.IsolationResponse
				$propvmcluster  = @{
							CLUSTER=$Cluster.name
							SERVIDOR=$v.name
							RESTART_PRORITY=$restartpriority
							VM_ISOLATE=$vmisolate
									}
				$ResultsrVMCLUSTER += New-Object PSObject -Property $propvmcluster
							}
			
			#### EXCEPSIONES DE DRS EN EL CLUSTER ####
				if ($drsvmexceptions -eq $null)
				{
				$propvmdrs  = @{
									SERVIDOR="NO HAY EXCEPSIONES DE VMOTIONS PARA VMs EN EL CLUSTER "
									
											}
											$ResultsrVMdrs += New-Object PSObject -Property $propvmdrs
				
				}
				else
				{
				Foreach ($drsvms in $drsvmexceptions){
						$v= $cluster | get-vm | where {$_.id -eq $drsvms.key}
						$drsvmotion=$drsvms.Enabled
						$drsvmotionstate=$drsvms.Behavior
						$propvmdrs  = @{
									SERVIDOR=$v.name
									DRS_VMOTION=$drsvmotion
									DRS_CONFIG=$drsvmotionstate
											}
											$ResultsrVMdrs += New-Object PSObject -Property $propvmdrs
						
				}
				
				}
			
			write-host "############# INVENTARIANDO CLUSTER <"$CLUSTER"> ###################" -foregroundcolor green
							
						foreach ($vmhost in get-cluster $cluster | get-vmhost)
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
								DATACENTER= $dcenter
								CLUSTER = $cluster.name
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
								TIENE_1000V=$na
								EQUIPO_NEXUS=$vds
								MODELO_NEXUS=$des_nexus
								VMNIC_Driver=$nic.driver
								VMNIC_Firmware=$nic.firmware
								VMNIC_DriverVersion=$nic.driverversion
								HBA_MODEL=$hba_model
								HBA_STATUS=$hba_status
								QUEUDEPTH=$qdhba
								
															}
							$Resultshost += New-Object PSObject -Property $Propsh
								}
							$nic=0
							$na=""
							$nombre_nexus=""
							$des_nexus=""
						}
			}
	}



###########################################################################################################################

$InputObject =  @{ 
					 Title= "Configuración y Recursos de los Clusters";
					 Object = $Resultsresc | Select-object Cluster, HA_Estado, HA_NIVEL, DRS_Estado, DRS_Nivel, DRS_AGRESIVIDAD, ISOLATION, ADMISSION_CONTROL, RESTART_PRIORITY, SWAP_CONFIG, DATASTORE_HEARTBEAT,CANTIDAD_HOST, CANTIDAD_HOST_OK, MemoriaTotal, MemoriaUsada, "Porcentaje de Uso"
				},
				@{ 
				    Title= "Configuración de las VMs para Eventos de HA";
					 Object = $ResultsrVMCLUSTER | Select-object Cluster, SERVIDOR, RESTART_PRORITY,VM_ISOLATE
				},
				@{ 
				    Title= "Inventario y configuración de los HOST ESXI de la Infraestructura";
					 Object = $Resultshost | Select-object DATACENTER, CLUSTER, HOST, IP, MODELO, SERIAL, BIOS_VERSION, BIOS_FECHA, VERSION, BUILD, CPU, CORES, MEMORIA, MEMORIA_USADA, MEMORIA_PORC, HORA_EQUIPO, DIFERENCIA_TIEMPO, NTP_SERVER, NTP_POLITICA, NTP_ESTADO, SSH_POLITICA, SSH_ESTADO, ESX_SHELL_POLITICA, ESX_SHELL_ESTADO, TIENE_1000V, EQUIPO_NEXUS, MODELO_NEXUS, VMNIC_Driver, VMNIC_Firmware, VMNIC_DriverVersion, HBA_MODEL, HBA_STATUS, QUEUDEPTH
				},
				@{ 
					Title= "Excepsiones de DRS del cluster";
					 Object = $ResultsrVMdrs
				}
				
					
Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName
Invoke-Item $OutputFileName



		
		
