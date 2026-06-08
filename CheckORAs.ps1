add-pssnapin VMware.VimAutomation.Core
#Requires -Version 2.0
Set-StrictMode -Version Latest
connect-viserver SSBUETYVMW01 -alllinked -user ypf\ys00837 -password VcoPS3011
$fecha= get-date -format "ddMMyyyy"
# A simple example for the usage of Export-HtmlReport:
#
# A report is generated from a single PowerShell object
###################################SALIDA DE DATOS#####################################

##CSV DE SALIDA
$outputstore = "D:\inventario\$fecha\host\VCPU-ORACLE.csv"


###############################################################################################
get-vm -name *suarbu*ora* | select name, numcpu > $outputstore 
################################################################################
		
xcopy $outputstore \\stbuetmadm07\share\ /y

	