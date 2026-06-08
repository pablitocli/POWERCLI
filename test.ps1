			$sql=0
			$apl=0
			$web=0
			$exc=0
			$dat=0
			$otro=0
			$lab=0
			
			
			$vms= get-cluster pvbuetmdes01| get-vm
			
			
			$c_vms=$vms.count
			
	foreach ($vm in $vms)
			{
			$v= get-vm $vm
			if ($v.name -like "*sql*")
			{$sql=$sql + 1}
			elseif($v.name -like "*apl*") 
			{$apl=$apl + 1}
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
			$c_apl= ($apl / $c_vms ) * 100
			$c_web= ($web / $c_vms ) * 100
			$c_dat= ($dat / $c_vms ) * 100
 			$c_exc= ($exc / $c_vms ) * 100
			$c_otro= ($otro / $c_vms ) * 100
			$c_lab= ($lab / $c_vms ) * 100
			
			WRITE-host $c_apl
			WRITE-host $c_sql
			WRITE-host $c_web
			WRITE-host $c_dat
			WRITE-host $c_exc
			WRITE-host $c_lab
			WRITE-host $c_otro