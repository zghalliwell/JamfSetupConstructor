#!/bin/bash

##############################################################
#
# This script can be run to help an admin set up the Jamf Setup
# app within Jamf Pro. It will create the necessary Extension Attribute
# with as many options as you need, the appropriate smart groups, 
# and configure the Jamf Setup App with all of the settings you want.
#
###############
# YOU WILL NEED
###############
#
# Before running this script make sure you have the following dependencies in place!
# 1. You have a Jamf Pro Admin user account and password
# 2. The Jamf Setup app needs to already exist as an app record in Jamf Pro under Devices/Mobile Device Apps
# 3. The name you would like to give the extension attribute that determines the laodout for a device
# 4. All of the options you would like for different possible loadouts
# 5. The hexidecimal color codes for what you would like to be the background, text, and border colors(optional)
# 6. The URL of a hosted image to display when the app opens (optional)
# 7. Any messaging you would like to change (optional)
#
# Upon completion or failure, you can find the logs at ~/Desktop/JamfSetupConstructorLogs.txt
#
# Do not change anything below this line manually, the script will prompt you for input
#
#########
# LICENSE
#########
#
# MIT License
#
# Copyright (c) 2019 Zach Halliwell
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Created by Zach Halliwell
# https://github.com/zghalliwell
#
###############################################################

#########################################
# ESTABLISH STARTING VARIABLES AND ARRAYS
#########################################

#Do not manually edit these
jamfProURL=
initialAnswer=
adminUser=
adminPass=
adminRecord=
accountRecord=
privilegeVerify=
accountID=
setupUser="jamfSetup"
setupPass=
adminPrivileges=
passwordOption=
setupTest=
EAName=
EANameVerification=
EAOptions=()
EAOptionIndex=1
EAOptionName=
EAOptionVerification=
EAOptionCreateAnother=
EAConfirmationMessage=
messageIndex=
optionChoice=
optionalVerification=
EANumberOfOptions=
numberOfSmartGroups=
smartGroupChoice=
smartGroupName=
smartGroupNameArray=()
finalMessage=
finalMessageChoice=
EAindex=
smartGroupIndex=
EAXML=
smartGroupXML=()
smartGroupXMLindex=
appConfigOptions=
appConfig=
logPath=~/Desktop/JamfSetupConstructorLogs.txt
closingSelection=

#Optional Variable Defaults
backgroundColor="#F8F8F8"
pageTextColor="#444444"
buttonColor="#37BB9A"
buttonTextColor="#F8F8F8"
headerLogoURL="https://resources.jamf.com/images/logos/Jamf-color.png"
mainPageTitle="Make a Selection"
mainPageBody="Select the appropriate role below, and then click Submit to configure your device"
buttonText="Submit"
successPageTitle="Success"
successPageBody="You have selected: "'$SELECTION'". Press the home button or swipe up to begin using this device."

###########################################
# BEGINNING MESSAGE AND VARIABLE COLLECTION
###########################################

#Prompt the user with the prerequisites needed to run this script successfully and allow them to quit if they're not ready. If they quit, script will exit 0 and notate in logs

#Create Log File
echo "################################
# JAMF SETUP CONSTRUCTOR
################################
" >> $logPath
echo $(date) "Jamf Setup Constructor initiated, prompting user to make sure dependencies are in place..." >> $logPath

initialAnswer=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Welcome to The Jamf Setup Constructor!
_______________________________________

BEFORE PROCEEDING, YOU WILL NEED:
 1. You have a Jamf Pro Admin user account and password
 2. The Jamf Setup app needs to already exist as an app record in Jamf Pro under Devices/Mobile Device Apps
 3. The name you would like to give the extension attribute that determines the laodout for a device
 4. All of the options you would like for different possible loadouts
 5. The hexidecimal color codes for what you would like to be the background, text, and border colors(optional)
 6. The URL of a hosted image to display when the app opens (optional)
 7. Any messaging you would like to change (optional)

If you do not have these items necessary, hit Quit and gather them before proceeding." buttons {"Quit", "Proceed"} default button 2)')

#If the user clicks quit, stop the script immediately
if [[ $initialAnswer == "Quit" ]]; then
	echo $(date) "User chose to quit session, terminating..." >> $logPath
	exit 0
	fi

#Prompt the user for the URL of their Jamf Pro server
jamfProURL=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Please enter the URL of your Jamf Pro server" default answer "ex. https://my.jamf.pro" buttons {"OK"} default button 1)')
echo $(date) "Jamf Pro Server: $jamfProURL" >> $logPath

echo "
################################
# ACCOUNT VALIDATION AND JAMF SETUP USER CREATION
################################
" >> $logPath

##########################
# ADMIN ACCOUNT VALIDATION
##########################
#
# The admin account for Jamf Pro must have AT LEAST the following Privileges:
# -CREATE/READ/UPDATE on Jamf Pro User Accounts and Groups
# -READ/UPDATE on Mobile Device Apps
# -CREATE on Mobile Device Extension Attributes
# -CREATE on Smart Mobile Device Groups
#
# After proceeding, first prompt the user to enter admin credentials for their Jamf Pro server
adminUser=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Please enter the username of an ADMIN for your Jamf Pro server at '"$jamfProURL"'" default answer "" buttons {"OK"} default button 1)')
echo $(date) "Jamf Pro admin account to be used: $adminUser" >> $logPath

# Prompt for their admin password with hidden input
adminPass=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Please enter the password for admin user '"$adminUser"' for your Jamf Pro server at '"$jamfProURL"'" default answer "" buttons {"OK"} default button 1 with hidden answer)')

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType utility -title "Authenticating..." -description "Testing your credentials and privileges, please stand by..." -alignDescription center &

# The script will now verify the user's account has at least these privileges
echo $(date) "Checking to see if admin user $adminUser has the correct privileges..." >> $logPath
adminRecord=$(curl -su $adminUser:$adminPass $jamfProURL/JSSResource/accounts/username/$adminUser -H "Accept: text/xml" -X GET)
adminPrivileges=$(echo $adminRecord | xmllint --xpath '/account/privileges/jss_objects' -)

