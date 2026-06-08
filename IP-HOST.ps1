add-pssnapin VMware.VimAutomation.Core
Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1
connect-viserver SSBUETYVMW01 -alllinked -user ypf\ys00837 -password VcoPS3011
connect-viserver ssbuetyvmw03, ssbuetyvmw11

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
$OutputFileName	= "D:\inventario\$fecha\host\IP_NODOS.html"
$ReportTitle	= "Verificación de Direccionamiento IP de Infraestructura Virtual -  Administración Cloud YPF "
$Propsh = @()
$Resultshost = @()
$x= @()
##CSV DE SALIDA
$outputstore = "D:\inventario\$fecha\host\IP_NODOS.csv"


###############################################################################################


$x=GET-VMHOST
		foreach ($esx in $x){
		Write-Host "<<<<<<<<<<<<<"$esx.name" >>>>>>>>>>>>>>>>>>>>>>>>"
		$vmhost= get-vmhost $esx
		$gateway= get-vmhost $vmhost | get-vmhostnetwork
		$VMKs= $vmhost | get-vmhostnetworkadapter -name vmk*
		foreach ($vmk in $vmks)
		{
		$ip=$vmk.ip
		$mask=$vmk.subnetmask
		
		
		
		$Propsh = @{
					HOST = $vmhost
					VMKERNEL=$vmk.name
					IP= $ip
					MASCARA=$mask
					GATEWAY=$gateway.VMKernelGateway
					
					}
		
			$Resultshost += New-Object PSObject -Property $Propsh
			
		}
		}		
		Write-Host "Creacion de archivos con la informacion de los hosts "
		$objetos="HOST","VMKERNEL","IP","MASCARA","GATEWAY"
		
		$Resultshost | Select-Object $objetos | Export-Csv $outputstore -NoTypeInformation

		write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
		###############################################################################################
		$InputObject = @{Object = $Resultshost | Select-Object $objetos }
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName
		Invoke-Item $OutputFileName
		Pop-Location

		
		
		