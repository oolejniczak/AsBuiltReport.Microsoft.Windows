function Get-AbrWinFOClusterAvailableDisk {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Microsoft FailOver Cluster Available Disk
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
        Write-PscriboMessage "Collecting Host FailOver Cluster Available Disk information."
    }

    process {
        try {
            $Settings = Invoke-Command -Session $TempPssSession { Get-ClusterAvailableDisk -Cluster $using:Cluster} | Sort-Object -Property Name
            if ($Settings) {
                Section -Style Heading3 "Available Disk" {
                    $OutObj = @()
                    foreach  ($Setting in $Settings) {
                        try {
                            $inObj = [ordered] @{
                                'Name' = $Setting.Name
                                'Number' = $Setting.Number
                                'Size' = ConvertTo-FileSizeString $Setting.Size
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }

                    $TableParams = @{
                        Name = "Available Disk - $($Cluster.toUpper().split(".")[0])"
                        List = $false
                        ColumnWidths = 40, 30, 30
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