# Testing user's privileges to see if the necessary ones exist
if [[ $adminPrivileges == *"Read Mobile Device Applications"* ]] && [[ $adminPrivileges == *"Update Mobile Device Applications"* ]] && [[ $adminPrivileges == *"Create Mobile Device Extension Attributes"* ]] && [[ $adminPrivileges == *"Create Accounts"* ]] && [[ $adminPrivileges == *"Read Accounts"* ]] && [[ $adminPrivileges == *"Update Accounts"* ]] && [[ $adminPrivileges == *"Create Smart Mobile Device Groups"* ]]; then
	
	#Admin account has the necessary privileges needed, awesome!
	echo $(date) "Admin user $adminUser has all of the privileges necessary, continuing on..." >> $logPath
	else 
		echo $(date) "The admin user credentials that were entered do not meet all of the privelege requirements. Please log into Jamf Pro and give the account the following privileges:
	-CREATE/READ/UPDATE on Jamf Pro User Accounts and Groups
	-READ/UPDATE on Mobile Device Apps
	-CREATE on Mobile Device Extension Attributes
	-CREATE on Smart Mobile Device Groups
	Exiting script." >> $logPath
	
	#Inform the user that the account does not have proper privileges
	# Kill the Jamf Helper prompt that's telling them to wait
	pkill jamfHelper

	osascript -e 'tell application "System Events" to(display dialog "Your admin account does not have the correct privileges. Please log into Jamf Pro and give the account the following permissions:

	-CREATE/READ/UPDATE on Jamf Pro User Accounts and Groups
	-READ/UPDATE on Mobile Device Apps
	-CREATE on Mobile Device Extension Attributes
	-CREATE on Smart Mobile Device Groups" buttons {"OK"} default button 1)'
	exit 0
	fi
	
##########################
# JAMF SETUP USER CREATION
##########################
#
# The Jamf Setup app requires its own API account that it can use to change the loadout of devices
# when the user selects an option. This script will first check to see if the default 
# account exists in Settings/Jamf Pro User Accounts and Groups and if it doesn't, it will 
# create the account with the necessary privileges. If it does exist, it will give it the 
# correct privileges. It will then generate a random 25 character string to use as the password,
# this is the password that Jamf Setup will use to authenticate with that account. Once
# created, it will ask if you would like to copy that password to your clipboard to use OR 
# allow you to create your own password to use. It will then have you go into Jamf Pro and update
# the password on the default account that was created. To do so, go to 
# Settings/Jamf Pro User Accounts and Groups and click "jamfSetup" and update the password
# field with the randomly generated password that has been provided. The script will test
# if the password has been updated and won't proceed until it can validate that it can do so.

echo $(date) "JSC will now check if the $setupUser account exists in Jamf Pro or not..." >> $logPath

#First run an API command to see if the account exists and save the response in a variable and hide any errors that might
#come through if the account doesn't exist
accountVerify=$(curl -su $adminUser:$adminPass $jamfProURL/JSSResource/accounts/username/$setupUser -H "Accept: text/xml" -X GET | xmllint --xpath '/account/name/text()' - 2>/dev/null)

#Test to see if the account is created, if it's not created then create it with appropriate permissions
#If it is created, check its permissions and update them with the appropriate permissions if necessary

