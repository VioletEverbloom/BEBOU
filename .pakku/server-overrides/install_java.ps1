# Copyright (C) 2025 Griefed
#
# This script was modified by VioletEverbloom. You can find a link to the source and the script's licence in docs/CREDITS.md 


Function Global:RunJavaInstallation {
    $ExternalVariablesFile = -join ("${BaseDir}", "\_variables.txt");

    if (!(Test-Path -Path $ExternalVariablesFile -PathType Leaf)) {
        "ERROR! _variables.txt not present. Without it the server can not be installed, configured or started."
        exit 1
    }

    $ExternalVariables = Get-Content -raw -LiteralPath $ExternalVariablesFile | ConvertFrom-StringData
    $RecommendedJavaVersion = $ExternalVariables['RECOMMENDED_JAVA_VERSION']
    $JabbaInstallURL = $ExternalVariables['JABBA_INSTALL_URL_PS']
    $JDKVendor = $ExternalVariables['JDK_VENDOR']
    $Java = $ExternalVariables['JAVA']
    $Env:JABBA_VERSION = $ExternalVariables['JABBA_VERSION']

    if (!(Test-Path -Path $home\.jabba\jabba.ps1 -PathType Leaf)) {
        Write-Host "Automated Java installation requires a piece of Software called 'Jabba'."
        Write-Host "Type 'I agree' if you agree to the installation of the aforementioned software."
        $Answer = Read-Host -Prompt 'Answer'
        if (${Answer} -eq "I agree") {
            Write-Host "Downloading and installing jabba."
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-Expression (
                Invoke-WebRequest "${JabbaInstallURL}" -UseBasicParsing
            ).Content
        }
        else {
            Write-Host "User did not agree to Jabba installation. Aborting Java installation process."
            exit 1
        }
    }

    . $home\.jabba\jabba.ps1

    Write-Host "Downloading and using Java ${JDKVendor}@${RecommendedJavaVersion}"
    jabba install "${JDKVendor}@${RecommendedJavaVersion}"
    jabba use "${JDKVendor}@${RecommendedJavaVersion}"

    CMD /C ${Java} -version WARUM IST POWERSHELL SO EIN HAUFEN STINKENDE SCHEIßE

    Write-Host "Installation finished. Returning to start-script."

    <#
    .SYNOPSIS

    Download and install Java with the version required by the Minecraft server.

    .DESCRIPTION

    Download and install Java with the version required by the Minecraft version set in the _variables.txt which was
    also shipped with this modpack. Should you want to use a different Java version with your server pack, change
    the RECOMMENDED_JAVA_VERSION. Likewise, you can change the vendor of the JDK to another one by changing
    JDK_VENDOR in your _variables.txt

    Depending on which Minecraft version is used in this server pack, a different Java version may be installed.

    ATTENTION:
       This script will NOT modify the JAVA_HOME variable for your user.

    A list of available JDK versions and vendors can be found at https://github.com/Jabba-Team/index/blob/main/index.json
    Jabba is available at https://github.com/Jabba-Team/jabba
#>
}