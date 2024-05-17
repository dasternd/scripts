<# ОПИСАНИЕ СКРИПТА
Очистка системного диска
Версия 1.00

Удаляет все файлы из временного каталога Temp, очищает каталог скаченных обновлений,
а так же удалет файлы по маске в профилях пользовтелей на локальном ПК

Danil Stepanov (c) 2019
#>

# ОПИСАНИЕ ПЕРЕМЕННЫХ
$minDiskSpaceGb = 20                                                                    # минимальное значение свободного дискового пространства в ГБ
$WinTempFolder = "$env:SystemDrive\Windows\Temp\"                                       # системная временная папка
$DowloadeUpdateFolder="$env:SystemDrive\Windows\SoftwareDistribution\Download\"         # системный каталог для хранения скаченных обновлений системы -  Windows Update
$TypeFiles = "*.iso", "*.mp3", "*.avi", "*.mp4"                                         # массив с типами файлов для удаления
# массив из списка путей профилей
$UserProfilesPath = Get-ChildItem 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\ProfileList' | Where-Object {$_.GetValue('ProfileImagePath') -like "*users*"} | ForEach-Object {$_.GetValue('ProfileImagePath')}

Main

function Main {   
    if (FreeDiskSpace) {
        exit
    }
    else {
        ClearTempFolders
        ClearUserProfiles
        exit
    }       
}

<# ФУНКЦИЯ 
определения удовлетворения условиям свободного дискового пространства
если условие удовлетворяет минимальному дисковому пространству возвращается значение $true
иначе $false
#>
function FreeDiskSpace {
   $freeDiskSpace = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | select Name, FileSystem,FreeSpace,BlockSize,Size | % {$_.BlockSize=(($_.FreeSpace)/($_.Size))*100;$_.FreeSpace=($_.FreeSpace/1GB);$_.Size=($_.Size/1GB);$_}

    if ([int]$freeDiskSpaceю.FreeSpace -gt $minDiskSpaceGb)     #если текущее дисковое пространство больше необходимого минимума
    {
        return $true    
    }
    else
    {
        return $false
    }
}

<# ФУНКЦИЯ 
очистка содержимого в необходимых каталогах
#>
function ClearTempFolders {
    Remove-Item $WinTempFolder\* -Recurse -Force                   # удаление всех файлов и вложенных каталогов с \Windows\Temp
    Remove-Item $DowloadeUpdateFolder\* -Recurse -Force            # удаление всех файлов и вложенных каталогов с \Windows\SoftwareDistribution\Download\
    Clear-RecycleBin -Confirm:$false                               # очистка корзины

    foreach ($usrProfile in $UserProfilesPath) {                   # удаление всех файлов из временного каталога в каждом локальном профиле
        Remove-Item $usrProfile\AppData\Local\Temp\* -Recurse -Force
    }
}

# Запуск удалени файлов по маске
function ClearUserProfiles {
    foreach ($typeFile in $TypeFiles) {                                                         # переберается тип файлов и затем
        foreach ($usrProfile in $UserProfilesPath) {                                            # перебирается путь к профилю пользователя
                Get-ChildItem -Path $usrProfile $typeFile -Recurse | Remove-Item -Recurse      # удаляются все файлы по маске в профиле пользователя
            }
    }
}