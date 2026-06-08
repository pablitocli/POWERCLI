add-pssnapin VMware.VimAutomation.Core
Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1
#connect-viserver vcenter6
$fecha= get-date -format "ddMMyyyy"
$hora= get-date -format "T"
# A simple example for the usage of Export-HtmlReport:
#
# A report is generated from a single PowerShell object
###################################SALIDA DE DATOS#####################################
D:
cd\
cd inventario
md $fecha
cd $fecha
md Networking

##VARIABLES!!
$OutputFileName	= "D:\inventario\$fecha\networking\CDP-HOST.html"
$ReportTitle	= "Verificación de CONEXIONES FISICAS de la Infraestructura Virtual -  Administración Cloud YPF "
$Propsh = @()
$Resultshost = @()
$x= @()
##CSV DE SALIDA
$outputstore = "D:\inventario\$fecha\networking\CDP-HOST.csv"

$vmhosts=  get-vmhost
foreach ($vmhost in $vmhosts){
$vmh = Get-VMHost $VMHost
Write-Host "VERIFICANDO NODO," $vmhost.name
If ($vmh.State -eq "Disconnected") {
  Write-Output "El Host $($vmh) Se encuentra en estado desconectado, Se continua con el proximo."
  }
Else {
  Get-View $vmh.ID | `
  % { $esxname = $_.Name; Get-View $_.ConfigManager.NetworkSystem} | `
  % { foreach ($physnic in $_.NetworkInfo.Pnic) {
    $pnicInfo = $_.QueryNetworkHint($physnic.Device)
    foreach( $hint in $pnicInfo ){
      # Write-Host $esxname $physnic.Device
      if ( $hint.ConnectedSwitchPort ) {
        $nicinfo=$hint.ConnectedSwitchPort
		$vmnic=$physnic.Device
		$swicth= $nicinfo.DevId
		$port= $nicinfo.PortId
		$Propsh = @{
					HOST=$esxname
					VMNIC= $vmnic
					SWICTH=$swicth
					PUERTO=$port
					}
		$Resultshost += New-Object PSObject -Property $Propsh
					
        }
      else {
        Write-Host "NO HAY INFORMACION DISPONIBLE POR CDP."
        }
      }
    
	}
	
  }
}

}

Write-Host "Creacion de archivos con la informacion de los hosts "
		$objetos="HOST","VMNIC","SWICTH","PUERTO"
		
		$Resultshost | Select-Object $objetos | Export-Csv $outputstore -NoTypeInformation

		write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
		###############################################################################################
		$InputObject = @{Object = $Resultshost | Select-Object $objetos }
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName
		

		#############MAIL###############
		#write-host "############# ENVIANDO CORREO AL GRUPO ###################" -foregroundcolor green
		$fecha= get-date -format "ddMMyyyy"
		$FROM="monitoreocloud@ypf.com"
		$TO="administracioncloudypf@ypf.com"
		$Asunto="Verificación de CONEXIONES FISICAS de la Infraestructura Virtual -  Administración Cloud YPF "
		$cuerpo="En El siguiente archivo adjunto la conexiones fisicas de todos los nodos de la infraestructura a modo de back-up"
		$adjuntos=$OutputFileName
		$smtp= "smtp-app-int.grupo.ypf.com"

		send-mailmessage -from $from -to $to -subject $asunto -body $cuerpo -Attachment $Adjuntos -smtpServer $smtp
		
		
		