# Copyright (C) 2025 Griefed
#
# This script was modified by VioletEverbloom. You can find a link to the source and the script's licence in docs/CREDITS.md 


Function PauseScript {
    Write-Host "Press any key to continue" -ForegroundColor Yellow
    $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown") > $null

    <#
    .SYNOPSIS

    Pause script execution. User input in the form of any keyboard key-press is required to continue execution.
#>
}

Function CrashServer {
    param ($Message)
    Write-Host "${Message}"
    PauseScript
    exit 1

    <#
    .SYNOPSIS

    Crash script execution with exit code 1. Print $1 to the console.

    .PARAMETER Message
    The message to print to console before force-stopping script execution.
    #>
}

Function CommandAvailable {
    param ($CmdName)
    return [bool](Get-Command -Name $CmdName -ErrorAction SilentlyContinue)

    <#
    .SYNOPSIS

    Check whether the command is available for execution. Can be used in if-statements.

    .PARAMETER CmdName
    The command to check for availability.
    #>
}

Function GetJavaVersion() {
    $JavaFullversion = CMD /C "`"${Java}`" -fullversion 2>&1"
    $JavaFullversion = $JavaFullversion.Substring($JavaFullversion.IndexOf('"') + 1).TrimEnd('"').Split('.')
    $script:JavaVersion = $JavaFullversion[0]

    if ([int]$JavaFullversion[0] -eq 1) {
        $script:JavaVersion = $JavaFullversion[1]
    }

    <#
    .SYNOPSIS

    Set $script:JavaVersion by checking $Java using -fullversion. Only the major version is stored, e.g. 8, 11, 17, 21.
    #>
}

Function InstallJava() {
    Write-Host "No suitable Java installation was found on your system. Proceeding to Java installation."
    . .\install_java.ps1
    RunJavaInstallation
    if (!(CommandAvailable -cmdname "${Java}")) {
        CrashServer "Java installation failed. Couldn't find ${Java}."
    }

    <#
    .SYNOPSIS

    Sources the companion-script "install_java.ps1" and runs the contained function "Global:RunJavaInstallation" to install
    the required Java version for this modded Minecraft server.
    #>
}

Function DeleteFileSilently {
    param ($FileToDelete)
    $ErrorActionPreference = "SilentlyContinue";
    if ((Get-Item "${FileToDelete}").PSIsContainer) {
        Remove-Item "${FileToDelete}" -Recurse
    }
    else {
        Remove-Item "${FileToDelete}"
    }
    $ErrorActionPreference = "Continue";

    <#
    .SYNOPSIS

    Quietly / silently delete the specified file from the filesystem. If a folder is specified, then the entire
    folder is deleted recursively.

    .PARAMETER FileToDelete
    The file or folder to delete silently, without printing messages or errors to console.
    #>
}

Function WriteFileUTF8NoBom {
    param ($FilePath, $Content)
    $AbsolutePath = Join-Path -Path "$BaseDir" -ChildPath "$FilePath"
    New-Item $AbsolutePath -type file
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [IO.File]::WriteAllLines(($FilePath | Resolve-Path), $Content, $Utf8NoBomEncoding)

    <#
    .SYNOPSIS

    Write a text-file using UTF-8, but without a BOM. No-BOM UTF-8 files are required by the ServerStarterJar
    from the NeoForge-project for installing and running NeoForge servers, whilst using "user_jvm_args.txt".

    .PARAMETER FilePath
    The path to the file which should be writte. The file is created by this function, so no need to create it yourself.
    The path must be relative to the script. The function will take care of writing it in the base of the scripts
    working-directory.

    .PARAMETER Content
    The content to print to the file.
    #>
}

Function global:RunJavaCommand {
    param ($CommandToRun)
    CMD /C "`"${Java}`" ${CommandToRun}"

    <#
    .SYNOPSIS

    Runs the passed string as a Java command with the Java installation set in $Java.

    .PARAMETER CommandToRun
    The command to run as a Java command.
    #>
}

