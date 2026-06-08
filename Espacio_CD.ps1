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
$OutputFileName	= "D:\inventario\$fecha\Datastore\cluster-Datastore.html"
$ReportTitle	= "Recursos Infraestructura VMWare Cluster Datastore"
$Propsc = @()
$Resultsclus = @()
##CSV DE SALIDA
$outputstore = "ClusterdatastoreESXi.csv"
###############################################################################################
write-host "############# INVENTARIO HOSTS ###################" -foregroundcolor green



foreach ($datastore in  get-datastorecluster)
	{
		IF($datastore -like "*exc*"){}else {
		Write-Host "Recolectando informacion del cluster datastore: <"$datastore.Name"> "
		$20x=($datastore.capacityGB*20)/100
		$x="{0:N2}" -f $20x
		$a="{0:N2}" -f $datastore.freespacegb 
		$y= $x
		$solicitar= $a - $x
		if ($solicitar -le 0 )
		{
		$Propsc = @{
								ClusterDatastore=$datastore.Name
								Capacidad="{0:N2}" -f $datastore.capacityGB
								Espacio_Libre= "{0:N2}" -f $datastore.freespacegb
								"Limite_20%"=$y
								Falta_Solicitar= "{0:N2}" -f $solicitar
											}
								$Resultsclus += New-Object PSObject -Property $Propsc
		}
		}
		
							
	}
Write-Host "Creacion de archivos con la informacion de los hosts "



write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
###############################################################################################
$InputObject =  @{ 
				   
					 Object = $Resultsclus | Select-object ClusterDatastore, Capacidad, Espacio_Libre, "Limite_20%", Falta_Solicitar
				}
					
Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName

Invoke-Item $OutputFileName


#############MAIL###############
		#write-host "############# ENVIANDO CORREO AL GRUPO ###################" -foregroundcolor green
		$fecha= get-date -format "ddMMyyyy"
		$FROM="monitoreocloud@ypf.com"
		$TO="administracioncloudypf@ypf.com"
		$Asunto="Verificación de Espacio Disponible en los Cluster Datastores"
		$cuerpo="En El siguiente archivo adjunto se encuentran los Clusters Datastores que poseen menos espacio que el 20%"
		$adjuntos=$OutputFileName
		$smtp= "smtp-app-int.grupo.ypf.com"

		send-mailmessage -from $from -to $to -subject $asunto -body $cuerpo -Attachment $Adjuntos -smtpServer $smtp


