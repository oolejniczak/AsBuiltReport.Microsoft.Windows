function Get-AbrWinFOClusterResource {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Microsoft FailOver Cluster Resource
    .DESCRIPTION
        Documents the configuration of Microsoft Windows Server in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.0
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
        Write-PScriboMessage "FailOverCluster InfoLevel set at $($InfoLevel.FailOverCluster)."
        Write-PscriboMessage "Collecting Host FailOver Cluster Resource information."
    }

    process {
        try {
            $Settings = Invoke-Command -Session $TempPssSession { Get-ClusterResource -Cluster $using:Cluster | Select-Object -Property * } | Sort-Object -Property Name
            if ($Settings) {
                Section -Style Heading3 "Resource" {
                    $OutObj = @()
                    foreach  ($Setting in $Settings) {
                        try {
                            $inObj = [ordered] @{
                                'Name' = $Setting.Name
                                'Owner Group' = $Setting.OwnerGroup
                                'Resource Type' = $Setting.ResourceType
                                'State' = $Setting.State
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }


                    if ($HealthCheck.FailOverCluster.Network) {
                        $OutObj | Where-Object { $_.'State' -notlike 'Online'} | Set-Style -Style Warning -Property 'State'
                    }

                    $TableParams = @{
                        Name = "Resource - $($Cluster.toUpper().split(".")[0])"
                        List = $false
                        ColumnWidths = 25, 25, 35, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }

    end {}

}