Function DownloadIfNotExists {
    param ($FileToCheck, $FileToDownload, $DownloadURL)
    if (!(Test-Path -Path $FileToCheck -PathType Leaf)) {
        Write-Host "${FileToCheck} could not be found."
        Write-Host "Downloading ${FileToDownload}"
        Write-Host "from ${DownloadURL}"
        Invoke-WebRequest -URI "${DownloadURL}" -OutFile "${FileToDownload}"
        if (Test-Path -Path "${FileToDownload}" -PathType Leaf) {
            Write-Host "Download complete."
            return $true
        }
        else {
            return $false
        }
    }
    else {
        Write-Host "${FileToCheck} present."
        return $false
    }

    <#
    .SYNOPSIS

    Checks whether $FileToCheck exists. If not, then it is downloaded from $DownloadURL and stored as $FileToDownload.
    Can be used in if-statements.

    .PARAMETER FileToCheck
    The file to check for existence.

    .PARAMETER FileToDownload
    The filename to which store the download as.

    .PARAMETER DownloadURL
    The URL from which to download the file from.

    .OUTPUTS

    Boolean. $true if the file was downloaded and exists, $false otherwise.
    #>
}

Function global:RefreshServerJar {
    if ("${ServerStarterJarForceFetch}" -eq "true") {
        DeleteFileSilently  'server.jar'
    }

    $ServerStarterJarDownloadURL = ""
    if ("${ServerStarterJarVersion}" -eq "latest") {
        $ServerStarterJarDownloadURL = "https://github.com/neoforged/ServerStarterJar/releases/latest/download/server.jar"
    }
    else {
        $ServerStarterJarDownloadURL = "https://github.com/neoforged/ServerStarterJar/releases/download/${ServerStarterJarVersion}/server.jar"
    }

    DownloadIfNotExists "server.jar" "server.jar" "${ServerStarterJarDownloadURL}"

    <#
    .SYNOPSIS

    Refresh the ServerStarterJar used for running NeoForge servers.
    Depending on the value of SERVERSTARTERJAR_FORCE_FETCH in the variables.txt the server.jar is force-refreshed.
    Meaning: If true, the server.jar will be deleted and then downloaded again.
    Depending on the value of SERVERSTARTERJAR_VERSION in the variables.txt a different version is fetched. More on
    this value in the variables.txt
    #>
}

