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
md Relevamientos


##VARIABLES!!
$OutputFileName	= "D:\inventario\$fecha\Relevamientos\Veeam-Relevamientos.html"
$ReportTitle	= "Recursos Infraestructura VMWare - Relevamiento Veeam"
$Props1 = @()
$Results1 = @()
$Props2 = @()
$Results2 = @()
$Props3 = @()
$Results3 = @()
##CSV DE SALIDA
$outputstore = "Veeam-Relevamientos.csv"
###############################################################################################
write-host "############# COMIENZO DE INVENTARIO ###################" -foregroundcolor green

foreach ($dcenter in  get-datacenter BUET*)
	{
	Write-Host "Recolectando informacion del datacenter: <"$dcenter.Name"> "
	
	foreach ($cluster in get-datacenter $dcenter | get-cluster)
			{
			Write-Host "Recolectando informacion del cluster: <"$cluster.Name"> "
			$c_hdisk=0
			$TB_TOTAL=0
			$TB_TOTAL_FREE= 0
			$TB_TOTAL_USADOS=0
			$sql=0
			$apl=0
			$web=0
			$exc=0
			$dat=0
			$otro=0
			$lab=0
			
			$vmhost=get-cluster $cluster | get-vmhost
			$vms= get-cluster $cluster | get-vm
			$hard= $vms | get-harddisk
			$c_hdisk=$c_hdisk + $hard.count
			
			$c_vms=$vms.count
			$promedio= $c_hdisk / $c_vms 
			$sumadk= $hard | Measure-Object 'CapacityGB' -Sum
			$promedio_vmxgb= $sumadk.sum / $c_vms
	foreach ($vm in $vms)
			{
			$v= get-vm $vm
			if ($v.name -like "*sql*")
			{$sql=$sql + 1}
			elseif($v.name -like "*web*") 
			{$web=$web + 1}
			elseif($v.name -like "*exc*") 
			{$exc=$exc + 1}
			elseif($v.name -like "*dat*") 
			{$dat=$dat + 1}
			elseif($v.name -like "*lab*") 
			{$lab=$lab + 1}
			else
			{$otro=$otro +1}
			}
			
			$c_sql= ($sql / $c_vms ) * 100
			
			$c_web= ($web / $c_vms ) * 100
			$c_dat= ($dat / $c_vms ) * 100
 			$c_exc= ($exc / $c_vms ) * 100
			$c_otro= ($otro / $c_vms ) * 100
			$c_lab= ($lab / $c_vms ) * 100
			
			$Props1 = @{
				DATACENTER=$DCENTER
				CLUSTER=$Cluster
				C_HOST=$VMHOST.COUNT
				C_VMS=$c_vms 
				C_HARDISK= $c_hdisk
				PROMEDIO="{0:N0}" -f $Promedio
				PROMEDIO_VOL_VM= "{0:N2}" -f $promedio_vmxgb
				P_SQL= "{0:N1}" -f $c_sql
				P_APL= "{0:N1}" -f $c_otro
				P_WEB= "{0:N1}" -f $c_web
				P_EXC= "{0:N1}" -f $c_exc
				P_DAT= "{0:N1}" -f $c_dat
				P_LAB= "{0:N1}" -f $c_lab
				
			}
			$Results1 += New-Object PSObject -Property $Props1
			
			$maxs= $vms | sort ProvisionedSpaceGB -Descending | select-object -first 5
	foreach($max in $maxs)
			{
			
			$Props3 = @{
				DATACENTER=$DCENTER
				CLUSTER=$Cluster
				VM= $max.name
				VOLUMEN="{0:N2}" -f $MAX.ProvisionedSpaceGB 
				}
			$Results3 += New-Object PSObject -Property $Props3
			}

			
			}
	foreach ($datastore in get-datacenter $dcenter | get-datastore)
			{
			$TB_TOTAL= $TB_TOTAL+ $datastore.CapacityGB
			$TB_TOTAL_FREE= $TB_TOTAL_FREE+ $datastore.FreeSpaceGB
			}
			$TB_TOTAL_USADOS= $TB_TOTAL - $TB_TOTAL_FREE
			$Props2 = @{
				DATACENTER=$DCENTER
				TB_ASIGNADOS="{0:N2}" -f $TB_TOTAL
				TB_LIBRES="{0:N2}" -f $TB_TOTAL_FREE
				TB_USADOS= "{0:N2}" -f $TB_TOTAL_USADOS
				}
			$Results2 += New-Object PSObject -Property $Props2
	
	
			
	}
Write-Host "Creacion de archivos con la informacion de los hosts "



write-host "############# FIN INVENTARIO ###################" -foregroundcolor green
###############################################################################################
$InputObject =  @{ 
					Title="CANTIDADES EN CLUSTERS"
					Object = $Results1 | Select-object DATACENTER,CLUSTER,C_HOST,C_VMS,C_HARDISK,PROMEDIO,PROMEDIO_VOL_VM,P_APL,P_WEB,P_DAT,P_EXC,P_SQL,P_LAB,P_OTROS
				},
				@{ 
					Title="CANTIDADES EN DATASTORES"
					Object = $Results2 | Select-object DATACENTER,TB_ASIGNADOS,TB_LIBRES,TB_USADOS
				},
				@{ 
					Title="TOP 5 DE VMS CON MAYOR APROVISIONAMIENTO"
					Object = $Results3 | Select-object DATACENTER,CLUSTER,VM,VOLUMEN
				}
					
Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $OutputFileName

Invoke-Item $OutputFileName
cd\
cd .\Scripts\PortalV2


#############MAIL###############
		


