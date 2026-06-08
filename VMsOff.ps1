
#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\bin\include\Export-HtmlReport.ps1


Write-Host "BUSQUEDA DE VMS APAGADAS Y VOLUMEN OCIOSO" -backgroundcolor "blue"
connect-viserver ssbuetyvmw01 -alllinked

$outputhostHTML  = "E:\ScriptsV2\exports\VMsOff.html"
$ReportTitle="BUSQUEDA DE VMS APAGADAS Y VOLUMEN OCIOSO"
$Resultsvunix=@()
$Propsvunix = @()
$Resultsvwin=@()
$Propsvwin = @()

$folderunix= get-folder -name *unix* -type HostAndCluster
$folderwin= get-folder -name *win* -type HostAndCluster

foreach ($funix in $folderunix){
					$vmsunix= get-folder $funix | get-vm | Where {$_.PowerState -eq "PoweredOff"}
					foreach ($vm in $vmsunix)
					{
					$x=get-vm $vm
					$state=$X.powerstate
					$volumen= "{0:N2}" -f $x.ProvisionedSpaceGB
					$Propsvunix = @{
											VM=$x.name
											ESTADO=$state
											VOLUMEN=$volumen
											}
							$Resultsvunix += New-Object PSObject -Property $Propsvunix
					}
					}
foreach ($fwin in $folderwin){
					$vmswin= get-folder $fwin | get-vm | Where {$_.PowerState -eq "PoweredOff"}
					foreach ($vmx in $vmswin)
					{
					$xx=get-vm $vmx
					$statex=$Xx.powerstate
					$volumenx= "{0:N2}" -f $xx.ProvisionedSpaceGB
					$Propsvwin = @{
											VM=$xx.name
											ESTADO=$statex
											VOLUMEN=$volumenx
											}
							$Resultsvwin += New-Object PSObject -Property $Propsvwin
					}
					}					

					
					
					
					
	$InputObject =  @{
				   Title  = "BUSQUEDA DE VMS APAGADAS Y VOLUMEN OCIOSO - SISTEMA OPERATIVO UNIX";
				   Object = $Resultsvunix | Select-Object VM,ESTADO,VOLUMEN 
				   },
				   @{ 
				   Title  = "BUSQUEDA DE VMS APAGADAS Y VOLUMEN OCIOSO - SISTEMA OPERATIVO WINDOWS";
				   Object = $Resultsvwin | Select-Object VM,ESTADO,VOLUMEN}
				
				
		Export-HtmlReport -InputObject $InputObject -ReportTitle $ReportTitle -OutputFile $outputhostHTML
		$outputhostHTML | Invoke-Item
