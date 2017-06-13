# Progress Functions
#------------------------------------------------------------#
# These functions are used to report progress to the user

<# 
 .Synopsis
  Writes "Done!" in green.

 .Description
  Leverages Write-Host to write "Done!" with ForegroundColor Green and position the cursor in the next line.
#>
Function Write-Done {
    Write-Host "Done!" -ForegroundColor Green
}

<# 
 .Synopsis
  Writes "Warning!" and the provided message in yellow.

 .Description
  Leverages Write-Host to write "Warning!" with ForegroundColor Yellow and position the cursor in the next line.
  If the WindowsSize is big enough, it'll also render the message inline, otherwhise it'll render it in the following line. 
   
 .Parameter Message
  The warning message to write on screen
#>
Function Write-DoneWithWarning {
    Param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$Message = ""
    )
    Process {
        Write-Host "Warning!" -ForegroundColor Yellow -NoNewline

        if ($Message -ne $null -and $Message -ne "")
        {
            [int] $endPos = $Host.UI.RawUI.CursorPosition.X + $Message.Length + 11

            if($Host.UI.RawUI.WindowSize -eq $null -or $Host.UI.RawUI.WindowSize.Width -ge $endPos)
            {
                Write-Host "- $Message" -ForegroundColor Yellow
            }
            else
            {
                Write-Host
                Write-Host " $Message" -ForegroundColor Yellow
            }
        } else { Write-Host }
    }
}

<# 
 .Synopsis
  Writes "Error!" and the provided message in red.

 .Description
  Leverages Write-Host to write "Error!" with ForegroundColor Red and position the cursor in the next line.
  If the WindowsSize is big enough, it'll also render the message inline, otherwhise it'll render it in the following line. 
   
 .Parameter Message
  The error message to write on screen
#>
Function Write-DoneWithErrors {
    Param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$Message = ""
    )
    Process {
        Write-Host "Error!" -ForegroundColor Red -NoNewline

        if ($Message -ne $null -and $Message -ne "")
        {
            [int] $endPos = $Host.UI.RawUI.CursorPosition.X + $Message.Length + 9

            if($Host.UI.RawUI.WindowSize -eq $null -or $Host.UI.RawUI.WindowSize.Width -ge $endPos)
            {
                Write-Host "- $Message" -ForegroundColor Red
            }
            else
            {
                Write-Host
                Write-Host " $Message" -ForegroundColor Red
            }
        } else { Write-Host }
    }
}

<# 
 .Synopsis
  Writes a message in white and positions the cursor in the specified position.

 .Description
  Leverages Write-Host to write a message with ForegroundColor White and positions the cursor in the specified position inline.
  If the provided message exceeds the max length provided it will trim the extra characters.
   
 .Parameter Message
  The message to write on screen

 .Parameter CursorPosition
  The position in which the cursor will be set after writing the message.
#>
Function Write-Action {
    Param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [string]$Message,
        [Parameter(Position=1,Mandatory=$false)]
        [ValidateScript({$_ -ge 0})]
        [int]$CursorPosition = 60
    )
    Process{
        if ($CursorPosition -ne 0 -and $Message.Length -gt $CursorPosition)
        {
            $Message = $Message.Substring(0, $CursorPosition)
        }

        Write-Host $Message.PadRight($CursorPosition) -ForegroundColor White -NoNewline
    }
}