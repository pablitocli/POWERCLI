add-pssnapin VMware.VimAutomation.Core
#Requires -Version 2.0
Set-StrictMode -Version Latest

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
md datastore

##VARIABLES!!
$OutputFileName	= "D:\inventario\$fecha\host\datastore-ESXI.html"
$ReportTitle	= "Inventario de los Datastores de la Infraestructura Virtual -  Administración Cloud YPF "
$Propsd  = @()
$Resultsstore = @()
##CSV DE SALIDA
$outputstore = "D:\inventario\$fecha\host\datastore-ESXI.csv"
$ls=""

###############################################################################################
write-host "############# INVENTARIO DATASTORE ###################" -foregroundcolor green
$dcenters= 	get-datacenter

$folders= get-folder -type Datastore
	foreach ($folder in $folders){
	
	$dstores= get-folder $folder.name | get-datastore 
	foreach ($dstore in $dstores)
		{
		$store= get-datastore $dstore | Where {$_.Name -notlike "*Local*"}
		$freegb= $store.freespacegb
		$capacitygb= $store.capacitygb
	    if ($capacitygb -gt 0) {
		$usedgb= $store.capacitygb - $store.freespacegb
		$version= $store.type
		$ver_vmfs=$store.extensiondata.info.vmfs.majorversion
		$vmfs=$version + $ver_vmfs
		$sioc=$store.StorageIOControlEnabled
		$freeporcentaje= ($store.FreeSpaceGB * 100)/$store.CapacityGB
		$datastore= $store | get-View -Property Name,Info
        $lunid = $Datastore.Info.Vmfs.Extent | select diskname
        $psps=$store | Get-ScsiLun | Select VMHost,MultipathPolicy 
		foreach ($l in $lunid){$ls += $l.diskname + "/"}
		foreach ($p in $psps){
		$hp=$p.vmhost.name
		$mp=$p.MultipathPolicy
				
		$Propsd = @{
			Folder=$folder.name
			Datastore = $dstore.name
			Version=$vmfs
			Espacio_Usado="{0:f2}" -f $usedgb
			Espacio_Libre="{0:f2}" -f $freegb
			Espacio_Total="{0:f2}" -f $capacitygb
			Porcentaje_Libre= "{0:f2}" -f $freeporcentaje + "%"
			Estado=$store.extensiondata.overallstatus
			VMHOST=$hp
            PSP=$mp
            SIOC=$sioc
			LUNID=$ls
			}
				$Resultsstore += New-Object PSObject -Property $Propsd
				$ls=""
            }
		}
		}
		}



write-host "############# FIN INVENTARIO DATASTORE ###################" -foregroundcolor green
$objetos="FOLDER","DATASTORE","VERSION","Estado","Porcentaje_Libre","Espacio_Total","Espacio_Usado","Espacio_Libre","SIOC","LUNID","VMHOST","PSP"


Write-Host "Creacion de archivos con la informacion de los DATASTORES "

$Resultshost | Select-Object $objetos | Export-Csv $OutputFileName -NoTypeInformation

write-host "############# FIN INVENTARIO HOSTS ###################" -foregroundcolor green
###############################################################################################
$InputObject = @{
				Title= "TOP 10 DE DATASTORE CON MENOS ESPACIO EN DISCO"
				Object = $Resultshost | Select-Object $objetos -FIRST 10 | Sort-object -property Porcentaje_Libre
				},
				@{
				Title= "Inventario Total de Datastores"
				Object = $Resultshost | Select-Object $objetos
				}
				
Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName

d:
cd\
cd scripts\portalv2
#.\mailer-datastore.ps1

Invoke-Item $OutputFileName


Pop-Location

