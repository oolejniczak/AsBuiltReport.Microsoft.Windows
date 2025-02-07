function Get-AbrWinHyperVNetworking {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Windows Server Hyper-V Networking information.
    .DESCRIPTION
        Documents the configuration of Microsoft Windows Server in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.2.0
        Author:         Andrew Ramsay
        Editor:         Jonathan Colon
        Twitter:        @asbuiltreport
        Github:         AsBuiltReport
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Windows
    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "Hyper-V InfoLevel set at $($InfoLevel.HyperV)."
        Write-PscriboMessage "Collecting Hyper-V Networking information."
    }

    process {
        if ($InfoLevel.HyperV -ge 1) {
            try {
                try {
                    Section -Style Heading3 "Hyper-V MAC Pool settings" {
                        $VmHostMacPool = [PSCustomObject]@{
                            'Mac Address Minimum' = Switch (($VmHost.MacAddressMinimum).Length) {
                                0 {"-"}
                                12 {$VmHost.MacAddressMinimum -replace '..(?!$)', '$&:'}
                                default {$VmHost.MacAddressMinimum}
                            }
                            'Mac Address Maximum' = Switch (($VmHost.MacAddressMaximum).Length) {
                                0 {"-"}
                                12 {$VmHost.MacAddressMaximum -replace '..(?!$)', '$&:'}
                                default {$VmHost.MacAddressMinimum}
                            }
                        }
                        $TableParams = @{
                            Name = "Host MAC Pool"
                            List = $false
                            ColumnWidths = 50, 50
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $VmHostMacPool |  Table @TableParams
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
                try {
                    $VmOsAdapters = Invoke-Command -Session $TempPssSession { Get-VMNetworkAdapter -ManagementOS | Select-Object -Property * }
                    if ($VmOsAdapters) {
                        Section -Style Heading3 "Hyper-V Management OS Adapters" {
                            Paragraph 'The following table details the Management OS Virtual Adapters created on Virtual Switches'
                            Blankline
                            $VmOsAdapterReport = @()
                            Foreach ($VmOsAdapter in $VmOsAdapters) {
                                try {
                                    $AdapterVlan = Invoke-Command -Session $TempPssSession { Get-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName ($using:VmOsAdapter).Name | Select-Object -Property * }
                                    $TempVmOsAdapterReport = [PSCustomObject]@{
                                        'Name' = $VmOsAdapter.Name
                                        'Switch Name' = $VmOsAdapter.SwitchName
                                        'Mac Address' = $VmOsAdapter.MacAddress
                                        'IPv4 Address' = ConvertTo-EmptyToFiller $VmOsAdapter.IPAddresses
                                        'Adapter Mode' = $AdapterVlan.OperationMode
                                        'Vlan ID' = $AdapterVlan.AccessVlanId
                                    }
                                    $VmOsAdapterReport += $TempVmOsAdapterReport
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                            $TableParams = @{
                                Name = "VM Management OS Adapters"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $VmOsAdapterReport | Sort-Object -Property 'Name' | Table @TableParams
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
                try {
                    $VmSwitches = Invoke-Command -Session $TempPssSession { Get-VMSwitch }
                    if ($VmSwitches) {
                        Section -Style Heading3 "Hyper-V vSwitch Settings" {
                            Paragraph 'The following table provide a summary of Hyper-V configured vSwitches'
                            Blankline
                            $VmSwitchesReport = @()
                            ForEach ($VmSwitch in $VmSwitches) {
                                try {
                                    $TempVmSwitchesReport = [PSCustomObject]@{
                                        'Switch Name' = $VmSwitch.Name
                                        'Switch Type' = $VmSwitch.SwitchType
                                        'Embedded Team' = ConvertTo-TextYN $VmSwitch.EmbeddedTeamingEnabled
                                        'Interface Description' = ConvertTo-EmptyToFiller $VmSwitch.NetAdapterInterfaceDescription
                                    }
                                    $VmSwitchesReport += $TempVmSwitchesReport
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            $TableParams = @{
                                Name = "Virtual Switch Summary"
                                List = $false
                                ColumnWidths = 30, 20, 20, 30
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $VmSwitchesReport | Sort-Object -Property 'Switch Name' | Table @TableParams

                            Foreach ($VmSwitch in $VmSwitches) {
                                try {
                                    Section -ExcludeFromTOC -Style NOTOCHeading4 ($VmSwitch.Name) {
                                        $VmSwitchReport = [PSCustomObject]@{
                                            'Switch Name' = $VmSwitch.Name
                                            'Switch Type' = $VmSwitch.SwitchType
                                            'Switch Embedded Teaming Status' = ConvertTo-TextYN $VmSwitch.EmbeddedTeamingEnabled
                                            'Bandwidth Reservation Mode' = $VmSwitch.BandwidthReservationMode
                                            'Bandwidth Reservation Percentage' = $VmSwitch.Percentage
                                            'Management OS Allowed' = ConvertTo-TextYN $VmSwitch.AllowManagementOS
                                            'Physical Adapters' = $VmSwitch.NetAdapterInterfaceDescriptions -Join ","
                                            'IOV Support' = ConvertTo-TextYN $VmSwitch.IovSupport
                                            'IOV Support Reasons' = $VmSwitch.IovSupportReasons
                                            'Available VM Queues' = $VmSwitch.AvailableVMQueues
                                            'Packet Direct Enabled' = ConvertTo-TextYN $VmSwitch.PacketDirectinUse
                                        }

                                        $TableParams = @{
                                            Name = "VM Switch Details"
                                            List = $true
                                            ColumnWidths = 50, 50
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $VmSwitchReport | Table @TableParams
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
        }
    }
    end {}
}
