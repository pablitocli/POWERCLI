 #####################################  
 ## http://kunaludapi.blogspot.com  
 ## Version: 1  
 ## Tested this script on  
 ##  1) Powershell v3  
 ##  2) Powercli v5.5  
 ##  3) Vsphere 5.x  
 #####################################  
 


#Requires -Version 2.0
Set-StrictMode -Version Latest

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
. .\bin\include\Export-HtmlReport.ps1


Write-Host "BUSQUEDA DE VMS APAGADAS Y VOLUMEN OCIOSO" -backgroundcolor "blue"
connect-viserver ssbuetyvmw01 -alllinked 
 Add-PSSnapin VMware.VimAutomation.core  
 Add-PSSnapin VMware.VimAutomation.Vds  
   
 $vCenterCred = Get-Credential -Message "vCenter server or esxi credentials"  
 $vcenterServer = "ssbuetyvmw01"  
   
 Connect-viServer -server $vcenterServer -Credential $vCenterCred -alllinked
   
 $Collection = @()  
   
 $Esxihosts = get-datacenter -name *dmzi | Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"}  
 foreach ($Esxihost in $Esxihosts) {  
   $Esxcli = Get-EsxCli -VMHost $Esxihost  
   $Esxihostview = Get-VMHost $EsxiHost | get-view  
   $NetworkSystem = $Esxihostview.Configmanager.Networksystem  
   $Networkview = Get-View $NetworkSystem  
       
   $DvSwitchInfo = Get-VDSwitch -VMHost $Esxihost  
   if ($DvSwitchInfo -ne $null) {  
     $DvSwitchHost = $DvSwitchInfo.ExtensionData.Config.Host  
     $DvSwitchHostView = Get-View $DvSwitchHost.config.host  
     $VMhostnic = $DvSwitchHostView.config.network.pnic  
     $DVNic = $DvSwitchHost.config.backing.PnicSpec.PnicDevice  
   }  
     
   $VMnics = $Esxihost | get-vmhostnetworkadapter -Physical   #$_.NetworkInfo.Pnic  
   Foreach ($VMnic in $VMnics){  
       $realInfo = $Networkview.QueryNetworkHint($VMnic)  
       $pNics = $esxcli.network.nic.list() | where-object {$vmnic.name -eq $_.name} | Select-Object Description, Link           
       $Description = $esxcli.network.nic.list()  
       $CDPextended = $realInfo.connectedswitchport  
         if ($vmnic.Name -eq $DVNic) {  
             
           $vSwitch = $DVswitchInfo | where-object {$vmnic.Name -eq $DVNic} | select-object -ExpandProperty Name  
         }  
         else {  
           $vSwitchname = $Esxihost | Get-VirtualSwitch | Where-object {$_.nic -eq $VMnic.DeviceName}  
           $vSwitch = $vSwitchname.name  
         }  
   $CDPdetails = New-Object PSObject  
   $CDPdetails | Add-Member -Name EsxName -Value $esxihost.Name -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name VMNic -Value $VMnic -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name vSwitch -Value $vSwitch -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name Link -Value $pNics.Link -MemberType NoteProperty   
   $CDPdetails | Add-Member -Name PortNo -Value $CDPextended.PortId -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name Device-ID -Value $CDPextended.devID -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name Switch-IP -Value $CDPextended.Address -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name MacAddress -Value $vmnic.Mac -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name SpeedMB -Value $vmnic.ExtensionData.LinkSpeed.SpeedMB -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name Duplex -Value $vmnic.ExtensionData.LinkSpeed.Duplex -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name Pnic-Vendor -Value $pNics.Description -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name Pnic-drivers -Value $vmnic.ExtensionData.Driver -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name PCI-Slot -Value $vmnic.ExtensionData.Pci -MemberType NoteProperty  
   $collection += $CDPdetails  
   }  
 }  
  
$InputObject =  @{
				   Title  = "BUSQUEDA DE VMS APAGADAS Y VOLUMEN OCIOSO - SISTEMA OPERATIVO UNIX";
				   Object = $Collection 
				   }
				
				
		Export-HtmlReport -OutputFile $outputhostHTML
		$outputhostHTML | Invoke-Item
  
 
   
 Disconnect-VIserver * -confirm:$false  