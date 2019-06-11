$testcomputers = Get-Content -Path 'C:\Temp\scripts\computers.txt'
$exportLocation = 'C:\Temp\scripts\remoteinventory.csv'
 
foreach ($computer in $testcomputers) {
  if (Test-Connection -ComputerName $computer -Quiet -count 2){
    Add-Content -value $computer -path c:\Temp\scripts\livePCs.txt
  }else{
    Add-Content -value $computer -path c:\Temp\scripts\deadPCs.txt
  }
}

$computers = Get-Content -Path 'C:\Temp\scripts\livePCs.txt'
 
foreach ($computer in $computers) {
    $Bios = Get-WmiObject win32_bios -Computername $Computer
    $Hardware = Get-WmiObject Win32_computerSystem -Computername $Computer
    $Sysbuild = Get-WmiObject Win32_WmiSetting -Computername $Computer
    $OS = Get-WmiObject Win32_OperatingSystem -Computername $Computer
    $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer | Where-Object {$_.IPEnabled}

    $diskC = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter "DeviceID='C:'" | Foreach-Object {$_.Size/1GB}
    $driveSpaceC = Get-WmiObject win32_volume -computername $Computer -Filter 'drivetype = 3' | 
    Select-Object PScomputerName, driveletter, label, @{LABEL='GBfreespace';EXPRESSION={'{0:N2}' -f($_.freespace/1GB)} } |
    Where-Object { $_.driveletter -match 'C:' }

    $diskE = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter "DeviceID='E:'" | Foreach-Object {$_.Size/1GB}
    $driveSpaceE = Get-WmiObject win32_volume -computername $Computer -Filter 'drivetype = 3' |
    Select-Object PScomputerName, driveletter, label, @{LABEL='GBfreespace';EXPRESSION={'{0:N2}' -f($_.freespace/1GB)} } |
    Where-Object { $_.driveletter -match 'E:' }

    $diskF = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter "DeviceID='F:'" | Foreach-Object {$_.Size/1GB}
    $driveSpaceF = Get-WmiObject win32_volume -computername $Computer -Filter 'drivetype = 3' |
    Select-Object PScomputerName, driveletter, label, @{LABEL='GBfreespace';EXPRESSION={'{0:N2}' -f($_.freespace/1GB)} } |
    Where-Object { $_.driveletter -match 'F:' }

    $cpu = Get-WmiObject Win32_Processor  -computername $computer
    $username = Get-ChildItem "\\$computer\c$\Users" | Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime -first 1
    $totalMemory = [math]::round($Hardware.TotalPhysicalMemory/1024/1024/1024, 2) 
 
    $IPAddress  = $Networks.IpAddress[0]
    $MACAddress  = $Networks.MACAddress
    $systemBios = $Bios.serialnumber
 
    $OutputObj  = New-Object -Type PSObject
    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()
    $OutputObj | Add-Member -MemberType NoteProperty -Name IP_Address -Value $IPAddress
    $OutputObj | Add-Member -MemberType NoteProperty -Name System_Type -Value $Hardware.SystemType
    $OutputObj | Add-Member -MemberType NoteProperty -Name Operating_System -Value $OS.Caption
    $OutputObj | Add-Member -MemberType NoteProperty -Name C:_TotalSpace_GB -Value $diskC
    $OutputObj | Add-Member -MemberType NoteProperty -Name C:_FreeSpace_GB -Value $driveSpaceC.GBfreespace
    $OutputObj | Add-Member -MemberType NoteProperty -Name E:_TotalSpace_GB -Value $diskE
    $OutputObj | Add-Member -MemberType NoteProperty -Name E:_FreeSpace_GB -Value $driveSpaceE.GBfreespace
    $OutputObj | Add-Member -MemberType NoteProperty -Name F:_TotalSpace_GB -Value $diskF
    $OutputObj | Add-Member -MemberType NoteProperty -Name F:_FreeSpace_GB -Value $driveSpaceF.GBfreespace
    $OutputObj | Add-Member -MemberType NoteProperty -Name Total_Memory_GB -Value $totalMemory
    $OutputObj | Export-Csv $exportLocation -Append -Force -NoTypeInformation
  }
