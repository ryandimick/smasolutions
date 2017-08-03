Function NumericChoice
{
#This is used to make sure the user chooses only the allowed menu choices. $menucountplus should always be 1 greater than the
#number of choices in a menu. $menucountplus should be designated in the function created by the coder
  $IntOK = $false
  while ($IntOK -eq $false)
  {
    try
    {
      [int]$Script:Choice = Read-Host "Choice"
      if (($Choice -gt 0) -and ($Choice -lt $MenuCountPlus))
      {
        $IntOK = $true
      }
      else
      {
        $IntOK = $false
      }
    }
    catch
    {
      $IntOK = $false
    }
  }
}

Function Set-EmailAutoReply
{
  cls
  $Message = "<i>Thank you for your correspondence.<br><br>I am out of the office today and do not have access to email.<br><br>One of my associates will be checking my incoming emails for urgent matters; however, I will respond to all emails and process all incoming paperwork upon my return.<br><br>Please continue to comply with deadlines and submit information via email or to my fax number $fax.<br><br>If you have an emergency, please call 1-888-829-0563 and press ‘0’ at the prompt. One of our Case Coordinators will be able to direct your call accordingly. I apologize for any inconvenience.<br><br>Thank you again, $DisplayName"
  $User = Read-Host "Username of person that will be out"  
  $UPN = "$User@121fcu.org"
  $UserExists = Get-Mailbox -Identity $UPN -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
  if ($UserExists -eq $null)
  {
    Write-Host -ForegroundColor Red "User does not exist."
    $TryAgain = Read-Host "Press any key to try again or type quit"
    if ($TryAgain -eq "quit")
    {
      exit
    }
    else
    {
      Set-EmailAutoReply
      return
    }
  }
  else
  {
    [int] $DaysOut = 0
    $DaysOut = read-host "`nHow many days? (0 = indefinitely)"   
    $Return = ((Get-Date).AddDays($DaysOut)).ToShortDateString()
    if ($days -eq 0)
    {
      #sets auto reply to never expire
      $Message = "<i>Thank you for your correspondence.<br><br>I will be out of the office until further notice. During this time, I will not have access to email.<br><br>One of my associates will be checking my incoming emails for urgent matters; however, I will respond to all emails and process all incoming paperwork upon my return.<br><br>I apologize for any inconvenience."
      Set-MailboxAutoReplyConfiguration -Identity $UPN -AutoReplyState enabled -ExternalMessage $Message -InternalMessage $Message
      Read-Host "`nDone. Press any key to quit"
    }
    else
    {
      #sets auto reply to expire user specified days after the running of the script
      $Message = "<i>Thank you for your correspondence.<br><br>I will be out of the office until $Return. During this time, I will not have access to email.<br><br>One of my associates will be checking my incoming emails for urgent matters; however, I will respond to all emails and process all incoming paperwork upon my return.<br><br>I apologize for any inconvenience."
      Set-MailboxAutoReplyConfiguration -Identity $UPN -AutoReplyState Scheduled -ExternalMessage $Message -InternalMessage $Message -EndTime $Return
      Read-Host "`nDone. Press any key to quit"
    }
  }
}

Function Remove-EmailAutoReply
{
  cls  
  $User = Read-Host "Username of person to remove auto reply"  
  $UPN = "$User@121fcu.org"
  $UserExists = Get-Mailbox -Identity $UPN -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
  if ($UserExists -eq $null)
  {
    Write-Host -ForegroundColor Red "User does not exist."
    $TryAgain = Read-Host "Press any key to try again or type quit"
    if ($TryAgain -eq "quit")
    {
      exit
    }
    else
    {
      Remove-EmailAutoReply
      return
    }
  }
  else
  {
    Set-MailboxAutoReplyConfiguration -Identity $UPN -AutoReplyState Disabled
    Read-Host "`nDone. Press any key to quit"
  }
}

Function Manage-EmailAutoReply
{
  cls
  Write-Host "Make a selection"
  Write-Host
  "1. Quit"
  "2. Set email auto reply"
  "3. Remove email auto reply`n"
  $Script:MenuCountPlus = 4
  NumericChoice
  switch ($choice)
  {
  # CHOICE 1
  1 {
      exit
    }
  # Choice 2
  2 {
      Set-EmailAutoReply
    }
  # CHOICE 3
  3 {
      Remove-EmailAutoReply
    }
  }
}

Manage-EmailAutoReply