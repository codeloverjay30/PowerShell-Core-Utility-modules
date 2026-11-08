# Copyright (c) Microsoft. All rights reserved.

<#
.SYNOPSIS
Downloads the given $Version of vsdbg for the given $RuntimeID and installs it to the given $InstallPath

.DESCRIPTION
The following script will download vsdbg and install vsdbg, the .NET Core Debugger

.PARAMETER Version
Specifies the version of vsdbg to install. Can be 'latest', 'vs2022', 'vs2019', 'vs2017u5', 'vs2017u1', or a specific version string i.e. 15.0.25930.0

.PARAMETER RuntimeID
Specifies the .NET Runtime ID of the vsdbg that will be downloaded. Example: linux-x64. Defaults to win7-x64.

.Parameter InstallPath
Specifies the path where vsdbg will be installed. Defaults to the directory containing this script.

.INPUTS
None. You cannot pipe inputs to GetVsDbg.

.EXAMPLE
C:\PS> .\GetVsDbg.ps1 -Version latest -RuntimeID linux-x64 -InstallPath .\vsdbg

.LINK
For more information about using this script with Visual Studio Code see: https://github.com/OmniSharp/omnisharp-vscode/wiki/Attaching-to-remote-processes

For more information about using this script with Visual Studio see: https://github.com/Microsoft/MIEngine/wiki/Offroad-Debugging-of-.NET-Core-on-Linux---OSX-from-Visual-Studio

To report issues, see: https://github.com/omnisharp/omnisharp-vscode/issues
#>

Param (
    [Parameter(Mandatory=$true, ParameterSetName="ByName")]
    [string]
    [ValidateSet("latest", "vs2022", "vs2019", "vs2017u1", "vs2017u5")]
    $Version,

    [Parameter(Mandatory=$true, ParameterSetName="ByNumber")]
    [string]
    [ValidatePattern("\d+\.\d+\.\d+.*")]
    $VersionNumber,

    [Parameter(Mandatory=$false)]
    [string]
    $RuntimeID,

    [Parameter(Mandatory=$false)]
    [string]
    $InstallPath = (Split-Path -Path $MyInvocation.MyCommand.Definition)
)

$ErrorActionPreference="Stop"

