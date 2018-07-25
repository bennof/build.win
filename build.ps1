# Powershell Build System
# Copyright 2018 Benjmain 'Benno' Falkner  


param (
    [string]$cfg   = "project.cfg",
    [switch]$help  = $false,
    [switch]$deps  = $false,
    [switch]$build = $false,
    [switch]$run   = $false,
    [switch]$init  = $false
)

if ($help) {
    return 0;
}

if ($init) {
    return 0;
}
