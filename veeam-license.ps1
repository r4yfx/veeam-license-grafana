<#
        .SYNOPSIS
        Veeam License Checker
  
        .DESCRIPTION
        This will check the license and virtual machines.  It will then convert them into JSON, ready to add into InfluxDB and show it with Grafana
	
        .Notes
        NAME:  veeam-license.ps1
        LASTEDIT: 24/01/2019
        VERSION: 0.1
        KEYWORDS: Veeam, License, Grafana, InfluxDB
   
        .Link
        https://github.com/r4yfx
 
 #Requires PS -Version 3.0
 #Requires -Modules VeeamPSSnapIn    
 #>

#### Enable Veeam CMDLet ####
asnp veeampssnapin

#### Variables ####
# Defining the expiration pattern (found here: https://ict-freak.nl/2011/12/29/powershell-veeam-br-get-total-days-before-the-license-expires/)
$pattern_date = "Expiration date\=\d{1,2}\/\d{1,2}\/\d{1,4}"
$pattern_count = "Instances\=\d{1,4}"

#### Body ####
# We obtain the license information consulting it's registry key.
# Getting registry key information.
$regkey_veeam = (Get-Item 'HKLM:\SOFTWARE\VeeaM\Veeam Backup and Replication\license').GetValue('Lic1')
# Converting registry key into human readable content.
$lic_veeam = [string]::Join($null, ($regkey_veeam | ForEach-Object { [char][int]$_;}))

# Extracting the expiration date using the previously defined $pattern_date.
$expdate_veeam = [regex]::matches($lic_veeam,$pattern_date)[0].Value.Split("=")[1]
# Extracting the instance amount from license using previously defined $pattern_count.
$instcount_veeam = [regex]::matches($lic_veeam,$pattern_count)[0].Value.Split("=")[1]

#Get the VM Count
$count_veeam = $JobList = Get-VBRJob
$out = @()
foreach($Jobobject in $JobList)
{$Objects = $JobObject.GetObjectsInJob()
$out += $Objects.name
}
# Getting the days until today.
$licdays_veeam = [int](((Get-Date $expdate_veeam) - (Get-Date)).TotalDays.toString().split(",")[0])
#Getting VM Count Left on License (Percentage)
$liccount_veeam = ($out.count) / ($instcount_veeam) * 100


# Generating monitoring output.
# JSON Output for Telegraf
Write-Host "{"
Write-Host "`"Days-Remaining`"": "$licdays_veeam,"
Write-Host "`"VM-License-Used`"": "$liccount_veeam"
Write-Host "}" 
