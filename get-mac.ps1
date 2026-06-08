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
$OutputFileName	= "D:\inventario\$fecha\host\MAC-CTX.html"
$ReportTitle	= "Verificación de Mac Adress equipos CTX -  Administración Cloud YPF "
$Propsh = @()
$Resultshost = @()
$x= @()
##CSV DE SALIDA
$outputstore = "D:\inventario\$fecha\host\MAC-CTX.csv"


###############################################################################################


$x=get-cluster -NAME *CTX* | get-vm
		foreach ($vin $x){
		Write-Host "<<<<<<<<<<<<<"$v.name" >>>>>>>>>>>>>>>>>>>>>>>>"
		$vm= get-vm $v
		$net= $vm | get-networkadapter
		$mac= $net.MacAddress
		$ip=$vm.Guest.IPAddress
				
		$Propsh = @{
					VM = $VM.name
					IP= $ip
					MAC=$MAC
										
					}
		
			$Resultshost += New-Object PSObject -Property $Propsh
			
		
		}		
		Write-Host "Creacion de archivos con la informacion de los hosts "
		$objetos="VM","IP","MAC"
		
		$Resultshost | Select-Object $objetos | Export-Csv $outputstore -NoTypeInformation

		write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
		###############################################################################################
		$InputObject = @{Object = $Resultshost | Select-Object $objetos }
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName
		Invoke-Item $OutputFileName
		Pop-Location

		
		
		