# In a separate method to prevent locking zip files.
function DownloadAndExtract([string]$url, [string]$targetLocation) {
    Add-Type -assembly "System.IO.Compression.FileSystem"
    Add-Type -assembly "System.IO.Compression"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Try {
        $zipStream = (New-Object System.Net.WebClient).OpenRead($url)
    }
    Catch {
        Write-Host "Info: Opening stream failed, trying again with proxy settings."
        $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
        $proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        $webClient = New-Object System.Net.WebClient
        $webClient.UseDefaultCredentials = $false
        $webClient.proxy = $proxy

        $zipStream = $webClient.OpenRead($url)
    }
    
    $zipArchive = New-Object System.IO.Compression.ZipArchive -ArgumentList $zipStream
    [System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($zipArchive, $targetLocation)
    $zipArchive.Dispose()
    $zipStream.Dispose()
}

# Checks if the existing version is the latest version.
function IsLatest([string]$installationPath, [string]$runtimeId, [string]$version) {
    $SuccessRidFile = Join-Path -Path $installationPath -ChildPath "success_rid.txt"
    if (Test-Path $SuccessRidFile) {
        $LastRid = Get-Content -Path $SuccessRidFile
        if ($LastRid -ne $runtimeId) {
            return $false
        }
    } else {
        return $false
    }

    $SuccessVersionFile = Join-Path -Path $installationPath -ChildPath "success_version.txt"
    if (Test-Path $SuccessVersionFile) {
        $LastVersion = Get-Content -Path $SuccessVersionFile
        if ($LastVersion -ne $version) {
            return $false
        }
    } else {
        return $false
    }

    return $true
}

function WriteSuccessInfo([string]$installationPath, [string]$runtimeId, [string]$version) {
    $SuccessRidFile = Join-Path -Path $installationPath -ChildPath "success_rid.txt"
    $runtimeId | Out-File -Encoding ascii $SuccessRidFile

    $SuccessVersionFile = Join-Path -Path $installationPath -ChildPath "success_version.txt"
    $version | Out-File -Encoding ascii $SuccessVersionFile
}

$ExplitVersionNumberUsed = $false
if ($Version -eq "latest") {
    $VersionNumber = "18.7.10521.2"
} elseif ($Version -eq "vs2022") {
    $VersionNumber = "18.7.10521.2"
} elseif ($Version -eq "vs2019") {
    $VersionNumber = "18.7.10521.2"
} elseif ($Version -eq "vs2017u5") {
    $VersionNumber = "18.7.10521.2"
} elseif ($Version -eq "vs2017u1") {
    $VersionNumber = "15.1.10630.1"
} else {
    $ExplitVersionNumberUsed = $true
}
Write-Host "Info: Using vsdbg version '$VersionNumber'"

if (-not $RuntimeID) {
    $RuntimeID = "win7-x64"
} elseif (-not $ExplitVersionNumberUsed) {
    $legacyLinuxRuntimeIds = @{ 
        "debian.8-x64" = "";
        "rhel.7.2-x64" = "";
        "centos.7-x64" = "";
        "fedora.23-x64" = "";
        "opensuse.13.2-x64" = "";
        "ubuntu.14.04-x64" = "";
        "ubuntu.16.04-x64" = "";
        "ubuntu.16.10-x64" = "";
        "fedora.24-x64" = "";
        "opensuse.42.1-x64" = "";
    }

    # Remap the old distro-specific runtime ids unless the caller specified an exact build number.
    # We don't do this in the exact build number case so that old builds can be used.
    if ($legacyLinuxRuntimeIds.ContainsKey($RuntimeID.ToLowerInvariant())) {
        $RuntimeID = "linux-x64"
    }
}
Write-Host "Info: Using Runtime ID '$RuntimeID'"

# if we were given a relative path, assume its relative to the script directory and create an absolute path
if (-not([System.IO.Path]::IsPathRooted($InstallPath))) {
    $InstallPath = Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Definition) -ChildPath $InstallPath
}

if (IsLatest $InstallPath $RuntimeID $VersionNumber) {
    Write-Host "Info: Latest version of VsDbg is present. Skipping downloads"
} else {
    if (Test-Path $InstallPath) {
        Write-Host "Info: $InstallPath exists, deleting."
        Remove-Item $InstallPath -Force -Recurse -ErrorAction Stop
    }
 
    $target = ("vsdbg-" + $VersionNumber).Replace('.','-') + "/vsdbg-" + $RuntimeID + ".zip"
    $url = "https://vsdebugger-cyg0dxb6czfafzaz.b01.azurefd.net/" + $target

    DownloadAndExtract $url $InstallPath

    WriteSuccessInfo $InstallPath $RuntimeID $VersionNumber
    Write-Host "Info: Successfully installed vsdbg at '$InstallPath'"
}

