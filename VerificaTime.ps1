add-pssnapin VMware.VimAutomation.Core
Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1
#connect-viserver SSBUETYVMW01 -alllinked -user ypf\ys00837 -password VcoPS3011
$fecha= get-date -format "ddMMyyyy"
$hora= get-date -format "T"
# A simple example for the usage of Export-HtmlReport:
#
# A report is generated from a single PowerShell object
###################################SALIDA DE DATOS#####################################
D:
cd\
cd inventario
cd CambioReloj

##VARIABLES!!
$OutputFileName	= "D:\inventario\CambioReloj\index.html"
$ReportTitle	= "Verificación de Servicio de NTP TIME de la Infraestructura Virtual -  Administración Cloud YPF "
$Propsh = @()
$Resultshost = @()
$x= @()
##CSV DE SALIDA
$outputstore = "D:\inventario\CambioReloj\CambioReloj.csv"


###############################################################################################
$ntps="10.1.4.121","10.1.4.120"
foreach ($esx in get-vmhost ) 
{
        Write-Host "<<<<<<<<<<<<<"$esx.name" >>>>>>>>>>>>>>>>>>>>>>>>"
        $servicesntp=Get-VMHostService -vmhost $esx | where {$_.key -eq "NTPD"}
 		$vmhost= get-vmhost $esx.name
		$ntp= Get-VMHostNtpServer -VMHost $vmhost
		$ntpserver= $ntp -join ", "
		get-vmhost $vmhost | %{$dts = get-view $_.ExtensionData.configManager.DateTimeSystem}
		#get host time
		$time = $dts.QueryDateTime().tolocaltime()
		#calculate time difference in secconds
		$timedife = ( $time - [DateTime]::Now).TotalSeconds
		$diferencia="{0:N2}" -f $timedife
        #if ($diferencia -gt "60" -or $diferencia -lt "-60" )
        #{
		#	Write-Host "<<<<<<<<<<<<<RESINCRONIZANDO"$esx.name" >>>>>>>>>>>>>>>>>>>>>>>>"
		#	$servicesntp | stop-VMHostService -confirm:$false

		#	$servicesntp | start-VMHostService -confirm:$false
		#	$REMEDIADO="RESINCRONIZADO"
			################################################################################
		#}
		#ELSE {$REMEDIADO="ESTADO OK"}
		
		$REMEDIADO="ESTADO OK"
		$Propsh = @{
					HOST = $vmhost
					HORA_EQUIPO=$time
					DIFERENCIA_TIEMPO= $diferencia
					NTP_SERVER=$ntpserver
					NTP_POLITICA=$servicesntp.policy
					NTP_ESTADO=$servicesntp.running
					ACCIONES=$REMEDIADO
					}
			$Resultshost += New-Object PSObject -Property $Propsh
			
}	
		Write-Host "Creacion de archivos con la informacion de los hosts "
		$objetos="HOST","HORA_EQUIPO","DIFERENCIA_TIEMPO","NTP_SERVER","NTP_POLITICA","NTP_ESTADO","ACCIONES"
		
		$Resultshost | Select-Object $objetos | Export-Csv $outputstore -NoTypeInformation

		write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
		###############################################################################################
		$InputObject = @{
						Title = "VERIFICACION DE HORARIOS EN LOS NODOS A LAS $hora"
						Object = $Resultshost | Select-Object $objetos 
						}
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName
		cd\
		cd .\Scripts\PortalV2
		.\VerificaTime.ps1
		#Invoke-Item $OutputFileName
		#Pop-Location

		
		