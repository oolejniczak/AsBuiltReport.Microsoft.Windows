function Get-AbrWinFOClusterSharedVolumeState {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Microsoft FailOver Cluster Shared Volume State
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
        Write-PscriboMessage "Collecting Host FailOver Cluster Shared Volume State information."
    }

    process {
        try {
            $Settings = Invoke-Command -Session $TempPssSession { Get-ClusterSharedVolumeState -Cluster $using:Cluster | Select-Object -Property * } | Sort-Object -Property Name
            if ($Settings) {
                Section -Style Heading4 "Cluster Shared Volume State" {
                    $OutObj = @()
                    foreach  ($Setting in $Settings) {
                        try {
                            $inObj = [ordered] @{
                                'Name' = $Setting.Name
                                'Node' = $Setting.Node
                                'State' = $Setting.StateInfo
                                'Volume Name' = $Setting.VolumeFriendlyName
                                'Volume Path' = $Setting.VolumeName
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }

                    $TableParams = @{
                        Name = "Cluster Shared Volume State - $($Cluster.toUpper().split(".")[0])"
                        List = $false
                        ColumnWidths = 20, 20, 20, 20, 20
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