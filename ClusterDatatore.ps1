add-pssnapin VMware.VimAutomation.Core
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
md Datastore


##VARIABLES!!
$OutputFileName	= "D:\inventario\$fecha\Datastore\cluster-Datastore-conf.html"
$ReportTitle	= "Recursos Infraestructura VMWare Configuracion Cluster Datastore"
$Propsc = @()
$Resultsclus = @()
##CSV DE SALIDA
$outputstore = "ClusterdatastoreConfESXi.csv"
###############################################################################################
write-host "############# INVENTARIO HOSTS ###################" -foregroundcolor green

foreach ($datastore in  get-datastorecluster)
	{
		Write-Host "Recolectando informacion del cluster datastore: <"$datastore.Name"> "
		$dc= get-datastorecluster $datastore
		$sdrslevel= $dc.SdrsAutomationLevel
		$spaceused=$dc.SpaceUtilizationThresholdPercent
		$estado=$dc.ExtensionData.PodStorageDrsEntry.StorageDrsConfig.PodConfig.Enabled
		if ($datastore -like "*EXC*" )
		{
		}
		else
		{
			if ($estado -eq $false)
			{
			$Propsc = @{
			ClusterDatastore=$dc.Name
			Estado=$estado
			Nivel_SDRS= $sdrslevel
			Nivel_Balanceo=$spaceused
			Remediado="OK"
			}
			$Resultsclus += New-Object PSObject -Property $Propsc
			}
			if ($sdrslevel -ne "FullyAutomated")
			{
			$dc | set-datastorecluster -SdrsAutomationLevel FullyAutomated
				if ($Propsc.ClusterDatastore -notcontains $dc.name)
					{
					$Propsc = @{
								ClusterDatastore=$dc.Name
								Estado=$estado
								Nivel_SDRS= $sdrslevel
								Nivel_Balanceo=$spaceused
								Remediado="OK"
								}
								$Resultsclus += New-Object PSObject -Property $Propsc
					}
			}
			if ($spaceused -ne 80)
			{
			$dc | set-datastorecluster -SpaceUtilizationThresholdPercent 80
			
			if ($Propsc.ClusterDatastore -notcontains $dc.name){
					$Propsc = @{
								ClusterDatastore=$dc.Name
								Estado=$estado
								Nivel_SDRS= $sdrslevel
								Nivel_Balanceo=$spaceused
								Remediado="OK"
								}
								$Resultsclus += New-Object PSObject -Property $Propsc
					}
			}
		
							
		}
							
	}
Write-Host "Creacion de archivos con la informacion de los hosts "



write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
###############################################################################################
$InputObject =  @{ 
				   
					 Object = $Resultsclus | Select-object ClusterDatastore, Estado, Nivel_SDRS, Nivel_Balanceo
				}
					
Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName

Invoke-Item $OutputFileName


#############MAIL###############
		#write-host "############# ENVIANDO CORREO AL GRUPO ###################" -foregroundcolor green
		$fecha= get-date -format "ddMMyyyy"
		$FROM="monitoreocloud@ypf.com"
		$TO="administracioncloudypf@ypf.com"
		$Asunto="ERRORES ENCONTRADOS en Configuracion de los Cluster Datastores"
		$cuerpo="En El siguiente archivo adjunto se encuentran los Clusters Datastores en los cuales se informan cuales pudieron ser remediados y cuales no"
		$adjuntos=$OutputFileName
		$smtp= "smtp-app-int.grupo.ypf.com"

		send-mailmessage -from $from -to $to -subject $asunto -body $cuerpo -Attachment $Adjuntos -smtpServer $smtp


