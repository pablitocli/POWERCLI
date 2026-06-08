add-pssnapin VMware.VimAutomation.Core
Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1
connect-viserver SSBUETYVMW01 -alllinked -user ypf\ys00837 -password VcoPS3011
$fecha= get-date -format "ddMMyyyy"
# A simple example for the usage of Export-HtmlReport:
#
# A report is generated from a single PowerShell object
###################################SALIDA DE DATOS#####################################
D:
cd\
cd inventario
md $fecha
cd $fecha
md host

##VARIABLES!!
$OutputFileName	= "D:\inventario\$fecha\host\NTP-HOST.html"
$ReportTitle	= "Verificación de Servicio de NTP TIME de la Infraestructura Virtual -  Administración Cloud YPF "
$Propsh = @()
$Resultshost = @()
$x= @()
##CSV DE SALIDA
$outputstore = "D:\inventario\$fecha\host\NTP-HOST.csv"


###############################################################################################

$ntps="10.1.4.120","10.1.4.121"
$x=foreach ($esx in get-vmhost) {Get-VMHostService -vmhost $esx | where {$_.key -eq "NTPD" -and $_.Running -eq $false } | select @{n="VMHost";e={$esx.name}},running}
if ($x -ne $null)
		{
		foreach ($esx in $x){
		Write-Host "<<<<<<<<<<<<<"$esx.vmhost" >>>>>>>>>>>>>>>>>>>>>>>>"
		$vmhost= get-vmhost $esx.vmhost
		$ntp= Get-VMHostNtpServer -VMHost $vmhost
		$ntpserver= $ntp -join ", "
		get-vmhost $vmhost | %{$dts = get-view $_.ExtensionData.configManager.DateTimeSystem}
		#get host time
		$time = $dts.QueryDateTime().tolocaltime()
		#calculate time difference in secconds
		$timedife = ( $time - [DateTime]::Now).TotalSeconds
		$diferencia="{0:N2}" -f $timedife
		$Services= $vmhost | get-vmhostservice
		$ntpservices= $services | where {$_.key -eq "ntpd"}
		
		#####################REMEDIACION######################################
		Write-Host "<<<<<<<<<<<<<REMEDIANDO"$esx.vmhost" >>>>>>>>>>>>>>>>>>>>>>>>"
		$ntpservices | Set-VMHostService -Policy on -confirm:$false
		if ($ntpserver -eq $null )
		{
		$vmhost|Add-VmHostNtpServer -NtpServer $ntps
		}
		elseif ($ntpserver -ne $ntps)
		{
		$vmhost|Remove-VMHostNtpServer -NtpServer $ntpserver -Confirm:$false
		$vmhost|Add-VmHostNtpServer -NtpServer $ntps
		}
		$vmhost| Where-Object {
		$t = Get-Date
		$dst = $_ | %{ Get-View $_.ExtensionData.ConfigManager.DateTimeSystem }
		$dst.UpdateDateTime((Get-Date($t.ToUniversalTime()) -format u))
		}
		$ntpservices | start-VMHostService -confirm:$false
		################################################################################
		
		$Propsh = @{
					HOST = $vmhost
					HORA_EQUIPO=$time
					DIFERENCIA_TIEMPO= $diferencia
					NTP_SERVER=$ntpserver
					NTP_POLITICA=$ntpservices.policy
					NTP_ESTADO=$ntpservices.running
					}
		#####################APERTUDA DE INCIDENTE######################################
			$grupo="ADMIN-CLOUD-YPF"
			$titulo="El siguiente nodo posee el servicio de NTP en estado STOPPED $vmhost"
			$des="Dicho nodo pose una diferencia horario de $diferencia"
						
			& 'D:\Scripts\PortalV2\bin\PosteINCGUIV2.exe' $titulo $des $grupo
				
		################################################################################
			$Resultshost += New-Object PSObject -Property $Propsh
			
		}	
		Write-Host "Creacion de archivos con la informacion de los hosts "
		$objetos="HOST","HORA_EQUIPO","DIFERENCIA_TIEMPO","NTP_SERVER","NTP_POLITICA","NTP_ESTADO"
		
		$Resultshost | Select-Object $objetos | Export-Csv $outputstore -NoTypeInformation

		write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
		###############################################################################################
		$InputObject = @{Object = $Resultshost | Select-Object $objetos }
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName
		Invoke-Item $OutputFileName
		Pop-Location

		
		#############MAIL###############
		#write-host "############# ENVIANDO CORREO AL GRUPO ###################" -foregroundcolor green
		$fecha= get-date -format "ddMMyyyy"
		$FROM="monitoreocloud@ypf.com"
		$TO="administracioncloudypf@ypf.com"
		$Asunto="Verificación de Servicio de NTP TIME de la Infraestructura Virtual"
		$cuerpo="En El siguiente archivo adjunto se encuentran los nodos que posee el servicio de NTP TIME en estado STOPPED"
		$adjuntos=$OutputFileName
		$smtp= "smtp-app-int.grupo.ypf.com"

		send-mailmessage -from $from -to $to -subject $asunto -body $cuerpo -Attachment $Adjuntos -smtpServer $smtp
		
		}
		