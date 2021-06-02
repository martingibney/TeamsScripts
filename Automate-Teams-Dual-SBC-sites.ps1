##################################################################################################################################################
# 
# Create dual SBC sites in Teams Tenant
# By Martin Gibney 
# Run this script in PowerShell on jump server
# Script will create two SBCs based on variables defined in Global Variables section
#
# Version 1 - 2nd June 2021
# Author Martin Gibney (@TheMartinGibney on Twitter)
#
#################################################################################################################################################

write-host -foregroundcolor red "TEAMS Dual SBC Site SETUP SCRIPT - Automation Version 1"


# Cleans up old sessions to ensure no errors in running the scripts - put in due to errors running multiple time in same window
Get-PSSession | Remove-PSSession

# Connection to Microsoft Teams
write-host -foregroundcolor GREEN "connecting to Teams Service"
Connect-MicrosoftTeams

########################
# 1. Global Variables  #
########################
# This section defines policy names here which you can change for different SBCs and sites
# MAKE YOUR CHANGES HERE!!

# FQDN of site 1 SBC
$SBCfqdn1 = "sbc-EU.domain.com"

# FQDN of site 2 SBC
$SBCfqdn2 = "sbc-US.domain.com"

# SIP Signaling port used for connectivity into Teams Tenant - usually 5067
$SIPport = "5067"

# Max concurrrent sessions (SIP Channels) between SBC1 and Teams
$Channels1 = "100"

# Max concurrrent sessions (SIP Channels) between SBC2 and Teams
$Channels1 = "100"

# PSTN Usage Name for Site 1
$PSTNusage1 = "EU"

# PSTN Usage Name for Site 2
$PSTNusage2 = "US"

# Site 1 Voice Route Name
$Site1route = "EU Route"

# Site 2 Voice Route Name
$Site2route = "US Route"



#####################
# 2. Transcript/Log #
#####################

# Function to get timestamp for using in transcript file
$time = get-date -format yyyyMMdd-HHmmss
$newfile= "NewTeamsSBC-" + $time + ".txt"
write-host -foregroundcolor BLUE "Starting Transcript"
Start-Transcript $newfile

#####################
# 3. PSTN Gateways  #
#####################

# Creates an SBC / PSTN Gateway for the first site
New-CsOnlinePSTNGateway -Identity $SBCfqdn1 -Enabled $true -SipSignalingPort $SIPport -MaxConcurrentSessions $Channels1

# Creates an SBC / PSTN Gateway for the second site
New-CsOnlinePSTNGateway -Identity $SBCfqdn2 -Enabled $true -SipSignalingPort $SIPport -MaxConcurrentSessions $Channels2

#####################
# 4. PSTN Usages    #
#####################

# Creates an PSTN Usage for the first site
Set-CsOnlinePstnUsage  -Identity Global -Usage @{Add="$PSTNusage1"}

# Creates an PSTN Usage for the second site
Set-CsOnlinePstnUsage  -Identity Global -Usage @{Add="$PSTNusage2"}

#####################
# 5. Voice Routes   #
#####################

# Creates primary route for first site using local SBC / PSTN Gateway
New-CsOnlineVoiceRoute -Identity "$Site1route" -NumberPattern ".*" -OnlinePstnGatewayList $SBCfqdn1 -Priority 1 -Description "Primary route for $PSTNusage1 Users"

# Creates backup route for first site using opposite site SBC / PSTN Gateway
New-CsOnlineVoiceRoute -Identity "$Site1route Backup" -NumberPattern ".*" -OnlinePstnGatewayList $SBCfqdn2 -Priority 2 -Description "Backup route (Via $PSTNusage2)  for $PSTNusage1 Users"

# Creates primary route for second site using local SBC / PSTN Gateway
New-CsOnlineVoiceRoute -Identity "$Site2route" -NumberPattern ".*" -OnlinePstnGatewayList $SBCfqdn2 -Priority 3 -Description "Primary route for $PSTNusage2 Users"

# Creates backup route for second site using opposite site SBC / PSTN Gateway
New-CsOnlineVoiceRoute -Identity "$Site2route Backup" -NumberPattern ".*" -OnlinePstnGatewayList $SBCfqdn1 -Priority 4 -Description "Backup route (Via $PSTNusage1)  for $PSTNusage2 Users"

#############################
# 5. Voice Routing Policy   #
#############################

# Creates Voice Routing Policy for first site 
New-CsOnlineVoiceRoutingPolicy "$PSTNusage1 Routing Policy" -OnlinePstnUsages $PSTNusage1 

# Creates Voice Routing Policy for second site 
New-CsOnlineVoiceRoutingPolicy "$PSTNusage2 Routing Policy" -OnlinePstnUsages $PSTNusage2 



write-host -foregroundcolor BLUE "Script is complete"
# Stop transcript report to text file
stop-transcript



