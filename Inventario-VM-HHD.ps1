
#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\bin\include\Export-HtmlReport.ps1
Write-Host "VERIFICACION DE LOS DISCOS VIRTUALES DE SERVIDORES SBASE" -backgroundcolor "blue"

#MD c:\TMPVMWARE
#MD c:\TMPVMWARE\html
#MD c:\TMPVMWARE\CSV

$outputhostHTML  = "c:\TMPVMWARE\html\vmdisks.html"
$outputhostCSV  = "c:\TMPVMWARE\CSV\vmdisks.csv"
$ReportTitle="Inventario Virtual Disk - SBASE"
 
$Resultsv=@()
$Propsv = @()
#$vcenter=read-host "Ingresar vCenter Server"
#connect-viserver $vcenter -user soporte@vsphere.local -password Soporte00! | out-null

foreach ($vmhost in get-vmhost)
		{
		foreach ($vm in get-vmhost $vmhost | get-vm)
				{
				$x= get-vm $vm
				$mem= $x.memorygb
				$vmdks= $x | get-harddisk
				foreach ($vmdk in $vmdks)
						{
						$file= $vmdk.filename
						$size= $vmdk.capacityGB
						$type= $vmdk.StorageFormat
						$label= $vmdk.extensiondata.deviceinfo.label
															
								Write-Host "GUARDANDO INFORMACION DEL SERVIDOR <"$vm.name"> " -foregroundcolor "black" -backgroundcolor "YELLOW"
			
								$Propsv = @{
								HOST=$vmhost.name
								VM=$VM.name
								MEMORIA=$MEM
								FILE=$FILE
								FORMATO=$TYPE
								ETIQUETA=$LABEL
								CAPACIDAD=$SIZE
								
											}
									
								$Resultsv += New-Object PSObject -Property $Propsv
														
						}
				}
		}

$objectos= "HOST","VM","MEMORIA","FILE","FORMATO","ETIQUETA","LETRA","CAPACIDAD"
$Resultsv | Select-Object $objectos| Export-Csv $outputhostCSV  -NoTypeInformation
		

$InputObject = 	@{
				   Title  = "Todas las VMs de la Infraestructura";
				   Object = $Resultsv | Select-Object $objectos}
				
				
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $outputhostHTML
		$outputhostHTML | Invoke-Item
