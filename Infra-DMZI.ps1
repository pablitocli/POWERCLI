
#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\bin\include\Export-HtmlReport.ps1


Write-Host "BUSQUEDA DE CONFIGURACIONES Y RECURSOS DEL CLUSTER " -backgroundcolor "blue"
#connect-viserver 10.2.0.210  -user zeni\administrador -password traNsaccioN

$outputhostHTML  = "E:\ScriptsV2\exports\Infra-ZENI.html"
$ReportTitle="INFRAESTRUCTURA ZENI"
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
$x=100
$porc=0
$clusters =get-cluster
foreach ($cluster in $clusters){

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
							}
		
		

					
					

					
					
	$InputObject =  @{
				   Title  = "CONFIGURACION Y RECURSOS DEL CLUSTER"
				   Object = $Resultsresc | Select-object Cluster, HA_Estado, HA_NIVEL, DRS_Estado, DRS_Nivel, DRS_AGRESIVIDAD, ISOLATION, ADMISSION_CONTROL, RESTART_PRIORITY, SWAP_CONFIG, DATASTORE_HEARTBEAT,CANTIDAD_HOST, CANTIDAD_HOST_OK, MemoriaTotal, MemoriaUsada, "Porcentaje de Uso"
				   
				   }
				
				
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $outputhostHTML
		$outputhostHTML | Invoke-Item
