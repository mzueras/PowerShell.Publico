# Get Windows product key from BIOS
function Get-BiosProductKey {
    $key = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
    return $key
}

# Check activation status and KMS activation
function Get-ActivationStatus {
    $slmgr = cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /dli
    $output = $slmgr | Out-String
    $isKMS = $output -match "KMS"
    $isLicensed = $output -match "Estado de la licencia:\con*licencia"
    return @{ IsKMS = $isKMS; IsLicensed = $isLicensed; Output = $output }
}

# Reset activation and set BIOS key if KMS activated
function Reset-Activation-IfKMS {
    $status = Get-ActivationStatus
    if ($status.IsKMS) {
        Write-Host "KMS activation detected. Resetting activation and applying BIOS key..."
        # Uninstall current product key
        cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /upk
        Start-Sleep -Seconds 2
        Write-Host "KMS activation detected. Clear the KMS Server Information..."
        cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /ckms
        Start-Sleep -Seconds 2

        # Install BIOS product key
        $biosKey = Get-BiosProductKey
        if ($biosKey) {
            cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /ipk $biosKey
            Start-Sleep -Seconds 2
            # Activate Windows
            cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /ato
            Write-Host "BIOS product key applied and activation attempted."
        } else {
            Write-Host "No BIOS product key found."
        }
    } else {
        Write-Host "KMS activation not detected. No action taken."
    }
}

# Main
Reset-Activation-IfKMS
