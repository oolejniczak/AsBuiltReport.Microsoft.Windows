function Get-AbrWinDHCPv4Statistic {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Microsoft Windows DHCP Servers from Domain Controller
    .DESCRIPTION
        Documents the configuration of Microsoft Windows Server in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Windows
    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "DHCP InfoLevel set at $($InfoLevel.DHCP)."
        Write-PscriboMessage "Collecting Host DHCP Server information."
    }

    process {
        try {
            $DhcpSv4Statistics = Get-DhcpServerv4Statistics -CimSession $TempCIMSession
            if ($DhcpSv4Statistics) {
                Section -Style Heading3 'Service Statistics' {
                    $OutObj = @()
                    try {
                        $inObj = [ordered] @{
                            'Total Scopes' = ConvertTo-EmptyToFiller $DhcpSv4Statistics.TotalScopes
                            'Total Addresses' = ConvertTo-EmptyToFiller $DhcpSv4Statistics.TotalAddresses
                            'Addresses In Use' = ConvertTo-EmptyToFiller $DhcpSv4Statistics.AddressesInUse
                            'Addresses Available' = ConvertTo-EmptyToFiller $DhcpSv4Statistics.AddressesAvailable
                            'Percentage In Use' = ConvertTo-EmptyToFiller ([math]::Round($DhcpSv4Statistics.PercentageInUse, 0))
                            'Percentage Available' = ConvertTo-EmptyToFiller ([math]::Round($DhcpSv4Statistics.PercentageAvailable, 0))
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Service Statistics Item)"
                    }
                    if ($HealthCheck.DHCP.Statistics) {
                        $OutObj | Where-Object { $_.'Percentage In Use' -gt 95} | Set-Style -Style Warning -Property 'Percentage Available','Percentage In Use'
                    }

                    $TableParams = @{
                        Name = "DHCP Server Statistics - $($System.toUpper().split(".")[0])"
                        List = $false
                        ColumnWidths = 17, 17, 17, 17 ,16, 16
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'DC Name' | Table @TableParams
                }
            }
        }
        catch {
            Write-PScriboMessage -IsWarning "$($_.Exception.Message) (IPv4 Service Statistics Table)"
        }
    }

    end {}

}