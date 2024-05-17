<# ОПИСАНИЕ СКРИПТА
Начальная настройка демо-стенда на базе Hyper-V
Версия 1.0
Настройка контролера домена
Danil Stepanov (c) 2022
#>

# ОБЪЯВЛЕНИЕ ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ **************************************************
$CSV_Path = "D:\Hyper-V\Template\PowerShell\DemoStand.csv"
$localDomain = "ms-ware.ru"
$NETBIOS = "MS-WARE"

$localADM = "Administrator"
$LocalADMPas = 'P@$$w0rd'

$global:VM_Name = ""
$global:VM_IP = ""
$global:VM_FQDN = ""

$Password = ConvertTo-SecureString $LocalADMPas -AsPlainText -Force

$global:cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $localADM,$Password


function SetConfigDC {

    $VM = $global:VM_Name

    $IP = $global:VM_IP

    $DNS = "127.0.0.1"

    Invoke-Command -VMName $VM -Credential $global:cred -ScriptBlock { Rename-Computer -NewName $Using:VM }

    Invoke-Command -VMName $VM -Credential $global:cred -ScriptBlock { Set-TimeZone -Id "Russian Standard Time" -PassThru }

    Invoke-Command -VMName $VM -Credential $global:cred -ScriptBlock { New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $Using:IP -AddressFamily IPv4 -PrefixLength 24 } 

    Invoke-Command -VMName $VM -Credential $global:cred -ScriptBlock { Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $Using:DNS }

    Invoke-Command -VMName $VM -Credential $global:cred -ScriptBlock { Restart-Computer -Force }
}


function InstallDC {

    $VM = $global:VM_Name

    Invoke-Command -VMName $VM -Credential $global:cred -ScriptBlock { Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools }

    Invoke-Command -VMName $VM -Credential $global:cred -ScriptBlock { Import-Module ADDSDeployment } 

    Invoke-Command -VMName $VM -Credential $global:cred -ScriptBlock {  Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName $Using:localDomain `
    -DomainNetbiosName $Using:NETBIOS `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true `
    -SafeModeAdministratorPassword (Convertto-SecureString -AsPlainText "P@$$w0rd" -Force) }
}


function StartScript {

    $arrayVMs = Import-Csv $CSV_Path –Delimiter “;”

    foreach ($VM in $arrayVMs){
        if ($VM.Role -eq "DC") {
            $global:VM_Name = $VM.VM
            $global:VM_IP = $VM.IP
            $global:VM_FQDN = $VM.FQDN
        }
    }

    SetConfigDC

    Start-Sleep -s 90

    InstallDC
}

StartScript