if [[ "$accountVerify" != "$setupUser" ]]; then
	#If the account doesn't exist, create it with permissions needed for API
	echo $(date) "Account $setupUser does not exist, creating..." >> $logPath
	outcome=$(curl -su $adminUser:$adminPass $jamfProURL/JSSResource/accounts/userid/0 -H "Content-type: application/xml" -X POST -d "<account>
	<name>$setupUser</name>
	<directory_user>false</directory_user>
	<full_name>API Service Account created on $(date) by $adminUser</full_name>
	<email/>
	<email_address/>
	<enabled>Enabled</enabled>
	<force_password_change>false</force_password_change>
	<access_level>Full Access</access_level>
	<privilege_set>Custom</privilege_set>
	<privileges>
		<jss_objects>
			<privilege>Update Mobile Device Extension Attributes</privilege>
			<privilege>Read Mobile Devices</privilege>
			<privilege>Update Mobile Devices</privilege>
			<privilege>Update User</privilege>
		</jss_objects>
		<jss_settings/>
		<jss_actions/>
		<recon/>
		<casper_admin/>
		<casper_remote/>
		<casper_imaging/>
	</privileges>
	</account>")
	outcomeFormatted=$(echo "$outcome" | xmllint --xpath '/account/id/text()' -)
	echo $(date) "The $setupUser account has been created at $jamfProURL with an ID of $outcomeFormatted" >> $logPath
	else 
		#If it does exist, check its permissions
		echo $(date) "Account already exists, checking permissions..." >> $logPath
		accountRecord=$(curl -su $adminUser:$adminPass $jamfProURL/JSSResource/accounts/username/$setupUser -H "Accept: text/xml" -X GET)
		privilegeVerify=$(echo $accountRecord | xmllint --xpath '/account/privileges/jss_objects' -)
		accountID=$(echo $accountRecord | xmllint --xpath '/account/id/text()' -)

		if [[ $privilegeVerify != *"Update Mobile Device Extension Attributes"* ]] || [[ $privilegeVerify != *"Update Mobile Devices"* ]] || [[ $privilegeVerify != *"Update User"* ]] || [[ $privilegeVerify != *"Read Mobile Devices"* ]]; then
			#If it has incorrect permissions, correct them
			echo $(date) "Account $setupUser doesn't have the correct permissions, updating to correct permission set" >> $logPath
			curl -su $adminUser:$adminPass $jamfProURL/JSSResource/accounts/userid/$accountID -H "Content-type: text/xml" -X PUT -d "<account><full_name>API Service Account updated on $(date) by $adminUser</full_name><privileges><jss_objects><privilege>Update Mobile Device Extension Attributes</privilege><privilege>Read Mobile Devices</privilege><privilege>Update Mobile Devices</privilege><privilege>Update User</privilege></jss_objects></privileges></account>"
			else
				echo $(date) "Account $setupUser has the correct permissions." >> $logPath
				fi
fi

##############################
# JAMF SETUP PASSWORD CREATION
##############################
# Now generate a random 25 character alphanumeric string to use as the password for the jamfSetup API account
# Once the password is generated, the user will be prompted to either copy that to their clipboard so they
# can enter it in the Jamf Pro GUI or they can choose to create their own password if they wish

#Generate a random 25-character alphanumeric string and save it in the setupPass variable
setupPass=$(perl -e '@c=("A".."Z","a".."z",0..9);$p.=$c[rand(scalar @c)] for 1..25; print "$p\n"')

# Kill the Jamf Helper prompt that's telling them to wait
pkill jamfHelper

#Prompt the user to ask them if they would like to use the randomly generated password or enter their own password
passwordOption=$(osascript -e 'tell application "System Events" to button returned of(display dialog "JSC has created a special API account for the Jamf Setup app to use in order for the app to actually be able to change the loadout of the devices. For security reasons, you will need to manually enter the password in the Jamf Pro GUI at 

Settings/Jamf Pro User Accounts and Groupds/'"$setupUser"'

To randomly generate a 25 character alphanumeric password, click the Copy to Clipbaord button below. To specify your own password, click Manually Enter Password." buttons {"Copy to Clipboard","Manually Enter Password"} default button 1)')
echo $(date) "User has selected $passwordOption..." >> $logPath

# If they selected to copy to clipboard, copy the random password to their clipboard and prompt them to go to jamf
# and enter it as the password for the jamfSetup user. If they opted to manually set it, prompt them to enter the 
# password they would like to use and again prompt them to enter it in jamf pro. With either option, validate that the
# account and password work before continuing.

if [[ $passwordOption == "Copy to Clipboard" ]]; then
	echo $(date) "Copying password to clipboard" >> $logPath
	echo $setupPass | pbcopy
	osascript -e 'tell application "System Events" to button returned of(display dialog "STOP!

The password has been copied to your clipboard. At this moment, pause for a second and go log into Jamf Pro. Go into Settings/Jamf Pro User Accounts and Groups and find the '"$setupUser"' user that was created. When you edit that user, paste the password into both of the password fields on that user account.

When you have SAVED and finished, click TEST below.

(If you accidentally lost what was on your clipboard, just hit TEST anyway, when it fails it will re-copy the password to your clipboard and prompt you to test again.)" buttons {"TEST"} default button 1)'
	
	#test out the credentials with a simple read API call to make sure it can authenticate
	testCall=$(curl -su $setupUser:$setupPass $jamfProURL/JSSResource/mobiledevices -H "Accept: text/xml" -X GET | xmllint --xpath '/mobile_devices/size/text()' -)
	
	#If it returns a number, that means the call succeeded
	if [[ $testCall > 0 ]] || [[ $testCall == 0 ]]; then
		setupTest="Successful"
		echo $(date) "The test call succeeded" >> $logPath
		else
			echo $(date) "The test call failed. Trying again" >> $logPath
		fi
		
	while [[ $setupTest != "Successful" ]]; do
		echo $setupPass | pbcopy
		osascript -e 'tell application "System Events" to button returned of(display dialog "Authentication Failed 
		
The password has been copied to your clipboard again. At this moment, pause for a second and go log into Jamf Pro. Go into Settings/Jamf Pro User Accounts and Groups and find the '"$setupUser"' user that was created. When you edit that user, paste the password into both of the password fields on that user account.

When you have SAVED and finished, click TEST below.

(If you accidentally lost what was on your clipboard, just hit TEST anyway, when it fails it will re-copy the password and prompt you to test again.)" buttons {"TEST"} default button 1)'
		
		#test out the credentials with a simple read API call to make sure it can authenticate
		testCall=$(curl -su $setupUser:$setupPass $jamfProURL/JSSResource/mobiledevices -H "Accept: text/xml" -X GET | xmllint --xpath '/mobile_devices/size/text()' -)
		
		#If it returns a number, that means the call succeeded
		if [[ $testCall > 0 ]] || [[ $testCall == 0 ]]; then
				setupTest="Successful"
				echo $(date) "The test call succeeded" >> $logPath
				else
					echo $(date) "The test call failed. Trying again" >> $logPath
				fi
				done
	else
		echo $(date) "User chose to enter their own password, prompting them to enter it." >> $logPath
		#Prompt the user to enter a password, update the account in Jamf Pro and then hit test to test it out
	setupPass=$(osascript -e 'tell application "System Events" to text returned of (display dialog "FIRST log into Jamf Pro and go to Settings/Jamf Pro User Accounts and Groups and select the account '"$setupUser"' and set the password for that account how you want it. 
	
Make sure to SAVE and then return to this dialog and enter the password in the box below and hit TEST." default answer "ENTER PASSWORD HERE" buttons {"TEST"} default button 1 with hidden answer)')
		
	#test out the credentials with a simple read API call to make sure it can authenticate
	 testCall=$(curl -su $setupUser:$setupPass $jamfProURL/JSSResource/mobiledevices -H "Accept: text/xml" -X GET | xmllint --xpath '/mobile_devices/size/text()' -)
			
			#If it returns a number, that means the call succeeded
			if [[ $testCall > 0 ]] || [[ $testCall == 0 ]]; then
				setupTest="Successful"
				echo $(date) "The test call succeeded" >> $logPath
				else
					echo $(date) "The test call failed. Trying again" >> $logPath
				fi
				
			while [[ $setupTest != "Successful" ]]; do
				setupPass=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Authentication Failed

FIRST log into Jamf Pro and go to Settings/Jamf Pro User Accounts and Groups and select the account '"$setupUser"' and set the password for that account how you want it. 

SAVE and then return to this dialog and enter the password in the box below and hit TEST." default answer "ENTER PASSWORD HERE" buttons {"TEST"} default button 1 with hidden answer)')
				
				#test out the credentials with a simple read API call to make sure it can authenticate
				testCall=$(curl -su $setupUser:$setupPass $jamfProURL/JSSResource/mobiledevices -H "Accept: text/xml" -X GET | xmllint --xpath '/mobile_devices/size/text()' -)
				
				#If it returns a number, that means the call succeeded
				if [[ $testCall > 0 ]] || [[ $testCall == 0 ]]; then
						setupTest="Successful"
						echo $(date) "The test call succeeded" >> $logPath
						else
							echo $(date) "The test call failed. Trying again" >> $logPath
						fi
						done
	fi

#Test to see if the Jamf Setup app exists as an app record and save it's ID as a variable
jamfSetupID=$(curl -su $adminUser:$adminPass $jamfProURL/JSSResource/mobiledeviceapplications/name/Jamf%20Setup -H "Accept: text/xml" -X GET | xmllint --xpath '/mobile_device_application/general/id/text()' -)

if [[ $jamfSetupID > 0 ]] && [[ $jamfSetupID < 99999999999999 ]]; then
	echo $(date) "Jamf Setup app exists as Mobile Device App record with ID $jamfSetupID" >> $logPath
	else
		echo $(date) "Error: $jamfSetupID
		
		exiting..." >> $logPath
		osascript -e 'tell application "System Events" to (display dialog "There was an error attempting to verify the Jamf Setup app exists in your Mobile Device Apps section of Jamf Pro.
		
		Error: '"$jamfSetupID"'
		
		The script will now exit." buttons {"OK"} default button 1)'
		exit 0
		fi
		
echo $(date) "Preliminary information gathered. Continuing on with Extension Attribute Setup...

################################
# EXTENSION ATTRIBUTE SETUP
################################
" >> $logPath

###########################
# EXTENSION ATTRIBUTE SETUP
###########################

#Prompt the user to name the Extension Attribute that will be created
EAName=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Constructor will need to create a Mobile Device Extension Attribute in Jamf Pro to use to determine which loadout a device should get. What would you like to name this Extension Attribute? (ex. Loadout, Subdepartment, Role, etc.)" default answer "Loadout" buttons {"OK"} default button 1)')

echo $(date) "User entered $EAName as the name for the extension attribute." >> $logPath

#Have the user verify the name
EANameVerification=$(osascript -e 'tell application "System Events" to button returned of (display dialog "You have chosen to name your Mobile Device Extension Attribute:

'"$EAName"'

Is this correct?" buttons {"Yes", "No, Rename..."} default button 1)')
echo $(date) "Requesting user verify entry..." >> $logPath

#Use a while loop to let them reset the EA Name if need be
while [[ $EANameVerification != "Yes" ]]; do
	
	#Rename the EAName variable
	echo $(date) "User requested to re-enter the name" >> $logPath
	EAName=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Re-enter the name for the Extension Attribute (ex. Loadout, Subdepartment, Role, etc.)" default answer "$EAName" buttons {"OK"} default button 1)')
	
	#Have the user verify the name
	echo $(date) "Requesting user verify re-entry..." >> $logPath
	EANameVerification=$(osascript -e 'tell application "System Events" to button returned of (display dialog "You have chosen to name your Mobile Device Extension Attribute:

'"$EAName"'

Is this correct?" buttons {"Yes", "No, Rename..."} default button 1)')
	done
echo $(date) "Extension Attribute successfully named $EAName" >> $logPath

#Explain to the user what the next step will entail for creating options for the Extension Attribute Dropdown
osascript -e 'tell application "System Events" to (display dialog "Next we will create options for your '"$EAName"' Extension Attribute. These will be the options that are displayed on the Jamf Setup screen for a user to choose from to decide what kind of loadout the device should receive. 

You will be prompted to add as many options as you would like and once you are finished we will proceed with the optional steps." buttons {"OK"} default button 1)'

echo $(date) "Requesting user enter options for the Extension Attribute and verify their entries..." >> $logPath

while [[ $EAOptionIndex != 0 ]]; do
	
	#Prompt the user to enter the name of the EA Option to create
	EAOptionName=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Please enter the name for Option '"$EAOptionIndex"' of your '"$EAName"' Extension Attribute" default answer "" buttons {"OK"} default button 1)')
	
	#Have user verify their entry
	EAOptionVerification=$(osascript -e 'tell application "System Events" to button returned of (display dialog "You entered:

'"$EAOptionName"'

Is this correct?" buttons {"Yes", "No, try again..."} default button 1)')
	
	#Re-enter the name if need be
	while [[ $EAOptionVerification != "Yes" ]]; do
		
		#Rename the Option
		EAOptionName=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Please enter the name for Option '"$EAOptionIndex"' of your '"$EAName"' Extension Attribute" default answer "" buttons {"OK"} default button 1)')
		
		#Have user verify their entry
		EAOptionVerification=$(osascript -e 'tell application "System Events" to button returned of (display dialog "You entered:

'"$EAOptionName"'

Is this correct?" buttons {"Yes", "No, try again..."} default button 1)')
		done
		
	#Once verified, add the option to the EAOptions Array
	EAOptions+=( "$(echo $EAOptionName)" )
	echo "	$EAOptionName has been added as an option for the Extension Attribute." >> $logPath
	
	#Ask the user if they have more options to enter
	EAOptionCreateAnother=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Option created! Would you like to create another option?" buttons {"Yes", "No"} default button 1)')
	
	#If they select yes to create another, continue the loop, if they select no, move on
	if [[ $EAOptionCreateAnother == "Yes" ]]; then
		EAOptionIndex=$(($EAOptionIndex+1))
		else
			EAOptionIndex=0
			fi
done
	
#Create a count of the number of options and an index to reference the array
EANumberOfOptions=$(echo "${#EAOptions[@]}")
EAindex=$(($EANumberOfOptions-1))
numberOfSmartGroups=$EANumberOfOptions

echo $(date) "$EANumberOfOptions options created." >> $logPath

#Build a message to show the user what has been created so far
EAConfirmationMessage="A Mobile Device Extension Attribute named $EAName will be created with $EANumberOfOptions options named:
"
messageIndex=0
for i in $(seq 0 $EAindex); do
	EAConfirmationMessage="$EAConfirmationMessage
	${EAOptions[$i]}"
	messageIndex=$(($messageIndex+1))
	done

#Display the message before moving on so the user can see what they've gotten set to be created so far
osascript -e 'tell application "System Events" to (display dialog "Brilliant!

'"$EAConfirmationMessage"'

NOTE: Nothing has been created in Jamf Pro so far, please proceed to finish Construction." buttons {"Proceed"} default button 1)'

echo $(date) "$EAConfirmationMessage
" >> $logPath
echo $(date) "Extension attribute section completed. Starting Optional Configurations

################################
# OPTIONAL CONFIGURATIONS
################################
" >> $logPath

#########################
# OPTIONAL CONFIGURATIONS
#########################

#Display a message to the user informing them of the options they can change and give them the option to keep the defaults or change them
#If they select Keep Defaults, this section will be skipped and default values will be placed in the App Config for the Jamf Setup App
#Even if options are skipped and defaults are kept, they can still change these options later in the App Config itself

optionChoice=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Next we will set up some optional configurations. All of these can be left to their defaults if you desire and later they can be changed in the App Configuration tab of the Jamf Setup mobile device app record within Jamf Pro. The options we can change are:

-Background Color (Hexidecimal format, default: white)
-Page Text Color (Hexidecimal format, default: dark grey)
-Button Color (Hexidecimal format, default: seafoam green)
-Button Text Color (Hexidecimal format, default: white)
-Header Image Logo (Hosted URL path, default: Jamf Logo)
-Main Page Title (Text, default: Make a Selection)
-Main Page Body Text (Text, default: Select the appropriate role below, and then click Submit to configure your device)
-Button Text (Text, default: Submit)
-Success Page Title (Text, default: Success)
-Success Page Body Text (Text, default: You have selected $SELECTION. Press the home button or swipe up to begin using this device.)

If you want to keep these defaults for now or change them at a later time, click Keep Defaults.
If you want to make changes to these now, select Change." buttons {"Keep Defaults", "Change"} default button 2)')

if [[ $optionChoice == "Change" ]]; then
	echo $(date) "User selected to change the options; barrage of prompts ensuing..." >> $logPath
	#Prompt the user for each option and what they would like to change it to, verify each option they enter to make sure they enter them correctly
	backgroundColor=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Background Color" default answer "#F8F8F8" buttons {"NEXT"} default button 1)')
	pageTextColor=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Page Text Color" default answer "#444444" buttons {"NEXT"} default button 1)')
	buttonColor=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Button Color" default answer "#37BB9A" buttons {"NEXT"} default button 1)')
	buttonTextColor=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Button Text Color" default answer "#F8F8F8" buttons {"NEXT"} default button 1)')
	headerLogoURL=$(osascript -e 'tell application "System Events" to text returned of (display dialog "URL of Hosted Image to be used as logo on the main page" default answer "https://resources.jamf.com/images/logos/Jamf-color.png" buttons {"NEXT"} default button 1)')
	mainPageTitle=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Main Page Title Text" default answer "Make a Selection" buttons {"NEXT"} default button 1)')
	mainPageBody=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Main Page Body Text" default answer "Select the appropriate role below, and then click Submit to configure your device" buttons {"NEXT"} default button 1)')
	buttonText=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Button Text" default answer "Submit" buttons {"NEXT"} default button 1)')
	successPageTitle=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Success Page Title Text" default answer "Success" buttons {"NEXT"} default button 1)')
	successPageBody=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Success Page Body Text" default answer "You have selected: $SELECTION. Press the home button or swipe up to begin using this device." buttons {"NEXT"} default button 1)')
	optionalVerification=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Here are the options you have set, please double check!
	
-BackGround Color: '"$backgroundColor"'
-Page Text Color: '"$pageTextColor"'
-Button Color: '"$buttonColor"'
-Button Text Color: '"$buttonTextColor"'
-Main Page Header Image URL: '"$headerLogoURL"'
-Main Page Title: '"$mainPageTitle"'
-Main Page Body: '"$mainPageBody"'
-Button Text: '"$buttonText"'
-Success Page Title: '"$successPageTitle"'
-Success Page Body: '"$successPageBody"'
	
If these look correct, hit Continue.
If you need to make a change, hit Change." buttons {"Continue", "Change"} default button 1)')
	
	while [[ $optionalVerification != "Continue" ]]; do
		backgroundColor=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Background Color" default answer "'"$backgroundColor"'" buttons {"NEXT"} default button 1)')
		pageTextColor=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Page Text Color" default answer "'"$pageTextColor"'" buttons {"NEXT"} default button 1)')
		buttonColor=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Button Color" default answer "'"$buttonColor"'" buttons {"NEXT"} default button 1)')
		buttonTextColor=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Button Text Color" default answer "'"$buttonTextColor"'" buttons {"NEXT"} default button 1)')
		headerLogoURL=$(osascript -e 'tell application "System Events" to text returned of (display dialog "URL of Hosted Image to be used as logo on the main page" default answer "'"$headerLogoURL"'" buttons {"NEXT"} default button 1)')
		mainPageTitle=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Main Page Title Text" default answer "'"$mainPageTitle"'" buttons {"NEXT"} default button 1)')
		mainPageBody=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Main Page Body Text" default answer "'"$mainPageBody"'" buttons {"NEXT"} default button 1)')
		buttonText=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Button Text" default answer "'"$buttonText"'" buttons {"NEXT"} default button 1)')
		successPageTitle=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Success Page Title Text" default answer "'"$successPageTitle"'" buttons {"NEXT"} default button 1)')
		successPageBody=$(osascript -e 'tell application "System Events" to text returned of (display dialog "Success Page Body Text" default answer "'"$successPageBody"'" buttons {"NEXT"} default button 1)')
		optionalVerification=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Here are the options you have set, please double check!
			
-BackGround Color: '"$backgroundColor"'
-Page Text Color: '"$pageTextColor"'
-Button Color: '"$buttonColor"'
-Button Text Color: '"$buttonTextColor"'
-Main Page Header Image URL: '"$headerLogoURL"'
-Main Page Title: '"$mainPageTitle"'
-Main Page Body: '"$mainPageBody"'
-Button Text: '"$buttonText"'
-Success Page Title: '"$successPageTitle"'
-Success Page Body: '"$successPageBody"'
			
If these look correct, hit Continue.
If you need to make a change, hit Change." buttons {"Continue", "Change"} default button 1)')
	done
fi

#Report back to logs the details of the options chosen or the default options
echo $(date) "Jamf Setup will be formatted with the following options:
-BackGround Color: '"$backgroundColor"'
-Page Text Color: '"$pageTextColor"'
-Button Color: '"$buttonColor"'
-Button Text Color: '"$buttonTextColor"'
-Main Page Header Image URL: '"$headerLogoURL"'
-Main Page Title: '"$mainPageTitle"'
-Main Page Body: '"$mainPageBody"'
-Button Text: '"$buttonText"'
-Success Page Title: '"$successPageTitle"'
-Success Page Body: '"$successPageBody"'

################################
# SMART GROUP SETUP
################################

Initiating Smart Group Section
" >> $logPath

##############
# SMART GROUPS
##############

#Have the user select whether or not they want an extra smart group created for Newly Assigned Devices 
smartGroupChoice=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Smart Groups

Scoping with the use of Jamf Setup requires Smart Mobile Device Groups to be created for each one of the loadout options that can be selected in your Extension Attribute. Constructor will create these smart groups for you with one of two options:

OPTION 1: Include a Newly Enrolled Devices Group
-This option allows an extra smart group to be created that can define Newly Enrolled Devices where the end user has not yet opened Jamf Setup and selected a loadout. This is helpful for new out of box deployments (or recently wiped devices) where you might want to have an empty Home Screen with just the Jamf Setup app displayed so the user can select a loadout to then receive the content provisioned for them.

OPTION 2: Only include smart groups for the different options
-This option is if you do not plan on having an out of box experience with Jamf Setup, and just want smart groups based on the extension attribute value.

Which Option Would You Prefer?" buttons {"Option 1", "Option 2"} default button 1)')

#If they select Option 1 to create the "Newly Enrolled Devices" group, add 1 to the number of Smart Groups and subtract 2 for the index to target the correct array container
#If they select Option 2 then just subtract 1 to create the index to point at the correct array container
if [[ $smartGroupChoice == "Option 1" ]]; then
	numberOfSmartGroups=$(($numberOfSmartGroups+1))
	smartGroupIndex=$(($numberOfSmartGroups-2))
	echo $(date) "Option 1 selected; an extra group called JSC_Newly Enrolled Devices will be created" >> $logPath
	else
		smartGroupIndex=$(($numberOfSmartGroups-1))
		echo $(date) "Option 2 selected; smart groups will only be made to correspond with the Extension Attribute Options" >> $logPath
fi
	
#Build Smart Group Names
#Generate array of names based off of the options in the Extension Attribute
for i in $(seq 0 $EAindex); do
	#add EA name to template
	smartGroupName="JSC_${EAOptions[$i]}"
	
	#add to smart group name array 
	smartGroupNameArray+=( "$smartGroupName" )
done

echo $(date) "Smart group section completed.

################################
# FINAL USER CONFIRMATION
################################
" >> $logPath

####################
# FINAL CONFIRMATION
####################

#Build a final message telling the user everything that will be built and give them one last chance to back out 
finalMessage="Alright! We have got everything we need!
Time to confirm it all!

JAMF PRO SERVER ADDRESS
$jamfProURL

ADMIN ACCOUNT
The Jamf Pro user that this script will use to make these changes is: $adminUser

SETUP ACCOUNT
The Jamf Pro user that Jamf Setup will use is: $setupUser

EXTENSION ATTRIBUTE
$EAConfirmationMessage

SMART GROUPS
A total of $numberOfSmartGroups smart mobile device groups will be created with the following names:
"
	
#Add smart group names to message
for i in $(seq 0 $smartGroupIndex); do
	finalMessage="$finalMessage
	${smartGroupNameArray[$i]}"
	done
	
#If they selected Option 1, add that smart group to the displayed list
if [[ $smartGroupChoice == "Option 1" ]]; then
	finalMessage="$finalMessage
	JSC_Newly Enrolled Devices"
	fi

#If they changed the default optional values, display those as well
if [[ $optionChoice == "Change" ]]; then
	finalMessage="$finalMessage
	
OPTIONAL CHANGES
The following optional values have been changed from their defaults:
-BackGround Color: $backgroundColor
-Page Text Color: $pageTextColor
-Button Color: $buttonColor
-Button Text Color: $buttonTextColor
-Main Page Header Image URL: $headerLogoURL
-Main Page Title: $mainPageTitle
-Main Page Body: $mainPageBody
-Button Text: $buttonText
-Success Page Title: $successPageTitle
-Success Page Body: $successPageBody"
	else
		finalMessage="$finalMessage
		
OPTIONAL CHANGES
You chose to keep the defaults for the optional values.
These can be changed later within the App Configuration tab of the Jamf Setup Mobile Device App record."
fi

#Finish message
finalMessage="$finalMessage

If these settings all look correct, hit PROCEED to initiate construction.
If these settings look wrong in any way, hit ABORT to cancel."

#Display message to user
finalMessageChoice=$(osascript -e 'tell application "System Events" to button returned of (display dialog "'"$finalMessage"'" buttons {"PROCEED", "ABORT"} default button 1)')

echo $(date) "The following confirmation message was displayed to user:

$finalMessage
" >> $logPath

#If they hit abort, exit 0
if [[ $finalMessageChoice == "ABORT" ]]; then
	echo $(date) "User chose to abort session session" >> $logPath
	closingSelection=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Session cancelled manually.
	
	Click "View Logs" to view more information." buttons {"Close","View Logs"} default button 1)')

	if [[ $closingSelection == "View Logs" ]]; then
		open -a TextEdit.app "$logPath"
		exit 0
	fi
	exit 0
fi

echo $(date) "Information gathering done, user has selected to proceed, initiating construction of assets..

################################
# CREATION OF ASSETS IN JAMF PRO
################################
" >> $logPath

################################
# CREATION OF ASSETS IN JAMF PRO
################################

#Launch a Jamf Helper window to let the user know it's working
echo $(date) "Launching Jamf Helper to let the user know to wait..." >> $logPath
"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType utility -title "Constructing..." -description "Please wait while we make some Jamf magic happen..." -alignDescription center &

echo "
################################
# CONSTRUCT EXTENSION ATTRIBUTE AND OPTIONS
################################
" >> $logPath

###############################
# CONSTRUCT EXTENSION ATTRIBUTE
###############################

echo $(date) "Building the $EAName Extension Attribute..." >> $logPath
#Build the XML to place the options in the extension attribute at the time of creation
for i in $(seq 0 $EAindex); do
	EAXML="$EAXML<choice>${EAOptions[$i]}</choice>"
	name=${EAOptions[$i]}
	echo "Option created: $name" >> $logPath
done

currentDateTime=$(date)

echo $(date) "Sending API call to create Extension Attribute..." >> $logPath
#Use the API to create the extension attribute with the selected choices in the popup menu
EAid=$(curl -su $adminUser:$adminPass $jamfProURL/JSSResource/mobiledeviceextensionattributes/id/0 -H "Content-type: text/xml" -X POST -d "<mobile_device_extension_attribute><name>$EAName</name><description>Made with Jamf Setup Constructor by user $adminUser on $currentDateTime</description><data_type>String</data_type><input_type><type>Pop-up Menu</type><popup_choices>$EAXML</popup_choices></input_type><inventory_display>General</inventory_display></mobile_device_extension_attribute>")
EAidFormatted=$(echo $EAid | xmllint --xpath '/mobile_device_extension_attribute/id/text()' -)

if [[ $EAidFormatted > 0 ]] && [[ $EAidFormatted < 999999999 ]]; then
	echo $(date) "Extension Attribute with the name $EAName has been created with ID number $EAidFormatted" >> $logPath
	else
		echo $(date) "Error: $EAid" >> $logPath
		echo "Due to error, script will now exit" >> $logPath
		closingSelection=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Due to an error the script has been cancelled.
		
		Error: "'$EAid'"
		
		Click "View Logs" to view more information." buttons {"Close","View Logs"} default button 1)')

		if [[ $closingSelection == "View Logs" ]]; then
			open -a TextEdit.app "$logPath"
			exit 0
		fi
		exit 0
fi

echo $(date) "Extension Attribute construction finished, moving on to Smart Groups...

################################
# CREATION OF SMART GROUPS
################################
" >> $logPath

########################
# CONSTRUCT SMART GROUPS
########################

echo $(date) "Building XML..." >> $logPath
#Build an array containing the proper XML for each Smart Group that needs to be created
for i in $(seq 0 $EAindex); do
	smartGroupXML+=( "<name>${smartGroupNameArray[$i]}</name><is_smart>true</is_smart><criteria><criterion><name>$EAName</name><priority>0</priority><and_or>AND</and_or><search_type>is</search_type><value>${EAOptions[$i]}</value><opening_paren>false</opening_paren><closing_paren>false</closing_paren></criterion><criterion><name>Model</name><priority>1</priority><and_or>AND</and_or><search_type>not like</search_type><value>TV</value><opening_paren>false</opening_paren><closing_paren>false</closing_paren></criterion></criteria>" )
done

#If they selected Option 1, add the "Newly Enrolled Devices smart group to the XML array
if [[ $smartGroupChoice == "Option 1" ]]; then
	
	criterionIndex=$(($EAindex+1))
	#Use a for loop to add each of the possible options as "not like" criteria in the smart group XML
	for i in $(seq 0 $EAindex); do
	newSmartGroupCriteria="$newSmartGroupCriteria<criterion><name>$EAName</name><priority>$i</priority><and_or>AND</and_or><search_type>not like</search_type><value>${EAOptions[$i]}</value><opening_paren>false</opening_paren><closing_paren>false</closing_paren></criterion>"
	done
	
	echo $(date) "Adding extra smart group since Option 1 was selected..." >> $logPath
	#Add the name of the new smart group to the end of the array
	smartGroupNameArray+=( "JSC_Newly Enrolled Devices" )
	
	#Once all of the criteria is added to the XML, add the whole thing to the end of the Smart Group XML array
	#Create a variable to pinpoint the next open priority slot
	lastPrioritySlot=$(($EAindex+1))
	smartGroupXML+=( "<name>JSC_Newly Enrolled Devices</name><is_smart>true</is_smart><criteria>$newSmartGroupCriteria<criterion><name>Model</name><priority>$lastPrioritySlot</priority><and_or>AND</and_or><search_type>not like</search_type><value>TV</value><opening_paren>false</opening_paren><closing_paren>false</closing_paren></criterion></criteria>" )
fi
	
#Count the total number of smart groups to be created
smartGroupXMLindex=$(echo "${#smartGroupXML[@]}")

#Subtract 1 to be able to use the indext to target array containers
smartGroupXMLindex=$(($smartGroupXMLindex-1))
	
#Use a loop to create API calls to create all of the smart groups in the array
for i in $(seq 0 $smartGroupXMLindex); do
	SGid=$(curl -su $adminUser:$adminPass $jamfProURL/JSSResource/mobiledevicegroups/id/0 -H "Content-type: text/xml" -X POST -d "<mobile_device_group>${smartGroupXML[$i]}</mobile_device_group>")
	SGidFormatted=$(echo $SGid | xmllint --xpath '/mobile_device_group/id/text()' -)

	if [[ $SGidFormatted > 0 ]] && [[ $SGidFormatted < 999999999 ]]; then
		echo $(date) "Smart Group with the name ${smartGroupNameArray[$i]} has been created with ID number $SGidFormatted" >> $logPath
		else
			echo $(date) "Error: $SGid" >> $logPath
			echo "Due to error, script will now exit" >> $logPath
			closingSelection=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Due to an error the script has been cancelled.
			
			Error: "'$SGid'"
			
			Click "View Logs" to view more information." buttons {"Close","View Logs"} default button 1)')

			if [[ $closingSelection == "View Logs" ]]; then
				open -a TextEdit.app "$logPath"
				exit 0
			fi
			exit 0
	fi
done
echo "Smart groups successfully created, moving on to App Configuration...

################################
# CREATION OF APP CONFIGURATION IN JAMF PRO
################################
" >> $logPath

#########################
# APP CONFIG CONSTRUCTION
#########################

#Build out the options to put into the app config
echo $(date) "Building out app configuration for Jamf Setup app..." >> $logPath
#Put first value in the variable
appConfigOptions="&lt;string&gt;${EAOptions[0]}&lt;/string&gt;&#13;"

for i in $(seq 1 $EAindex); do
	appConfigOptions="$appConfigOptions
						&lt;string&gt;${EAOptions[$i]}&lt;/string&gt;&#13;"
done

#Build out the rest of the app config
appConfig="<app_configuration><preferences>&lt;dict&gt;&#13;
		 &lt;key&gt;com.jamf.config.jamfpro.url&lt;/key&gt;&#13;
		 &lt;string&gt;$jamfProURL&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.jamfpro.username&lt;/key&gt;&#13;
		 &lt;string&gt;$setupUser&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.jamfpro.password&lt;/key&gt;&#13;
		 &lt;string&gt;$setupPass&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.jamfpro.device-id&lt;/key&gt;&#13;
		 &lt;string&gt;"'$JSSID'"&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.setup.extension-attribute.name&lt;/key&gt;&#13;
		 &lt;string&gt;$EAName&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.setup.extension-attribute.options&lt;/key&gt;&#13;
				  &lt;array&gt;&#13;
						$appConfigOptions
				  &lt;/array&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.header-image.url&lt;/key&gt;&#13;
		 &lt;string&gt;$headerLogoURL&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.main-page.title&lt;/key&gt;&#13;
		 &lt;string&gt;$mainPageTitle&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.main-page.text&lt;/key&gt;&#13;
		 &lt;string&gt;$mainPageBody&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.text.color&lt;/key&gt;&#13;
		 &lt;string&gt;$pageTextColor&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.main-page.button.text&lt;/key&gt;&#13;
		 &lt;string&gt;$buttonText&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.main-page.button.color&lt;/key&gt;&#13;
		 &lt;string&gt;$buttonColor&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.main-page.button.text.color&lt;/key&gt;&#13;
		 &lt;string&gt;$buttonTextColor&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.success-page.title&lt;/key&gt;&#13;
		 &lt;string&gt;$successPageTitle&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.success-page.text&lt;/key&gt;&#13;
		 &lt;string&gt;$successPageBody&lt;/string&gt;&#13;
		 &lt;key&gt;com.jamf.config.ui.background.color&lt;/key&gt;&#13;
		 &lt;string&gt;$backgroundColor&lt;/string&gt;&#13;
&lt;/dict&gt;</preferences></app_configuration>"

#Add the app configuration to the app record
appID=$(curl -su $adminUser:$adminPass $jamfProURL/JSSResource/mobiledeviceapplications/id/$jamfSetupID -H "Content-type: text/xml" -X PUT -d "<mobile_device_application>$appConfig</mobile_device_application>")
appIDFormatted=$(echo $appID | xmllint --xpath '/mobile_device_application/id/text()' -)

	if [[ $appIDFormatted > 0 ]] && [[ $appIDFormatted < 999999999 ]]; then
		echo $(date) "App Config for Jamf Setup has been successfully updated" >> $logPath
		else
			echo $(date) "Error: $appID" >> $logPath
			echo "Due to error, script will now exit" >> $logPath
			
			closingSelection=$(osascript -e 'tell application "System Events" to button returned of (display dialog "Due to an error the script has been cancelled.
			
			Error: "'$appID'"
			
			Click "View Logs" to view more information." buttons {"Close","View Logs"} default button 1)')

			if [[ $closingSelection == "View Logs" ]]; then
				open -a TextEdit.app "$logPath"
				exit 0
			fi
			exit 0
	fi

echo "Everything has been successfully created! Enjoy your new Jamf Setup experience!

###########################################
# SUCCESS!!! BRING IN THE DANCING LOBSTERS!
###########################################
" >> $logPath

#Kill the jamf helper window that's telling the user to wait
pkill jamfHelper

closingSelection=$(osascript -e 'tell application "System Events" to button returned of (display dialog "All finished! Your Jamf Pro server should now be configured with the proper extension attribute and corresponding smart groups and app configuration!

Note: You might not see everything that was created right away because of your browsers cache. If you do not see your extension attribute or smart groups, just wait a few minutes or clear your browser cache and refresh the page.

 For details on what all happened, you can find the logs at '"$logPath"'" buttons {"Close","View Logs"} default button 1)')

if [[ $closingSelection == "View Logs" ]]; then
	open -a TextEdit.app "$logPath"
	exit 0
	else
		exit 0
fi
