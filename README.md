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

PPPC!
--------
<br>![!](https://i.ibb.co/4FQtrRs/Screen-Shot-2019-07-26-at-10-48-19-AM.png "PPPC Prompt for Apple Events")
<br>Quick callout; When you run this script, depending on what version of macOS you're running you may get a prompt from our good friend PPPC asking you to allow Terminal (or the application you run the script from) access to Apple Events. This is because the script utilizes Apple Script to prompt you for information. You'll need to click allow in order for the script to run. If you don't want to keep this setting, then afterwards you can always open terminal and run 
<br><code>tccutil reset "AppleEvents"</code><br>
That will reset the Apple Events PPPC settings so that you'll be prompted the next time this software needs to access it.

How To Use This Script
----------
**This script needs to be run from a computer that is enrolled in Jamf Pro so it has access to Jamf Helper**

1. First off, you'll need an Admin account in Jamf Pro that can be used to make all of the things necessary. When you first run the script it will ask for your Jamf Pro URL and then the username and password for an Admin Account. That admin account needs AT LEAST the following privileges:<p>CREATE/READ/UPDATE on **Jamf Pro User Accounts and Groups**<br>READ/UPDATE on **Mobile Device Apps**<br>CREATE on **Mobile Device Extension Attributes**<br>CREATE on **Smart Mobile Device Groups**

2. Next thing you'll need to do is make sure you already have the Jamf Setup app added to your Mobile Device Apps page in Jamf Pro either through Apps and Books in Apple Business/School Manager (The artist formerly known as VPP), or through the Jamf Pro GUI in the Mobile Device Apps section. You'll need to configure the VPP and General tabs as well but leave the app unscoped for now and leave the App Configuration tab empty, the script will take care of filling that part out.

3. (A) This script will create a new Jamf Pro User Account called "jamfSetup" by default. The Jamf Setup app needs to use this account every time a user uses the app to change the loadout. It checks if the account already exists; if it doesn't it will create it with the minimum privileges needed for the Jamf Setup App to use it. If the account DOES exist, it will update the account's permission set to the minimum privileges necessary.

3. (B) The password for the jamfSetup account is the only thing that needs to be manually entered in the GUI just because of security reasons. It's impossible to use the API to put a password into an account. So I've programmed in two options. First, and probably most secure, you can choose to have the script generate a random 25 character alphanumeric string and copy it to your clipboard. At that point the script will tell you to stop and go to Jamf Pro to update the password in the newly created jamfSetup account before proceeding. Then when you come back to the prompt you can click the "TEST" button and it will test and make sure it can authenticate. If it can't, it will reprompt you and re-copy the password to your clipboard so that you can try to update the password again manually. On the flip side, you can choose to enter your own password as well. It will, again, pause and tell you to first go put that password in the jamfSetup account in Jamf Pro and it will prompt you to enter the password in the dialog as well so that it can test it and authenticate and add the password to the App Configuration for Jamf Setup.

4. You'll want to think and map out what you want to name the extension attribute and all of it's options. Here are some examples:<p>**Extension Attribute Name:** Loadout<br>**Options:** Classroom, Library Kiosks, Design iPads<p>**Extension Attribute Name:** Role<br>**Options:** Manager, Supervisor, Intern, Marketing Surveys, Maintenance<p>**Extension Attribute Name:** Hospital Roles<br>**Options:** Nurse, Patient, Pharmacist, Technician, Administration
  
5. There are some optional configurations for you to change how the Jamf Setup app looks. You can leave the defaults set how they are, or you can change them if you want. The script will present you with this choice and if you choose to change them it will cycle through them individually.
<br>![!](https://nation-cdn-resources.jamf.com/3d4ac144a6b946c3add11d578831beba "The default colors and text of Jamf Setup")
<br>This is what the app looks like by default. The text and colors can all be changed and colors must be entered in hexidecimal format. For help on finding these codes, I recommend https://htmlcolorcodes.com/#
Here are the default options:<br>**-Background Color** (Hexidecimal format, default-white: #F8F8F8)<br>**-Page Text Color** (Hexidecimal format, default-dark grey: #444444)<br>**-Button Color** (Hexidecimal format, default-seafoam green: #37BB9A)<br>**-Button Text Color** (Hexidecimal format, default-white: #F8F8F8)<br>**-Header Image Logo** (Hosted URL path, default: Jamf Logo)<br>**-Main Page Title** (Text, default: Make a Selection)<br>**-Main Page Body Text** (Text, default: Select the appropriate role below, and then click Submit to configure your device)<br>**-Button Text** (Text, default: Submit)<br>**-Success Page Title** (Text, default: Success)<br>**-Success Page Body Text** (Text, default: You have selected $SELECTION. Press the home button or swipe up to begin using this device.)

6. You might not see the newly created items immediately. Your browser will sometimes cache the current state of Jamf Pro and take a few minutes to update the interface. If it doesn't update after a few minutes, just clear your browser cache, log out of Jamf Pro and log back in.

Once the script has run, you will be able to find detailed logs in ~/Desktop/JamfSetupConstructorLogs.txt

Also if you're unfamiliar with HOW to run a script like this, simply download the JamfSetupConstructor.sh file, then open Terminal on a Mac that is enrolled in Jamf Pro. Simply drag the script onto the terminal window and hit enter to begin running it. You may see some verbose output in the terminal window, but you can just ignore it! Any necessary details will be found in the logs.

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

More information about the Jamf Setup app can be found here: https://www.jamf.com/jamf-nation/articles/535/configuring-and-deploying-the-jamf-setup-app
