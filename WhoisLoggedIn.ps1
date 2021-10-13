function Get-LoggedOnUser
 {
     [CmdletBinding()]
     param
     (
         [Parameter()]
         [ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })]
         [ValidateNotNullOrEmpty()]
         [string[]]$ComputerName = $env:COMPUTERNAME
     )
     foreach ($comp in $ComputerName)
     {
         $output = @{ 'ComputerName' = $comp }
         $output.UserName = (Get-WmiObject -Class win32_computersystem -ComputerName $comp).UserName
         [PSCustomObject]$output
     }
 }
 #add assembly to run a .net core WFP xaml file
 Add-Type -AssemblyName PresentationFramework
 $xamlFile = "MainWindow.xaml"
 #get content of xaml file
 $inputXML = Get-Content $xamlFile -Raw
 $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*','<Window'
 [XML]$XAML = $inputXML
 #setup reader to read the xaml file
 $reader = (New-Object System.Xml.XmlNodeReader $xaml)
 try{
    $window = [Windows.Markup.XamlReader]::Load($reader)
    }catch {
    Write-Warning $_.Exception
    throw
    }
$xaml.SelectNodes("//*[@Name]") | ForEach-Object{
    try{
        Set-Variable -Name "var_$($_.Name)" -Value $window.FindName($_.Name) -ErrorAction Stop
    }catch{
        throw
    }
}

Get-Variable var_*

#function to display in result field

function LoggedOnUser{
     #if else to see if anything was put into the text box for computer name. 
    if($var_txtCmpName.Text -eq ""){
        $var_txtResults.Text = "You must enter a computer name"
    }else {
     #try and catch for when no one is logged into the computer
         try {
        ($result = Get-LoggedOnUser $var_txtCmpName.Text)
        foreach ($comp in $result)
         {
           $var_txtResults.Text = "Computer Name: $($comp.ComputerName)`n"
           $var_txtResults.Text = $var_txtResults.Text + "User: $($comp.UserName)"
         }
    }catch {
     $var_txtResults.Text = "No one currently logged into computer"
        }
    }

}
#function to clear out the display field
function ClearResults{

    $var_txtResults.Text = ""

}

#run functions when btnsearch is clicked (loggedOnUser)
$var_btnSearch.Add_Click({
  ClearResults
  LoggedOnUser
})
#run functions when enter key is pressed in text field
$var_txtCmpName.Add_KeyDown({

    if($_.Key -eq "Enter"){
        ClearResults
        LoggedOnUser
    }

})

#clear both text fields
$var_btnReset.Add_Click({

    $var_txtCmpName.Text =""
    ClearResults

})

$Null = $window.ShowDialog()