Function global:CleanServerFiles {
    $ErrorActionPreference = "SilentlyContinue";
    ForEach ($FileToRemove in $Cleanup) {
        $ToRemove = -join ($BaseDir.Trim('"'), "\" , ${FileToRemove}.Trim('"'));
        Remove-Item -Path "${ToRemove}" -Recurse -Force -Verbose -ErrorAction SilentlyContinue
    }
    $ErrorActionPreference = "Continue";

    <#
    .SYNOPSIS

    Clean up files created by installers or modloader servers, but leave server pack files untouched.
    Allows changing and re-installing the modloader, Minecraft and modloader versions.
    #>
}

# If modloader = NeoForge, run NeoForge-specific checks
Function global:SetupNeoForge {
    ""
    "Running NeoForge checks and setup..."
    Write-Host "Generating user_jvm_args.txt from variables..."
    Write-Host "Edit JAVA_ARGS in your variables.txt. Do not edit user_jvm_args.txt directly!"
    Write-Host "Manually made changes to user_jvm_args.txt will be lost in the nether!"
    DeleteFileSilently  'user_jvm_args.txt'
    $Content = "# Xmx and Xms set the maximum and minimum RAM usage, respectively.`n" +
    "# They can take any number, followed by an M or a G.`n" +
    "# M means Megabyte, G means Gigabyte.`n" +
    "# For example, to set the maximum to 3GB: -Xmx3G`n" +
    "# To set the minimum to 2.5GB: -Xms2500M`n" +
    "# A good default for a modded server is 4GB.`n" +
    "# Uncomment the next line to set it.`n" +
    "# -Xmx4G`n" +
    "${script:JavaArgs}"
    WriteFileUTF8NoBom "user_jvm_args.txt" $Content

    $script:ServerRunCommand = "@user_jvm_args.txt -jar server.jar --installer-force --installer ${ModLoaderVersion} nogui"

    RefreshServerJar

    <#
    .SYNOPSIS

    Download and install a NeoForge server for $ModLoaderVersion. The ServerStarterJar from the NeoForge-group is used.
    This has the benefit of making this server pack compatible with most hosting-companies.
    #>
}

Function global:SetupFabric {
    ""
    "Running Fabric checks and setup..."
    $FabricInstallerUrl = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/${FabricInstallerVersion}/fabric-installer-${FabricInstallerVersion}.jar"
    $ImprovedFabricLauncherUrl = "https://meta.fabricmc.net/v2/versions/loader/${MinecraftVersion}/${ModLoaderVersion}/${FabricInstallerVersion}/server/jar"
    $ErrorActionPreference = "SilentlyContinue";
    $script:ImprovedFabricLauncherAvailable = [int][System.Net.WebRequest]::Create("${ImprovedFabricLauncherUrl}").GetResponse().StatusCode
    $ErrorActionPreference = "Continue";
    if ("${ImprovedFabricLauncherAvailable}" -eq "200") {
        "Improved Fabric Server Launcher available..."
        "The improved launcher will be used to run this Fabric server."
        $script:LauncherJarLocation = "fabric-server-launcher.jar"
        (DownloadIfNotExists "${script:LauncherJarLocation}" "${script:LauncherJarLocation}" "${ImprovedFabricLauncherUrl}") > $null
    }
    else {
        try {
            $ErrorActionPreference = "SilentlyContinue";
            $FabricAvailable = [int][System.Net.WebRequest]::Create("https://meta.fabricmc.net/v2/versions/loader/${MinecraftVersion}/${ModLoaderVersion}/server/json").GetResponse().StatusCode
            $ErrorActionPreference = "Continue";
        }
        catch {
            $FabricAvailable = "400"
        }
        if ("${FabricAvailable}" -ne "200") {
            CrashServer "Fabric is not available for Minecraft ${MinecraftVersion}, Fabric ${ModLoaderVersion}."
        }
        if ((DownloadIfNotExists "fabric-server-launch.jar" "fabric-installer.jar" "${FabricInstallerUrl}")) {
            "Installer downloaded..."
            $script:LauncherJarLocation = "fabric-server-launch.jar"
            RunJavaCommand "-jar fabric-installer.jar server -mcversion ${MinecraftVersion} -loader ${ModLoaderVersion} -downloadMinecraft"
            if ((Test-Path -Path 'fabric-server-launch.jar' -PathType Leaf)) {
                DeleteFileSilently '.fabric-installer' -Recurse
                DeleteFileSilently 'fabric-installer.jar'
                "Installation complete. fabric-installer.jar deleted."
            }
            else {
                DeleteFileSilently  'fabric-installer.jar'
                CrashServer "fabric-server-launch.jar not found. Maybe the Fabric servers are having trouble. Please try again in a couple of minutes and check your internet connection."
            }
        }
        else {
            "fabric-server-launch.jar present. Moving on..."
            $script:LauncherJarLocation = "fabric-server-launch.jar"
        }
    }
    $script:ServerRunCommand = "${script:JavaArgs} -jar ${script:LauncherJarLocation} nogui"

    <#
    .SYNOPSIS

    Download and install a Fabric server for $ModLoaderVersion. If the Fabric Launcher is available for $MinecraftVersion
    and $ModLoaderVersion, it is downloaded and used, otherwise the regular Fabric-installer is downloaded and used.
    Checks are also performed to determine whether Fabric is available for $MinecraftVersion and $ModLoaderVersion.
    #>
}

Write-Host "Start script generated by ServerPackCreator 8.1.0."
Write-Host "To change the launch settings of this server, such as JVM args / flags, Minecraft version, modloader version etc., edit the variables.txt-file."

# Ensures we are working in the directory which contains this script.
$BaseDir = Split-Path -parent $script:MyInvocation.MyCommand.Path
Push-Location $BaseDir

# Check whether the path to this directory contains spaces. Spaces in the path are prone to cause trouble.
if ( ${BaseDir}.Contains(" ")) {
    "WARNING! The current location of this script contains spaces. This may cause this server to crash!"
    "It is strongly recommended to move this server pack to a location whose path does NOT contain SPACES!"
    "Current path: ${BaseDir}"
    $WhyMustPowerShellBeThisWayLikeSeriouslyWhatTheFrag = Read-Host -Prompt 'Are you sure you want to continue? (Yes/No): '
    if (${WhyMustPowerShellBeThisWayLikeSeriouslyWhatTheFrag} -eq "Yes") {
        "Alrighty. Prepare for unforseen consequences, Mr. Freeman..."
    }
    else {
        CrashServer "User did not desire to run the server in a directory with spaces in its path."
    }
}

# It is not recommended to run the server using root as this introduces security risks to your system.
# Using your regular user is enough.
if ( (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Warning! Running with administrator-privileges is not recommended."
}

$ExternalVariablesFile = -join ("${BaseDir}", "\variables.txt");
if (!(Test-Path -Path $ExternalVariablesFile -PathType Leaf)) {
    CrashServer "ERROR! variables.txt not present. Without it the server can not be installed, configured or started."
}

$ExternalVariables = Get-Content -raw -LiteralPath $ExternalVariablesFile | ConvertFrom-StringData
$MinecraftVersion = $ExternalVariables['MINECRAFT_VERSION']
$ModLoader = $ExternalVariables['MODLOADER']
$ModLoaderVersion = $ExternalVariables['MODLOADER_VERSION']
$FabricInstallerVersion = $ExternalVariables['FABRIC_INSTALLER_VERSION']
$Java = $ExternalVariables['JAVA']
$WaitForUserInput = $ExternalVariables['WAIT_FOR_USER_INPUT']
$JavaArgs = $ExternalVariables['JAVA_ARGS']
$Restart = $ExternalVariables['RESTART']
$SkipJavaCheck = $ExternalVariables['SKIP_JAVA_CHECK']
$RecommendedJavaVersion = $ExternalVariables['RECOMMENDED_JAVA_VERSION']
$ServerStarterJarForceFetch = $ExternalVariables['SERVERSTARTERJAR_FORCE_FETCH']
$ServerStarterJarVersion = $ExternalVariables['SERVERSTARTERJAR_VERSION']
$Cleanup = $ExternalVariables['CLEANUP'].Split(",")
$LauncherJarLocation = "do_not_manually_edit"
$ServerRunCommand = "do_not_manually_edit"
$JavaVersion = "do_not_manually_edit"
$Semantics = ${MinecraftVersion}.Split(".")

# Clears the "" from the beginning and end of the Java, JavaArgs vars
$Java = $Java.Trim('"')
$JavaArgs = $JavaArgs.Trim('"')

# If Java checks are desired, then the available Java version is compared to the one required by the Minecraft server.
# Should no Java be found, or an incorrect version be available, the required one is installed by running installJava.
if ("${SkipJavaCheck}" -eq "true") {
    "Skipping Java version check."
}
else {
    if ("${Java}" -eq "java") {
        if (!(CommandAvailable -cmdname "${Java}")) {
            InstallJava
        }
        else {
            GetJavaVersion
            if ($script:JavaVersion -match '[0-9]+') {
                if ($script:JavaVersion -ne $RecommendedJavaVersion) {
                    InstallJava
                }
            }
            else {
                InstallJava
            }
        }
    }
    else {
        GetJavaVersion
        Write-Host "Detected $($Semantics[0]).$($Semantics[1]).$($Semantics[2]) - Java $($JavaVersion)"
        if ($script:JavaVersion -ne $RecommendedJavaVersion) {
            $script:Java = "java"
            InstallJava
        }
    }
}

# Check and warn the user if a 32bit Java-installation is used. Realistically, this should happen less and less, but
# it does happen from time to time. Best to warn people about it.
$Bit = CMD /C "`"${Java}`" -version 2>&1"
if (( ${Bit} | Select-String "32-Bit").Length -gt 0) {
    Write-Host "WARNING! 32-Bit Java detected! It is highly recommended to use a 64-Bit version of Java!"
}

$ReInstall = $args
$PreviousRunFile = -join ("${BaseDir}", "\.previousrun");

if ($ReInstall -eq '--cleanup') {
    Write-Host "Running cleanup..."
    CleanServerFiles
}
elseif (Test-Path -Path $PreviousRunFile -PathType Leaf) {
    $PreviousRunValues = Get-Content -raw -LiteralPath $PreviousRunFile | ConvertFrom-StringData
    $PreviousMinecraftVersion = $PreviousRunValues['PREVIOUS_MINECRAFT_VERSION']
    $PreviousModLoader = $PreviousRunValues['PREVIOUS_MODLOADER']
    $PreviousModLoaderVersion = $PreviousRunValues['PREVIOUS_MODLOADER_VERSION']
    if (!("${PreviousMinecraftVersion}" -eq "${MinecraftVersion}") -or
        !("${PreviousModLoader}" -eq "${ModLoader}") -or
        !("${PreviousModLoaderVersion}" -eq "${ModLoaderVersion}")) {
        Write-Host "Minecraft version, modloader or modloader version have changed. Cleaning up..."
        CleanServerFiles
    }
}

"PREVIOUS_MINECRAFT_VERSION=${MinecraftVersion}`n" +
"PREVIOUS_MODLOADER=${ModLoader}`n" +
"PREVIOUS_MODLOADER_VERSION=${ModLoaderVersion}" | Out-File $PreviousRunFile -encoding utf8

switch (${ModLoader}) {
    NeoForge {
        SetupNeoForge
    }
    Fabric {
        SetupFabric
    }
    default {
        CrashServer "Incorrect modloader specified: ${ModLoader}"
    }
}

if (!(Test-Path -Path 'eula.txt' -PathType Leaf)) {
    "Mojang's EULA has not yet been accepted. In order to run a Minecraft server, you must accept Mojang's EULA."
    "Mojang's EULA is available to read at https://aka.ms/MinecraftEULA"
    "If you agree to Mojang's EULA then type 'I agree'"
    $Answer = Read-Host -Prompt 'Answer'
    if (${Answer} -eq "I agree") {
        "User agreed to Mojang's EULA."
        "#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.ms/MinecraftEULA).`n" +
        "eula=true" | Out-File eula.txt -encoding utf8
    }
    else {
        CrashServer "User did not agree to Mojang's EULA. Entered: ${Answer}. You can not run a Minecraft server unless you agree to Mojang's EULA."
    }
}

""
"Starting server..."
"Minecraft version:              ${MinecraftVersion}"
"Modloader:                      ${ModLoader}"
"Modloader version:              ${ModLoaderVersion}"
"Fabric Installer Version:       ${FabricInstallerVersion}"
"Java Args:                      ${JavaArgs}"
"Java Path:                      ${Java}"
"Wait For User Input:            ${WaitForUserInput}"
if (!("${LauncherJarLocation}" -eq "do_not_manually_edit")) {
    "Launcher JAR:                   ${LauncherJarLocation}"
}
"Run Command:       ${Java} ${ServerRunCommand}"
"Java version:"
RunJavaCommand "-version"
""

# Depending on $Restart the server runs in a loop, to make sure it comes right back up after crashing. Force exit can be
# achieved by hitting CTRL+C multiple times. Variables are not reloaded between server runs. Quit the script and re-run
# it if you wish to reload the variables.
while ($true) {
    RunJavaCommand "${ServerRunCommand}"
    if ("${SkipJavaCheck}" -eq "true") {
        "Java version check was skipped. Did the server stop or crash because of a Java version mismatch?"
        "Detected $($Semantics[0]).$($Semantics[1]).$($Semantics[2]) - Java $($JavaVersion), recommended $($RecommendedJavaVersion)"
    }
    if (!("${Restart}" -eq "true")) {
        Write-Host "Exiting..."
        if ("${WaitForUserInput}" -eq "true") {
            PauseScript
        }
        exit 0
    }
    "Automatically restarting server in 5 seconds. Press CTRL + C to abort and exit."
    Start-Sleep -Seconds 5
}

""