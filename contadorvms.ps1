#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1
$outputhostHTML  = "cantidadvmsxdatacenter.html"
Connect-viserver ssbuetyvmw01 -alllinked
Connect-viserver ssbuetyvmw02 -alllinked
$dcenters= Get-datacenter
$Propsv = @{}
$Resultsv = @{}
	foreach ($dcenter in $dcenters)
	{
	Write-Host "Contando VMs en el Datacenter <"$dcenter.Name"> "
	$vms=get-datacenter $dcenter.name | get-vm
	$c_vms=$vms.count
	$Propsv = @{
		DATACENTER=$dcenter.name
		CANTIDAD=$c_vms
	}
	$Resultsv += New-Object PSObject -Property $Propsv
	}
@{Object = $Resultv | Select-Object DATACENTER,CANTIDAD } | Export-HtmlReport -OutputFile $outputhostHTML | Invoke-Item

Pop-Location