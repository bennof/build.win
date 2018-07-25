# Powershell Build System
# Copyright 2018 Benjmain 'Benno' Falkner  


param (
    [string]$CFG   = ".\project.cfg",
    [string]$BUILD_WIN_PATH = ".\.build.win",
    [string]$NAME = ($PSScriptRoot | split-path -leaf),
    [switch]$update_build = $false,
    [switch]$help  = $false,
    [switch]$deps  = $false,
    [switch]$build = $false,
    [switch]$run   = $false,
    [switch]$init  = $false
)


function mk_deps(){
    Write-Host "<<DEPS>>"
    $dir = Get-Location
    if(!(Test-Path -Path ".\dll" )){
        New-Item -ItemType directory -Path ".\dll"
    }
    Set-Location -Path ".\dll"
    $conf["deps"].Keys | foreach-object -process { 
        Write-Host "$_ :"$conf["deps"][$_]
        $target = ".\$_"
        $l_name = ".\"+($conf["deps"][$_] | split-path -leaf)
        if( ! (Test-Path $target -PathType Leaf))  {
            Write-Host "Get: "$conf["deps"][$_]
            Invoke-Expression "git clone $($conf['deps'][$_])"
            Write-Host "Build: $l_name"
            $bdir = Get-Location
            Set-Location -Path $l_name
            Invoke-Expression ".\build.ps1 -build"
            Set-Location -Path $bdir
            Copy-Item -Path "$l_name\dll\*" -Include *.dll  -Destination "."
        }
    }
    Set-Location -Path $dir
    return 0
}

function mk_build(){
    Write-Host "<<BUILD $pwd >>"
    $conf["build"].Keys | foreach-object -process {
        if ($_.Trim().EndsWith(".dll")) { # library
            if(!(Test-Path -Path ".\dll" )){
                New-Item -ItemType directory -Path ".\dll"
            }
            Write-Host "csc -target:library -out:$_ $($conf['build'][$_])"
            Invoke-Expression "csc -target:library -out:$_ $($conf['build'][$_])" | Write-Host
        } elseif ($_.Trim().EndsWith(".exe")) { # executable
            if(!(Test-Path -Path ".\bin" )){
                New-Item -ItemType directory -Path ".\bin"
            }
            Write-Host "csc -out:$_ $($conf['build'][$_])"
            Invoke-Expression "csc -out:$_ $($conf['build'][$_])" | Write-Host
        } else {
            Write-Error "ERROR: Unkown target: $_"
            return 1
        }
    }
    return 0
}
function mk_run(){
    Write-Host "Missing"
    return 0
}


if ($help) {
    Start-Process "https://github.com/bennof/build.win"
    return 0;
}

if ($update_build) {
    Remove-Item -Force -Path $BUILD_WIN_PATH
    git clone https://github.com/bennof/build.win $BUILD_WIN_PATH
    $f=get-item $BUILD_WIN_PATH -Force
    $f.attributes="Hidden"
    Invoke-WebRequest -Uri https://raw.githubusercontent.com/bennof/build.win/master/build.ps1 -OutFile build.ps1
    return 0;
}

if ($init) {
    new-item -Force -itemtype directory -path ".\src", ".\bin", ".\dll", ".\priv", ".\test"
    git clone https://github.com/bennof/build.win $BUILD_WIN_PATH
    $f=get-item $BUILD_WIN_PATH -Force
    $f.attributes="Hidden"
    $CONFIG = @"
# Project Configuration File

[General]
Name = `"$NAME`"
Version = `"0.01`"
Git = `"https://github.com/`"

# DLLs
[dll]
# none

# Dependencies from github
[deps]
# none

# Build instruction for each target
[build]
# Example: 
# bin\$NAME.exe = .\src\main.cs

"@; 
    $CONFIG | Out-File -FilePath $CFG -Encoding UTF8;
    Write-Output "If you are using git, add '.build.win' to '.gitignore'"
    return 0;
}

# Read config
$conf=@{}
Try { 
    $group = ""
    Get-Content $CFG | foreach-object -process { 
            $_ = $_.Trim()
            if ( $_.StartsWith("#") -ne $True ) {
                if ( $_.StartsWith("[") ) {
                    $group = $_.Trim("[","]")
                    $conf.Add($group, @{})
                } else {
                    $k = [regex]::split($_,'=');
                    if( ($k[0].CompareTo("") -ne 0)) {
                        if (-not ([string]::IsNullOrEmpty($group))) {
                            $conf.Get_Item($group).Add($k[0], $k[1])
                        } else {
                            $conf.Add($k[0].Trim(), $k[1].Trim())
                        } 
                    }
                }
            }
        }
} Catch { Write-Error "ERROR: Project file could not be read!"; return 1; }



if ($deps) {
    if ( $(mk_deps) -ne 0 ) { Write-Error "ERROR DEPS: $(pwd)"; return 1 }
    return 0
}

if ($build) {
    if ( $(mk_deps) -ne 0 ) { Write-Error "ERROR DEPS: $(pwd)"; return 1 }
    if ( $(mk_build) -ne 0 ) { Write-Error "ERROR BUILD: $(pwd)"; return 1 }
    return 0;
}

if ($run) {
    if ( $(mk_deps) -ne 0 ) { Write-Error "ERROR DEPS: $(pwd)"; return 1 }
    if ( $(mk_build) -ne 0 ) { Write-Error "ERROR BUILD: $(pwd)"; return 1 }
    if ( $(mk_run) -ne 0 ) { Write-Error "ERROR RUN: $(pwd)"; return 1 }
    return 0;
}