# SIG # Begin signature block
# MIIpkgYJKoZIhvcNAQcCoIIpgzCCKX8CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBBQepCt6P49y76
# 3o1iUs/uVWw6rLh9aYEJtzNDie+AM6CCDeUwgga9MIIEpaADAgECAhMzAAAAHEif
# gd+hsLd3AAAAAAAcMA0GCSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0
# aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yNDA4MDgyMTM2MjNaFw0zNTA2MjMy
# MjA0MDFaMF8xCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMDAuBgNVBAMTJ01pY3Jvc29mdCBXaW5kb3dzIENvZGUgU2lnbmluZyBQ
# Q0EgMjAyNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJp9a30nwXYq
# Lq7j1TT/zCtt7vxU+CCj+7BkifS/B2gXKGU7OV9SXRJGP1yFs5p6jpsYi4cYzF56
# AV0AEmmEjV8wT2lvPU5BhN3wV30HqYPIYEj5P3WXf0kXD9fvjUf1GAtXEriJ8w7A
# LNaVEm9Rs4ePA0ZsYHaCbU5kBUJQDXv76hafOcQgdFCA3I3zYtfzX2vOwx87uDOa
# CuyKORZih9c3zTf+TLC5QYLyhVMBnDXEHDOrvaw92DSyIqpdgRWpufzqDFy1egVj
# koXZhb+9pZ9heUzNXTXhOoXzexh6YzAL4flBWm+Bc1hQyESenEvBJznV+25u3h77
# jjgMUY44+WXQ4u9qddDe/U5SeAaKRvvibmi4z7QRpLvZsla0CPiOUGz00Do5sfkC
# 0EwlsSzfM3+8A9rsyFVOgWDVPzt98OJP2EoaEOq8GE9GCoN2i7/4C2FCwff1BSCT
# JWZO1Wcr2MteJE6UxGV+ihA8nN51YPKD2dYGoewrXvRzC/1HoUeSvlZf0mf9GHEt
# vvkbJVRRo6PBf0md5t87Vb1mM/fIp1eypyaxmXkgpcBwuylsOq2kSVOJ5wBPoaEs
# sJkeMcKnEuuu++UKdDHlS0DtsYjN0QnOucvTdSsdvhzKOSjJF3XVqr9f2C945LXT
# 5rxKIHUIEDBcNYU6BKDDH6rfpKOOCSilAgMBAAGjggFGMIIBQjAOBgNVHQ8BAf8E
# BAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFB6C3w7XjLPXAjSDDtqr
# rWW5r7jsMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMA8GA1UdEwEB/wQFMAMB
# Af8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBL
# oEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggr
# BgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNS
# b29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQEMBQADggIBAENf+N8/
# u+mUjDtc9btoA52RBc0XVDSBMQBMqxu56hXHBwuctUWs1XBqDDMIFCHu9c6Y/UF+
# TN8EIgjnujApKYmHP4f4EM3ARSmlzrpF5ozOJx0BA5FUv1jmpdf/2ZbqpvCxlxv/
# G1R4KjrSmmqPHzs6igw3b7RTbj7BxIS8fOIkwYWQhB2fLjlg+3HSrDGPFIhpIJWV
# amMIR7a72OGonjdf45rspwqIHuynZU4avy9ruB/Rhhbwm+fMb8BMecIaTmkohx/E
# ZZ5GNWcN6oTYW3G2BM3B3YznWkl9t4shP60fMue+2ksdHGWSE8EVTdSmGUdj0jrU
# c46lGVFJISF3/MxcxnlNeP1Khyr+ZzT4Ets/I7mufpaLnLalzMR2zIuhGOAWWswe
# sbjtFzkVUFgDR2SW903I0XKlbPEA6q8epHGJ9roxh85nsEKcBNUw4Scp68KCqSpF
# BaKiyV1skd+l8U50WNePMb9Bzz0OfASal8v5sQG+DW01kN+I+RKUIbM5I50wJjiH
# ymQFNDsbobFx9I95mCEEPU7fUZ3VT/HOUVbkmX7ltIC/eQAu5GO8fu+ceETMybvb
# oxUM4dYNC+PzooUxfmC0DuKRwB21bX9+acuIBkxIm4Ed3O19w1VLoA7UNOUuJ7z6
# NQ2W/+q7cnfOPl2QVL4qlgCblUT2vmQpllV3MIIHIDCCBQigAwIBAgITMwAAASJs
# BjOj0VK23QAAAAABIjANBgkqhkiG9w0BAQwFADBfMQswCQYDVQQGEwJVUzEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTAwLgYDVQQDEydNaWNyb3NvZnQg
# V2luZG93cyBDb2RlIFNpZ25pbmcgUENBIDIwMjQwHhcNMjYwMzA1MTk1ODI0WhcN
# MjcwMzAzMTk1ODI0WjB0MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMR4wHAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24wggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQCeFlu3IJtMm0DcCUF5EKHUKh/L06a1JyvxX2aV
# aapyABxwDINwxmSS0MR5ObqvX4TKhYX2Ic7+HNhNjxZg7UJUTMamRDcmnS3QHYOe
# oqsgveL1mGQsvBqWROEi2tBe8PrwJrYd4tefld81kaQ1cnbzuUuou3fuAHNudJnA
# CW5SqPmZHF565Ij7jwMeJPxU5JHsPAs/Y11aWPxI85kVEUecjfOMpIx5oTXnNi9U
# nw7BSv/SSrXfkyAyFyqu+PN9ymIWLmOAPaAnJ+QxGRZ9D7jJy4fZK0RxO1GlPTaj
# h9xgbz7SDSeC70z8Ro8mgO3ImrCDv4KdJztT5dnCieVXLMSxCqWikfKznmoCaAqG
# 5skdylL5CFi8TQVKASb2QR0MjS1fqX0FpOkgibu7+m2EPzjp36SkgZ1TXVfAO3j5
# BjRZT/VXaWS0Zk+eNn8/SQf8U/LRRpnuJXhkOWVBNIGq5ew6EsKIQm5Dter5NTSK
# J8gUlqiwDKZ1HuaTEWn1PmgN0YYF9av8fDTeVbEPQe04yv47o8lYpldFM0B9kWOc
# kIc0U+hXNC/+pnDVUh2fjN+JtMaLKTTOciXM2F0tt3CbdKO+cCmlCzSuhN9aeQ2m
# GEnQY3v3V3W15uaUpYELTYOTeTwDVkYJXCZK/zNRXxU38rQ+LwxLOeRVNvEYh2Js
# 0nuX0QIDAQABo4IBvjCCAbowDgYDVR0PAQH/BAQDAgeAMB8GA1UdJQQYMBYGCisG
# AQQBgjc9BgEGCCsGAQUFBwMDMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFJ8ytbdA
# tti7ifaKbKxtPwbvlJiSMFQGA1UdEQRNMEukSTBHMS0wKwYDVQQLEyRNaWNyb3Nv
# ZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxFjAUBgNVBAUTDTIzMDg2NSs1
# MDY5NjUwHwYDVR0jBBgwFoAUHoLfDteMs9cCNIMO2qutZbmvuOwwagYDVR0fBGMw
# YTBfoF2gW4ZZaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWlj
# cm9zb2Z0JTIwV2luZG93cyUyMENvZGUlMjBTaWduaW5nJTIwUENBJTIwMjAyNC5j
# cmwwdwYIKwYBBQUHAQEEazBpMGcGCCsGAQUFBzAChltodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFdpbmRvd3MlMjBDb2Rl
# JTIwU2lnbmluZyUyMFBDQSUyMDIwMjQuY3J0MA0GCSqGSIb3DQEBDAUAA4ICAQCY
# WFIyjTfk5OvOrxA8oAS2jbS6/P0DDLLiqZsyy6dY9vfid+P2uawuygeoVwkvGqMO
# 0UDWuupsy8VQ/5Fw+GXfx7n9AfvoVg30rHm883siWQ9/GaayCh219lbearlRziyq
# TZoz7ShvA23fRoKs3I9LlXWWOH1d5CeFtuyX0D4oRBU1pQS+ijDSv848ZiLwqjig
# Q7XBaYiPNVQI8xMkkVeIc6B575rVsxqLF5rQFMuXZhwU+BXEbVa4tmVAzY9geP3X
# dOP+L/OwWQV83Z6poT/RW6QMqkNpgf7Pc3oSGKGTpr32AwHIutwmWaEaj8asyDUj
# FABzJBG6AH8pugTf440r61uNlw6mDXppfOZVyuHuH93uNzaINvuW/Y/yEYSDdTvy
# 6Sn5GwWrHKNA23UR18Abu7B2uOeDhiTq69oePmKEAPjjHMTQBrZUX+VBwv+v7MJB
# r8A0s4zg/AY+A/LmN5veQpcAjTj9H+2mKEQobRTUHKBDW1T1fXYQb1JdWQXDK9In
# 6Lx8EaWOExYktAceGfzxC9NoCjxBUb8ba6QOQXNaqrzQlDzGwqxLsiClN+H6h58p
# BfFF2OoSaLlgpih0WRfp7sTGddsp6ajbAAX7VSI/W32o2G7KaDIc1jiok64BnBRo
# ewtKnNm3Ny0ulmJ6IgIZA5DOAxT9tPtEtNhwHmhshzGCGwMwghr/AgEBMHYwXzEL
# MAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEwMC4G
# A1UEAxMnTWljcm9zb2Z0IFdpbmRvd3MgQ29kZSBTaWduaW5nIFBDQSAyMDI0AhMz
# AAABImwGM6PRUrbdAAAAAAEiMA0GCWCGSAFlAwQCAQUAoIGuMBkGCSqGSIb3DQEJ
# AzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8G
# CSqGSIb3DQEJBDEiBCDhbbo5wU4SYlEBtWoqU2bv1KB+Qjhh8ajHycfhBMan4TBC
# BgorBgEEAYI3AgEMMTQwMqAUgBIATQBpAGMAcgBvAHMAbwBmAHShGoAYaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tMA0GCSqGSIb3DQEBAQUABIICABrByBHCDve71Rj/
# qZhSNIJ3JsW5sAW1viyzFFnQqW30JyQBKk+YsMOoNM+K1EA/50zzuMtTVKEBLT4x
# HclhDFLwUIoJhfqS0wV5IBNeCYOvkklm+24z21KITM/lTyuqAo4tjntt8wCWBVtc
# UMJME6QMWiQKOT31I2VfeJBtwsu89GAZuRgqc+AujWmud/GDDVWw6E5Ph/d9KoEO
# ciJRi7qil1zsT1fhqgCAxwWQr6WbqtBzx79jQXAd7CVvESAnsX6hJ9i3fkGDgAZ2
# zGNa/TmWKjmMAMRBBqHjb1QgivHjZ9J0pJbuCihxvICNTas5TyR7wlvqWJ7sZNJF
# YQK/d/ZYI+zXqmiqgzq6CMAbYt1NPPt9fj0leyJUIbBjOUXBPHho285AatWMvD+L
# +TAj1CyJVcSbIAWRy9Hx7pg5bAEiSn2d4lgNHXRPS2+0dQ8RNOa7AvDLwn0TxBEf
# ml+x1k2IrYrCnxUv187St2iwffBX9N/sWp79uUrVL3uhE/MbGuYBgtLxf6y5l9x8
# fHg+MPShY8MT0CEg7C4iHLdSoPX0csCkJKmTYLZNuzR4uSP3cF+YVzRgloGmbm2R
# A2qMzDg51hekjJu1Jspq7GORoXSvbFYcgA3KoRizQgafcFsqN+jNC/Kjh0iJjO52
# xJScOCev3DfkkDbT1Tiz99JJfLgWoYIXrTCCF6kGCisGAQQBgjcDAwExgheZMIIX
# lQYJKoZIhvcNAQcCoIIXhjCCF4ICAQMxDzANBglghkgBZQMEAgEFADCCAVoGCyqG
# SIb3DQEJEAEEoIIBSQSCAUUwggFBAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUD
# BAIBBQAEIEchefBCMdHvkIZntKBkWG1ssrGEmwN/ijs0tWq3oTzHAgZp69faFb0Y
# EzIwMjYwNTIxMDYyMDIzLjU1M1owBIACAfSggdmkgdYwgdMxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVs
# YW5kIE9wZXJhdGlvbnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNO
# OjRDMUEtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloIIR+zCCBygwggUQoAMCAQICEzMAAAIYJdmSBeLn5eQAAQAAAhgwDQYJ
# KoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjUw
# ODE0MTg0ODI1WhcNMjYxMTEzMTg0ODI1WjCB0zELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046NEMxQS0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Uw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCx3Ojq65AmoB/Eue8QF8i+
# PqScr6npucxcQVn9CM84XLCVyMN/MjwODWfMOXGbv+mpu+NaHK9rMqYXI7qps/AK
# V9GcjnuHk4KLGCk44IYklAhlJOIyC6LcHwM+IW0k9x/NG3cWyfGMtfAEiMaCeMZ+
# ZCXvN6MDVahgv+oGZCHD8UMVNZ5vF+jibREII7F/arCPfVo6NzZphR4+0sxcexco
# 8UfS2nlIogX/20nFFKDQ1gS9CpWKWN7xpCQ93erMC7HYxzkcxIrg0xO1VUJgBYNR
# nin7qIMj23kE0IEix/migU1Ra3EKqekViItiQd8V/GFVQFnwsYbFiwDfqycPrmzY
# d/i3zqTR7xZ6Uf+6x+Fio4zfPbJojyuDTzrfUiTCpTPJCgQ+oyweAF6bXGmY4ZIh
# SdW9OwC/6WYQIvZGqtw5mVlrHwrRqKKPyHpSRYE3YgD+KRpyRNIZVEFCZZZm4sVZ
# X9PjG43OxwLRfvGjh962CmypoQDSNj9B6+RO8u/g6U03144vws2HtWbRHrk/uhps
# 5AOq1QUDAKCOA8nSJX+NAJowBw7dJikbnBIBiImSThcuM1KU3FTYh2OzWw5GGXuz
# ssLqE5vttUAdXA43vgbF8U2IQgDoF+50A2OlAnSdRz+mkRelPimAMEexi1Xw7IpK
# MqwjE50VHt8gkiMNzwO9SQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFCQuocRcOhtj
# t0e6hAIFrixftovRMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8G
# A1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBs
# BggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUy
# MDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUH
# AwgwDgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQCeSNGGPA+B2gim
# +3hiKhP+PQta4HEXcBEEpcMQ2CCtoq8LShE/BuMCaxec8Sa26jkwPy4n1fD15ivG
# qqQrgMX2ydkyscx+ijEJr77WKsvPxiijMLi1yL5rg3ftJuR7Wm3XGz2pm2+Q+BkZ
# afkFzBV+YDBJkseLYK5nTpjT9f63p80GetsxWi81oNfhY93Ij0YTPF8iCAOxyTYi
# mjhVcv8CtzPunYXtsRkZG7LGOAwL7CgKQMlof/KT/BxmkCyLF7g8503QNbplvfk7
# cODf5rqmsA0xzdYh298oOXvk/RqpxBtABHtvR/iAfg0yRRy3RabgY3kqGwTVgrtX
# /ACoMqYriPHfMvPdrwezFr0cHcbKK2WYLmwOE6XhBMY3mRGLqgKhXiEr6QgWCeRa
# MeFJE2ibPfpCdsJIb8EcsSbYZFT27f8jjNR30TUAL3sgkQZ/Bv7Q1ZvdARyuTKl0
# Z1bCXQsQ5uGtBH0HVXv551zI2axfSnYFfSsWl3U+RclJvF/whwSLD9uQ2BqBkT5W
# UO3Fd6u4t2jmTeUY6/us9i44RqhljEO9m2kc/0/frCZbgg2NHo0iefZQz6Ss//F4
# udFsMGSb1GyWegOFWtqWIoMfrYHGFyAv22JGA4eVwjTCq9VYt2/zJbyvGRrA6WEJ
# GpPcQoQJbyS1QA/A1sFQuRP6hZy8FzCCB3EwggVZoAMCAQICEzMAAAAVxedrngKb
# SZkAAAAAABUwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmlj
# YXRlIEF1dGhvcml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIy
# NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXI
# yjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjo
# YH1qUoNEt6aORmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1y
# aa8dq6z2Nr41JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v
# 3byNpOORj7I5LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pG
# ve2krnopN6zL64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viS
# kR4dPf0gz3N9QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYr
# bqgSUei/BQOj0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlM
# jgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSL
# W6CmgyFdXzB0kZSU2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AF
# emzFER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIu
# rQIDAQABo4IB3TCCAdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIE
# FgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWn
# G1M1GelyMFwGA1UdIARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEW
# M2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5
# Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBi
# AEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV
# 9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3Js
# Lm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAx
# MC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2
# LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv
# 6lwUtj5OR2R4sQaTlz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZn
# OlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1
# bSNU5HhTdSRXud2f8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4
# rPf5KYnDvBewVIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU
# 6ZGyqVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDF
# NLB62FD+CljdQDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/
# HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdU
# CbFpAUR+fKFhbHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKi
# excdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTm
# dHRbatGePu1+oDEzfbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZq
# ELQdVTNYs6FwZvKhggNWMIICPgIBATCCAQGhgdmkgdYwgdMxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVs
# YW5kIE9wZXJhdGlvbnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNO
# OjRDMUEtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQCda0atdaK40TxCsp+bgK0avnvP6aCBgzCB
# gKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBCwUA
# AgUA7bibeTAiGA8yMDI2MDUyMDIwNDMzN1oYDzIwMjYwNTIxMjA0MzM3WjB0MDoG
# CisGAQQBhFkKBAExLDAqMAoCBQDtuJt5AgEAMAcCAQACAgdRMAcCAQACAhMFMAoC
# BQDtuez5AgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEA
# AgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBAG7T630sEIO3GiXe
# eQZGa9tgJs6RpbNCioGTXQxkQNfFJAcCdCoA87yI6Yyjd0xLkjX5ZWEYsGEuX90U
# GsriQO9fViRBDsENfUdRdiH3sSx9y6/tpH2F31VAiicdKYQoWZzOlE75IlyKDBaR
# W3EU7zw6IXTDg3k4cVgLxx3aZzvljied+dIguoaHbBCaH+04Z53ne/aqieC4n+P3
# buvMGxK5zTT+Kl5e/nJ0kBP8GAeve8U1M55iQL+ctGsdv4sasiOAXl7FK1t3hdAS
# PkCeybSE6ox7ijX7FMUAxuaSrgbFRHtNg5LBLgTVFIOHQVmHmbW2XQeFejs/6Dau
# zLFh2CAxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MAITMwAAAhgl2ZIF4ufl5AABAAACGDANBglghkgBZQMEAgEFAKCCAUowGgYJKoZI
# hvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCBacyEHEzCbt2Vl
# imz3iy8L2BFk5dWhiRuWXeYP3cj6QzCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQw
# gb0EIJkT3Im45Mi0jBZoRLqXMYorVdxKjPXKdHNo5XPH14VqMIGYMIGApH4wfDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAIYJdmSBeLn5eQAAQAAAhgw
# IgQgnX9OZFLc19T6q0oj3ZM38I297uOTBxy8Ma2h1UMei1YwDQYJKoZIhvcNAQEL
# BQAEggIAQIfLnsQlw99BporGnTuPFnBCoTzEobSwqnMmu7ZMh6QRGhto/lh3xz5F
# pdGlcvM89klDSWpwKLHRqJ4RJQOvAaQW2BocGqRN9BIbuiLTac6ZulM1VdPiiDYM
# BRqfXgJeTFZIiaEveKZwu9H3RjrXpfRzmDMGdwugOiKQh98eEhPUZul8YM0YkYdf
# lHEAVN6Vq8mbtmDwGMV/x1lCbO2sDhSILE07LBIpDQUg4ppIyHOZdF3u8X4PTj2d
# mqSfxb3o+o7zKAsGPG7F9H0VW+XgtJM39ta/xp0MWq9TlzsbR24nLD1VuZOGY1cB
# gTKUV/1OrLctqz575YiqIellfY9ZOSMEDlW9hfBxKBcKCYjtIBBQ8Cho2n9K5vjM
# tuxEGnY2hGeg2QLfHnNY4aM9sI+MHxGkMXb9c8RW4DVLB7LMm6p3vIzAX7aCJyvr
# j1+aI5NAhHvOzd79m++b8qOzDv7L+4x/uBSvHB83UzUw6sDpLldsC/qfUIj+tSIc
# hNw+rwdTWz61kqrpj0oJqnizb7slodHPyhILasRUqtxEN4zGfLg5n5VSCJQPfCWN
# tFXBzHp3YunAnBoPe3dn0+/3x63qAqhYegMv6YOQnEN3PI35t4Z4r3AAqmgouhq2
# Aot2w4QcqtY2iPRnfklljyk+73rv/K/bp9CmQGEM/HIPCBGj6UM=
# SIG # End signature block
