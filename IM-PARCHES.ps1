	$vmhosts= Get-vmhost 
	foreach ($vmhost in $vmhosts){
		#####################APERTUDA DE INCIDENTE######################################
		Write-Host "#####################"$VMHOST.name "######################################"
		$nodo=get-vmhost $vmhost
		$grupo="ADMIN-CLOUD-YPF"
			$titulo="Instalacion de parches para el nodo $nodo.name"
			$des="Dicho nodo pose 36 parches pendientes"
						
			& 'D:\Scripts\PortalV2\bin\PosteINCGUIV2.exe' $titulo $des $grupo
				
		################################################################################
		}