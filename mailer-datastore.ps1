add-pssnapin VMware.VimAutomation.Core
#############MAIL###############
write-host "############# ENVIANDO CORREO AL GRUPO ###################" -foregroundcolor green
$fecha= get-date -format "ddMMyyyy"
$FROM="monitoreocloud@ypf.com"
$TO="administracioncloudypf@ypf.com"
$Asunto="Inventario Infraestructura virtual-DATASTORE"
$cuerpo="Correo Interno Semanal con información sobre la Infraestructura Virtual a nivel Datastore con fecha $fecha"
$adjuntos="D:\inventario\$fecha\host\datastore-ESXI.html"
$smtp= "smtp-app-int.grupo.ypf.com"

send-mailmessage -from $from -to $to -subject $asunto -body $cuerpo -Attachment $Adjuntos -smtpServer $smtp




