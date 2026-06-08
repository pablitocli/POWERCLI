#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1

# A simple example for the usage of Export-HtmlReport:
#
# A report is generated from a single PowerShell object
connect-viserver SSBUETYVMW01, SSBUETMVMW01 -user ypf\ys00837 -password VcoPS3011
$outputstore = "DataESXi.csv"
$dcenters= 	get-datacenter
write-host "############# INVENTARIO DATASTORE ###################" -foregroundcolor green
$Resultsstore = @()
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


$Resultsstore| Select-Object DATASTORE,VERSION,Estado,Porcentaje_Libre,Espacio_Total,Espacio_Usado,Espacio_Libre,SIOC,LUNID,VMHOST,PSP | Export-Csv $outputstore -NoTypeInformation

write-host "############# FIN INVENTARIO DATASTORE ###################" -foregroundcolor green
###############################################################################################


@{Object = $Resultsstore| Select-Object DATASTORE,VERSION,Estado,Porcentaje_Libre,Espacio_Total,Espacio_Usado,Espacio_Libre,SIOC,LUNID,VMHOST,PSP} | Export-HtmlReport -OutputFile "datastore.html" | Invoke-Item

Pop-Location
