param([Switch]$Release)

Import-Module "$PSScriptRoot\..\TestFramework.psm1" -Force
$ModulePath = Get-ModulePath -Release:$Release
$BrowserPort = Get-BrowserPort -Release:$Release

Import-Module $ModulePath -Force

Get-UDDashboard | Stop-UDDashboard

Describe "Element" {

    $Dashboard = New-UDDashboard -Title "Test" -Content {}
    $Server = Start-UDDashboard -Dashboard $Dashboard -Port 10001
    $Driver = Start-SeFirefox
    Enter-SeUrl -Driver $Driver -Url "http://localhost:$BrowserPort"

    Context "Endpoint" {
        $Dashboard = New-UDDashboard -Content {
            New-UDElement -Tag "div" -Id "testElement" -Endpoint {
                New-UDElement -Tag "span" -Content { "Hey!" }
            }
        }

        $Server.DashboardService.SetDashboard($Dashboard)
        Enter-SeUrl -Driver $Driver -Url "http://localhost:$BrowserPort"

        It "has content generated by endpoint" {
            Start-Sleep -Seconds 2
            (Find-SeElement -Driver $Driver -Id "testElement").Text | Should be "Hey!"
        }
    }

    Context "SyncUdElement" {
        $Dashboard = New-UDDashboard -Title "PowerShell Universal Dashboard" -Content {
            New-UDElement -Tag "div" -Id "item1" -Endpoint { $Cache:Value }
            New-UDElement -Tag "div" -Id "item2" -Endpoint { $Cache:Value }
            New-UDElement -Tag "div" -Id "item3" -Endpoint { $Cache:Value }
            New-UDButton -Id "btnPipeline" -Text "Click Me" -OnClick {
                $Cache:Value = "Updated via pipeline"
                "item1", "item2", "item3" | Sync-UDElement 
            }

            New-UDButton -Id "btnParameter" -Text "Click Me" -OnClick {
                $Cache:Value = "Updated via parameter"
                Sync-UDElement -Id @( "item1", "item2", "item3")
            }
        }
        
        $Server.DashboardService.SetDashboard($Dashboard)
        Enter-SeUrl -Driver $Driver -Url "http://localhost:$BrowserPort"

        It "should update via parameter" {
            Find-SeElement -Driver $Driver -Id 'btnParameter' | Invoke-SeClick
            Start-Sleep 2
            (Find-SeElement -Drive $Driver -Id 'item1').Text | should be "Updated via parameter"
            (Find-SeElement -Drive $Driver -Id 'item2').Text | should be "Updated via parameter"
            (Find-SeElement -Drive $Driver -Id 'item3').Text | should be "Updated via parameter"
        }

        It "should update via pipeline" {
            Find-SeElement -Driver $Driver -Id 'btnPipeline' | Invoke-SeClick
            Start-Sleep 2
            (Find-SeElement -Drive $Driver -Id 'item1').Text | should be "Updated via pipeline"
            (Find-SeElement -Drive $Driver -Id 'item2').Text | should be "Updated via pipeline"
            (Find-SeElement -Drive $Driver -Id 'item3').Text | should be "Updated via pipeline"
        }
    }

    Context "ArgumentList" {
        $Dashboard = New-UDDashboard -Title "PowerShell Universal Dashboard" -Content {
            $Patch = 'comp1'
            New-UDButton -Id 'button' -Text $Patch -OnClick (New-UDEndpoint -Endpoint { 
                Add-UDElement -ParentId 'parent' -Content {
                    New-UDElement -Id "output" -Tag 'div' -Content { $ArgumentList[0] }
                }
            } -ArgumentList $Patch )
            New-UDElement -Id 'parent' -Tag 'div' -Content { }
        }

        $Server.DashboardService.SetDashboard($Dashboard)
        Enter-SeUrl -Driver $Driver -Url "http://localhost:$BrowserPort"

        It "should use an endpoint" {
            Find-SeElement -Driver $Driver -Id 'button' | Invoke-SeClick
            Start-Sleep 2
            (Find-SeElement -Drive $Driver -Id 'output').Text | should be "comp1"
        }
    }

    Context "Should work with attributes that start with on" {
        $Dashboard = New-UDDashboard -Title "PowerShell Universal Dashboard" -Content {
            New-UDElement -Tag A -Id "element" -Attributes @{onclick = 'kaboom'} -Content {'IAMME'}
        }
        
        $Server.DashboardService.SetDashboard($Dashboard)
        Enter-SeUrl -Driver $Driver -Url "http://localhost:$BrowserPort"

        It "should not show error" {
            (Find-SeElement -Driver $Driver -Id 'element').Text | Should be "IAMME"
        }
    }

    Context "Heading" {
        $Dashboard = New-UDDashboard -Title "Heading" -Content {
            New-UDRow -Columns {
                New-UDColumn -Endpoint {
                    New-UDHeading -Text "Hello" -Size 4  -Id "Test" 
                }
            }
        }

        $Server.DashboardService.SetDashboard($Dashboard)
        Enter-SeUrl -Driver $Driver -Url "http://localhost:$BrowserPort"

        It "has heading" {
            (Find-SeElement -Driver $Driver -Id "Test").Text | Should be "Hello"
        }
    }

    Context "Events" {

        $Dashboard = New-UDDashboard -Title "PowerShell Universal Dashboard" -Content {
            New-UDRow -Columns { 
                New-UDColumn -Size 12 -Content {
                    New-UDElement -Tag "ul" -Id "chatroom" -Attributes @{ className = "collection" }
                }
            }

            New-UDRow -Columns { 
                New-UDColumn -Size 8 -Content {
                    New-UDTextbox -Id "message" -Placeholder 'Type a chat message'
                }
                New-UDColumn -Size 2 -Content {
                    New-UDButton -Text "Send" -Id "btnSend" -onClick {
                        $message = New-UDElement -Id 'chatMessage' -Tag "li" -Attributes @{ className = "collection-item" } -Content {
                            $txtMessage = Get-UDElement -Id "message" 
                            "$(Get-Date) $User : $($txtMessage.Attributes['value'])"
                        }
                        
                        Set-UDElement -Id "message" -Attributes @{ 
                            type = "text"
                            value = ''
                            placeholder = "Type a chat message" 
                        }

                        Add-UDElement -ParentId "chatroom" -Content { $message } -Broadcast
                    }
                }

                New-UDColumn -Size 2 -Content {
                    New-UDButton -Text "Clear Message"-Id 'btnClear' -OnClick {
                        Clear-UDElement -Id "chatroom"
                    }
                }
            }
        } 

        $Server.DashboardService.SetDashboard($Dashboard)
        Enter-SeUrl -Driver $Driver -Url "http://localhost:$BrowserPort"

        It "should enter a chat message" {

            Start-Sleep 1

            $MessageBox = Find-SeElement -Driver $Driver -Id 'message'
            Send-SeKeys -Element $MessageBox -Keys "Hey"

            $btnSend = Find-SeElement -Driver $Driver -Id 'btnSend'
            Invoke-SeClick -Element $btnSend

            (Find-SeElement -Driver $Driver -Id 'chatMessage').Text | Should BeLike "*Hey"
        }
        
        It "should clear chat messages" {
            $MessageBox = Find-SeElement -Driver $Driver -Id 'message'
            Send-SeKeys -Element $MessageBox -Keys "Hey"

            $btnSend = Find-SeElement -Driver $Driver -Id 'btnSend'
            Invoke-SeClick -Element $btnSend

            $btnSend = Find-SeElement -Driver $Driver -Id 'btnClear'
            Invoke-SeClick -Element $btnSend

            (Find-SeElement -Driver $Driver -Id 'chatMessage').Text | Should Not BeLike "*Hey"
        }
    }

    Context "Element in dynamic page" {
        $HomePage = New-UDPage -url '/home' -Endpoint {
            New-UDCard -Title 'Debug' -Content {
                New-UDButton -Id "Button" -Text 'Restart' -OnClick { Set-UDElement -Id "Output1" -Content {"Clicked"}}
                New-UDHeading -Id "Output1" -Text ""
            }
        } 
        $HomePage.Name = 'Home' # So it appears in the menu
        
        $HomePage2 = New-UDPage -name 'home2' -Content {
            New-UDCard -Title 'Debug' -Content {
                New-UDButton -Text 'Restart' -OnClick { Set-UDElement -Id "Output" -Content {"Clicked"}}
                New-UDHeading -Id "Output" -Text ""
            }
        } 
        
        $Dashboard = New-UDDashboard -Title 'home' -Pages $HomePage,$HomePage2

        $Server.DashboardService.SetDashboard($Dashboard)
        Enter-SeUrl -Driver $Driver -Url "http://localhost:$BrowserPort"

        It "Should work in dynamic page" {
            Find-SeElement -Id "Button" -Driver $Driver | Invoke-SeClick

            Start-Sleep 1

            (Find-SeElement -Id "Output1" -Driver $Driver).Text | Should be "Clicked"
        }
    }

    Context "Session Endpoint Cache" {
        $homePage = New-UDPage -Name "Home" -Content {
            New-UDRow -Columns {
               New-UDColumn -Endpoint {
                  New-UDButton -Id 'button' -Text "Click me" -OnClick {
                      Set-UDElement -Id "changer" -Content { Get-Date }
                  } 
               } -AutoRefresh -RefreshInterval 2
            }

            New-UDRow -Columns {
                New-UDColumn -Content {
                    New-UDElement -Tag div -Id "changer" -Content {}
                }
            }

            New-UDElement -Tag "div" -Id "sessionInfo" -Endpoint {
                $DashboardService.EndpointService.SessionManager.GetSession($SessionId).Endpoints.Count
            } -AutoRefresh -RefreshInterval 1
         } 

         $dashboard = New-UDDashboard -Title "PowerShell Universal Dashboard" -Pages $homePage

         $Server.DashboardService.SetDashboard($Dashboard)
         Enter-SeUrl -Driver $Driver -Url "http://localhost:$BrowserPort"
 
         It "has only 1 cached endpoint" {
             Find-SeElement -Driver $Driver -ClassName 'btn' | Invoke-SeClick

             Start-Sleep 1

             $ChangerText = (Find-SeElement -Driver $Driver -Id "changer").Text
             $ChangerText | Should not be $null
             Find-SeElement -Driver $Driver -ClassName 'btn' | Invoke-SeClick

             Start-Sleep 3

             (Find-SeElement -Driver $Driver -Id "changer").Text | should not be $ChangerText
             (Find-SeElement -Driver $Driver -Id "sessionInfo").Text | should be "1"
         }
    }

    Get-UDDashboard | Stop-UDDashboard
    Stop-SeDriver $Driver

}
