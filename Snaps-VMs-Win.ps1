#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1

# A simple example for the usage of Export-HtmlReport:
#
# A report is generated from a single PowerShell object
$fecha= get-date -format "ddMMyyyy"
MD reportes\Windows\$fecha
connect-viserver SSBUETYVMW01, SSBUETMVMW01 -user ypf\ys00837 -password VcoPS3011
$outputhost = "reportes\Windows\$fecha\VMS-Reportes-SNAP-WIN.csv"
$outputhostHTML  = "reportes\Windows\$fecha\VMS-Reportes-SNAP-WIN.html"
###############################################################################################
write-host "############# INVENTARIO HOSTS ###################" -foregroundcolor green

$Resultsvms = @()
$Propsv = @()	
				
					
					$vms= get-vm
					foreach ($vmx in $vms)
					{
					
					$vm=get-vm $vmx
					Write-Host "Buscando snaps en la VM: <"$vm.Name"> "
					$vmsnap= get-snapshot $vm 
					if ($vmsnap -eq $null)
					{
					$snapname="NO TIENE"
					$snapsize="NO TIENE"
					$snapcreated="NO TIENE"
					$SNAPDAYS="NO TIENE"
					}
					else
					{
					$snapname=$vmsnap.name
					$snapsize=$vmsnap.sizemb / 1024
					$snapcreated=$vmsnap.Created
					$SNAPDAYS=$vmsnap.daysold
					}
					Write-Host "Guardando la informacion de snaps en la VM: <"$vm.Name"> "
					$Propsv = @{
								
								Servidor=$vm
								Snapname=$snapname
								Snapsize="{0:f2}" -f $snapsize
								SnapDias=$SNAPDAYS
								Snapcreated=$snapcreated
								
							}
					
					$Resultsvms += New-Object PSObject -Property $Propsv
					}		
	
$Resultsvms | Select-object Servidor,Snapname,Snapcreated,Snapsize,SnapDias | Export-Csv $outputvms -NoTypeInformation

@{Object = $Resultsvms | Select-object Servidor,Snapname,Snapcreated,Snapsize,SnapDias } | Export-HtmlReport -OutputFile $outputhostHTML | Invoke-Item

Pop-Location

write-host "############# FIN INVENTARIO VMS ###################" -foregroundcolor green