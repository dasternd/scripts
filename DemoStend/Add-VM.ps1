<# ОПИСАНИЕ СКРИПТА
Начальная настройка демо-стенда на базе Hyper-V
Версия 1.0
Создания виртуальных машин из CSV-файла
Danil Stepanov (c) 2022
#>

# ОБЪЯВЛЕНИЕ ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ **************************************************
# каталог с размещением ВМ
$HV_Path = "D:\Hyper-V\"

# каталог с размещением эталонных дисков с ОС
$HV_Path_Template = "D:\Hyper-V\Template\"

# $localDomain = "demo.daste.ru"
$CSV_Path = "D:\Hyper-V\Template\PowerShell\DemoStand.csv"

function createVM($VM) {
    $VM_Name = $VM.VM
    $VM_RAM_Start = [int64]$VM.RAMStart.Replace('MB','') * 1MB
    $VM_RAM_Min = [int64]$VM.RAMMin.Replace('MB','') * 1MB
    $VM_RAM_Max = [int64]$VM.RAMMax.Replace('MB','') * 1MB
    $VM_CPU = $VM.CPU
    $VM_Path = $HV_Path + $VM_Name + "\"
    switch ($VM.OS) {
        # типы ОС
        "WS16" { $VM_Disk_Parent = $HV_Path_Template + "WS16.vhdx" }    # w2k16 - Windows Server 2016 Standard
        "WS19" { $VM_Disk_Parent = $HV_Path_Template + "WS19.vhdx" }    # w2k19 - Windows Server 2019 Standard
        "WS22" { $VM_Disk_Parent = $HV_Path_Template + "WS22.vhdx" }    # w2k22 - Windows Server 2022 Standard
        "WS22c" { $VM_Disk_Parent = $HV_Path_Template + "WS22c.vhdx" }  # w2k22 - Windows Server 2022 Standard Core
        "WS25" { $VM_Disk_Parent = $HV_Path_Template + "WS25.vhdx" }    # w2k25 - Windows Server 2022 Standard
        "WS25c" { $VM_Disk_Parent = $HV_Path_Template + "WS25c.vhdx" }  # w2k25 - Windows Server 2022 Standard Core
        "w7" { $VM_Disk_Parent = $HV_Path_Template + "w7.vhdx" }        # w7 - Windows 7 Pro
        "w7e" { $VM_Disk_Parent = $HV_Path_Template + "w7e.vhdx" }      # w7e - Windows 7 Enterprise
        "w10" { $VM_Disk_Parent = $HV_Path_Template + "w10.vhdx" }      # w10 - Windows 10 Pro
        "w10e" { $VM_Disk_Parent = $HV_Path_Template + "w10e.vhdx" }    # w10e - Windows 10 Enterprise
        "w11" { $VM_Disk_Parent = $HV_Path_Template + "w11.vhdx" }      # w11 - Windows 11 Pro
        "w11e" { $VM_Disk_Parent = $HV_Path_Template + "w11e.vhdx" }    # w11e - Windows 11 Enterprise

        Default { $VM_Disk_Parent = $HV_Path_Template + "WS22.vhdx" }
    }
    
    $VM_Disk = $VM_Path + $VM_Name + ".vhdx"
    switch ($VM.Switch) {
        "vPrivate" { $VM_Switch = "vPrivate" }
        "vExternal" { $VM_Switch = "vExternal" }
        Default { $VM_Switch = "vPrivate" }
    }

    New-VM -Name $VM_Name -path $VM_Path -MemoryStartupBytes $VM_RAM_Start -Generation 2 -Switch $VM_Switch

    New-VHD -ParentPath $VM_Disk_Parent -Path $VM_Disk -Differencing
    Add-VMHardDiskDrive -VMName $VM_Name -path $VM_Disk

    Set-VM -Name $VM_Name -MemoryMinimumBytes $VM_RAM_Min -MemoryMaximumBytes $VM_RAM_Max -ProcessorCount $VM_CPU -CheckpointType Disabled

    $VM_DiskBoot = Get-VMFirmware $VM_Name
    Set-VMFirmware $VM_Name -BootOrder $VM_DiskBoot.BootOrder[1]

    Start-VM $VM_Name
}

function createVMs {
    $arrayVMs = Import-Csv $CSV_Path –Delimiter “;”

    foreach ($VM in $arrayVMs){
        if ($VM.Add -eq "True") {
            createVM($VM)
        }
    }
}

function StartScript {
    createVMs
}

StartScript