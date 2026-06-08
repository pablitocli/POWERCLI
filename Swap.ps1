
#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\sitio\include\Export-HtmlReport.ps1

write-host "############# BUSCANDO CONFIGURACION SWAP ###################" -foregroundcolor green

$outputhostHTML  = "swap.html"
$vms= get-vm -name PRD_suarbuwcp2p*
$Propsv = @()
$Resultsv = @()
foreach ($vm in $vms){
$vmx=get-vm $vm
$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
$vmConfigSpec.extraconfig += New-Object VMware.Vim.optionvalue
$keyswap=$vmx.ExtensionData.Config.ExtraConfig | where {$_.Key -eq "sched.swap.dir"}
write-host "############# CAMBIANDO PARAMETRO ###################" -foregroundcolor green
$vmConfigSpec.extraconfig[0].Key=$keyswap.key
$vmConfigSpec.extraconfig[0].Value=""
if ($keyswap -ne $null)
			{
			write-host "############# GUARDANDO SWAP PARAMETRO  <"$VM.Name">###################" -foregroundcolor green
			$Propsv = @{
				vm=$vm.name
				key=$keyswap.key
				value=$keyswap.value
			}
			}
			else
			{
			write-host "############# NO TIENE CONFIGURACION SWAP <"$VM.Name">###################" -foregroundcolor green
			$Propsv = @{
				vm=$vm.name
				key="NO TIENE PARAMETRO"
				value="NO TIENE PARAMETRO"
			}
			}
		$Resultsv += New-Object PSObject -Property $Propsv
}
@{Object = $Resultsv | Select-Object Vm,Key,Value } | Export-HtmlReport -OutputFile $outputhostHTML | Invoke-Item



