<# ОПИСАНИЕ СКРИПТА
Начальная настройка демо-стенда на базе Hyper-V
Версия 1.0
Настройка серверов
Danil Stepanov (c) 2022
#>

# ОБЪЯВЛЕНИЕ ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ **************************************************
$CSV_Path = "D:\Hyper-V\Template\PowerShell\DemoStand.csv"
$global:localDomain = "ms-ware.ru"
$global:NETBIOS = "ms-ware"

$localADM = "Administrator"
$LocalADMPas = 'P@$$w0rd'

$DomainADM = $global:NETBIOS + "\" +"Administrator"
$DomainADMPas = 'P@$$w0rd'

$global:VM_Name = ""
$global:VM_IP = ""
$global:VM_FQDN = ""
$global:DNS_DC = ""

$PasswordLocal = ConvertTo-SecureString $LocalADMPas -AsPlainText -Force

$PasswordDomain = ConvertTo-SecureString $DomainADMPas -AsPlainText -Force

$global:credLocal = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $localADM,$PasswordLocal

$global:credDomain = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DomainADM,$PasswordDomain


function SetConfigClient () {

    $VM = $global:VM_Name
    
    $FQDN = $global:VM_FQDN

    $IP = $global:VM_IP

    $DNS = $global:DNS_DC

    $lDomain = $global:localDomain


    Invoke-Command -VMName $VM -Credential $global:credLocal -ScriptBlock { Rename-Computer -NewName $Using:FQDN }

    Invoke-Command -VMName $VM -Credential $global:credLocal -ScriptBlock { Set-TimeZone -Id "Russian Standard Time" -PassThru }

    Invoke-Command -VMName $VM -Credential $global:credLocal -ScriptBlock { New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $Using:IP -AddressFamily IPv4 -PrefixLength 24 } 

    Invoke-Command -VMName $VM -Credential $global:credLocal -ScriptBlock { Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $Using:DNS }

    Invoke-Command -VMName $VM -Credential $global:credLocal -ScriptBlock { Restart-Computer -Force }
}

function JoinDomain {

    $VM = $global:VM_Name
    $FQDN = $global:VM_FQDN
    $lDomain = $global:localDomain

    $Credential = $global:credDomain

    Invoke-Command -VMName $VM -Credential $global:credLocal -ScriptBlock { Add-Computer -DomainName $Using:lDomain -Credential $Using:Credential -Restart -Force }
}


function StartScript {

    $arrayVMs = Import-Csv $CSV_Path –Delimiter ";"

    foreach ($VM in $arrayVMs){
        if ($VM.Role -eq "DC") {
            $global:DNS_DC = $VM.IP
        }
    }

    foreach ($VM in $arrayVMs){
        if (($VM.Role -eq "client") -and ($VM.Add -eq "True")) {
            $global:VM_Name = $VM.VM
            $global:VM_FQDN = $VM.FQDN
            $global:VM_IP = $VM.IP
            SetConfigClient
        }
    }

    Start-Sleep -s 90

    foreach ($VM in $arrayVMs){
        if (($VM.Role -eq "client") -and ($VM.Join -eq "domain") -and ($VM.Add -eq "True")) {
            $global:VM_Name = $VM.VM
            $global:VM_FQDN = $VM.FQDN
            $global:VM_IP = $VM.IP
            JoinDomain
        }
    } 
}

StartScript