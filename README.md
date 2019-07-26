# Jamf Setup Constructor
This script help you configure the Jamf Setup app by creating the necessary extension attribute, smart groups, and App Configuration in Jamf Pro.

What is Jamf Setup?
----------
Jamf Setup is a wonderful iOS App that was released in Fall of 2018 for devices managed by Jamf Pro to be able to change the loadout of content that was scoped to those devices simply by opening the app and choosing a new "role" or "loadout". This allowed end users to easily change the content assigned to their devices.

The only downside to it is the configuration on the back end is still pretty involved; a Mobile Device Extension Attribute needs to be created with options in a pop up menu to specify the various "loadouts" that will be available to the end user. Then Smart Mobile Device Groups need to be created to find devices that are in each loadout so that you can scope things accordingly. Finally when configuring the Jamf Setup app itself in the Mobile Device Apps section, it needs a long and somewhat complicated XML snippet in the App Configuration tab to set a bunch of options.

So at best, if the Jamf Admin is highly knowledgeable, the configuration of Jamf Setup is tedious and slightly annoying. At worst; if the Jamf Admin doesn't have as high of a technical acumen, the task can be very intimidating and time consuming.

Jamf Setup Constructor
----------
That brings us to this script. The Jamf Setup Constructor will take care of the hard parts of getting everything set up, and all you need to do is provide the necessary information like what you would like to name the Extension Attribute and its options. The script will take care of creating it, creating all the necessary smart groups with the correct logic, and also generating the XML with your choices and putting it into the Jamf Setup App Configuration.

How To Use This Script
----------
1. The first thing you'll need to do is make sure you already have the Jamf Setup app added to your Mobile Device Apps page in Jamf Pro either through Apps and Books in Apple Business/School Manager (The artist formerly known as VPP), or through the Jamf Pro GUI in the Mobile Device Apps section. You'll need to configure the VPP and General tabs as well but leave the app unscoped for now and leave the App Configuration tab empty, the script will take care of filling that part out.

2. You'll need a special Jamf Pro User Account created for the Jamf Setup app to use. When your end users make a selection in Jamf Setup on their devices, an API call will be initiated and it will need to use that account for authentication. For security purposes it is recommended that a special account is created and used only for Jamf Setup with the minimum privileges necessary.<br>**For example:**<br>**Account Name:** jamfsetup<br>**Privileges:** "Update Mobile Devices Extension Attributes", "Update Mobile Devices", "Update Users"<br>The script will prompt you for the username and password of this account to add to the app config.

3. You'll also need a Jamf Pro User Account with admin privileges for the script to create everything. These credentials won't be saved anywhere so you can use a normal admin account. However, if you're concerned about security, a separate account can be made to use for this script and it will need the following privileges:<br>-Create, Read, and Update **Mobile Device Extension Attributes**<br>-Create, Read, and Update **Smart Mobile Device Groups**<br>-Read and Update **Mobile Device Applications**

4. You'll want to think and map out what you want to name the extension attribute and all of it's options. Here are some examples:<p>**Extension Attribute Name:** Loadout<br>**Options:** Classroom, Library Kiosks, Design iPads<p>**Extension Attribute Name:** Role<br>**Options:** Manager, Supervisor, Intern, Marketing Surveys, Maintenance<p>**Extension Attribute Name:** Hospital Roles<br>**Options:** Nurse, Patient, Administration
  
5. There are some optional configurations for you to change how the Jamf Setup app looks. You can leave the defaults set how they are, or you can change them if you want. The script will present you with this choice and if you choose to change them it will cycle through them individually.
![!](https://nation-cdn-resources.jamf.com/3d4ac144a6b946c3add11d578831beba "The default colors and text of Jamf Setup")
<br>This is what the app looks like by default. The text and colors can all be changed and colors must be entered in hexidecimal format. For help on finding these codes, I recommend https://htmlcolorcodes.com/#
Here are the default options:<br>**-Background Color** (Hexidecimal format, default: white)<br>**-Page Text Color** (Hexidecimal format, default: dark grey)<br>**-Button Color** (Hexidecimal format, default: seafoam green)<br>**-Button Text Color** (Hexidecimal format, default: white)<br>**-Header Image Logo** (Hosted URL path, default: Jamf Logo)<br>**-Main Page Title** (Text, default: Make a Selection)<br>**-Main Page Body Text** (Text, default: Select the appropriate role below, and then click Submit to configure your device)<br>**-Button Text** (Text, default: Submit)<br>**-Success Page Title** (Text, default: Success)<br>**-Success Page Body Text** (Text, default: You have selected $SELECTION. Press the home button or swipe up to begin using this device.)

Once the script has run, you will be able to find detailed logs in /Users/Shared/JamfSetupConstructorLogs.txt

What Next?
--------
So the script ran successfully and everything is all set up. What next?

Once everything is configured all you need to do is scope scope scope! First you'll need to scope the Jamf Setup app to whomever should get it. It might go to everyone, or it might only go to the "Newly Enrolled Devices". Or maybe only devices in certain roles should get it. For instance in the Healthcare example; maybe Nurses will get it so they can turn their devices to the "Patient" loadout if they need to, but then patients won't get it because we want to lock them into that setting. At that point the Jamf Reset app could be used to get the device back to its basic settings or the extension attribute could be manually changed from the General tab of the Inventory Record.

You'll want to also check out your Re-Enrollment settings if you'll be wiping devices often. In Settings/Global Management/Re-Enrollment Settings you'll find an option to **"Clear extension attribute values on computers and mobile devices"**. With this checked, that means when a device is wiped and re-enrolled, then the Extension Attribute will be set back to a blank value. Meaning if you're using the "Newly Enrolled Devices" option of the script, then devices that are re-enrolled will fall into that group again.

Lastly you'll just need to scope out your content to the appropriate smart groups created by the script.

Tips and Tricks
----------
**App Installation:** If your different loadouts will have different apps, try this. Instead of scoping those apps directly to the groups they belong to, scope them to all of the groups (including Newly Enrolled Devices) and then use configuration profiles to Restrict the apps that each loadout shouldn't have. This way, when a user switches into a new role, the apps will just show up, otherwise they'd have to wait up to 10 minutes for any newly scoped apps to install. Obviously this only works nicely on free apps unless you're okay with buying more paid apps than you really need as the apps will be installed on each device, only hidden by the configuration profile.

**Restrictions:** In multi-user scenarios, it is recommended that you have a restriction profile set to all of the devices with the following features disabled:<br>**- "Allow Erase All Content and Settings"<br>- "Allow modifying account settings"<br>- "Allow modifying passcode"<br>- "Allow modifying restrictions"<br>- "Allow modifying wallpaper"**

**Single App Mode:** An important consideration to take is whether or not one of the loadouts will have an app in single app mode, like a "Kiosk" option. This is a particular instance, as mentioned above, where you'll want the app that is set for Single App Mode to be installed on all groups and just hidden so that if someone switches over into kiosk mode then the app will already be there and you won't get a "Guided Access Error" while the app installs.

**Newly Enrolled Devices:** The script will give you the option to create a "Newly Enrolled Devices" smart group which comes in handy for an Out of Box scenario. The smart group looks for devices where the extension attribute is left blank which should be any new devices or re-enrolled devices. You could create a restriction configuration profile with the "Only Allow Some Apps" App Restriction and specify only "Jamf Setup" so that when a new device (or newly re-enrolled device) is turned on for the first time they will only see Jamf Setup and will need to choose a loadout before proceeding. And then once they choose the loadout, they will get all of their content.
