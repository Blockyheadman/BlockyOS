# The Desktop

## Sections
- [Introduction](#introduction)
- [Setup](#setup)
    - [Variables & Signals](#variables--singals)
    - [Ready Function](#ready-function)
- [User Input](#user-input)
- [Functions](#functions)
    - [Useful Functions](#useful-functions)
- [Layout](#layout)
    - [Desktop Layer](#desktop-layer)
    - [Apps Grid](#apps-grid)
    - [Menu Bar](#menu-bar)
    - [Windows](#windows)
    - [Debugging](#debugging)

# Introduction
Welcome! This page will discuss how the desktop works and the different interactions it has with other elements. This will be your main of learning how the main UI is dealt with. If you're wondering how this would apply to development, it's neccessary to understand how this works if you're making a customized version of the BlockyOS app itself. for app development, it's less, if not, not at all important. 

# Setup
Before we talk about setup, there's two things to keep in mind.

1. Some of the setup is called via other files (Ex: Global)
2. Certain setup event happen only on certain systems

With that said, let's get straight into it!

## Variables & Singals
There's not many variables here to discuss but let's get into it!

- `close_app_window_button` is a signal that is connected to n app's taskbar button which helps the taskbar button go away when closing a window. It's a relay signal which means its only purpose is to relay the closing signal from the window to the taskbar button.
- `window_anim_playable` is a variable used to see if a window's minimize animation is playable after clicking on it's taskbar button.
- `user_path` is a static path to the user's data folder. Can be seen like `AppData\Roaming` or `share` in different platforms. Mainly used to access the BlockyOS path. **(WARNING: This variable may soon be depricated)**
- `apps` refers to the currently installed apps on the system. It is referred to in `update_apps()`, `refresh_app_list()`, and `clear_app_buttons()`.
- `time` refers to the current time of the host OS. This is used to create the little clock icon in the right corner
- `permissions_granted` is a variable that is only updated once. It mainly refers to the Android system's given permissions and is used to enable or disable certain features if that permission isn't granted.

## Ready Function
In the ready function, there's a lot that's going on to get everything connected and ready to use. The ready function is called once the desktop node is fully setup. Let's start out with the first thing you see.

The first function to be called is a `while` loop. This `while` loop insists that in case of any update or change has been made to the settings file that need to be done will get done. The function called is by `Global.load_settings()`. It also loads the settings once it gets everything setup. After it succeeds, it break out of the loop and continues on.

After that gets called, it sets the minimum BlockyOS window size so it can't become absurdly small.

Then there are some checks done.

- If the end user is running a debug version of BlockyOS, it will be sure to show the debugging tools. Otherwise the debug tools get removed from memory.
- After that, it checks if the user is running an HTML build so it can remove update checker from the menu. (No need to update if it gets updated by the user!)

After doing those checks, we then setup the start menu so it's not visible to the user when booting. Then we check to see if the apps directory exists, if not, make it. Then we check to see if an app install list exists. If not, then make one as well.

Once we do that, we run `update_apps()` to update the app list and check for apps in the apps directory.

We then connect a signal (`files_dropped`) for when files are dropped onto the window for later use.

After that, we request for Android permissions and add the allowed permissions the afformentioned `permissions_granted` variable. If the media access permission hasn't been accepted, then we disable the install apps feature in the start menu.

# User Input
When on the desktop, we're able to access user input and complete 2 different tasks

1. When the user pressed the `F11` key, we go fullscreen
2. When the mouse hovers over the start button, we hide the windows so input errors don't occur. Otherwise, we show the windows again.

Let's talk about the second one shortly.

When the user interracts with the start button, it has an input layer. Windows also have their own input layer. In this case, the window's input layer is above the start button's. Even though visually it doesn't show above the button, the input is still able to be done. As of now, I have no better way of making this issue go away so all windows just dissapear.

# Functions
Here in this section we'll talk about the custom functions created for their different purposes. This will go in order of appearance in the script.

- `dropped_files(files: PoolStringArray, screen: int)` is used in conjunction with the signal `files_dropped` from earlier.<br>**In depth:** In this function, it sorts through the files and sees if it ends in '.pck'. If it does, it gets the file path, reduces its name to the file name, and copies it to the apps directory. Then `update_apps()` is called and handles the rest of app installation.

- `clear_app_buttons()` clears all buttons in the app grid on the Desktop.<br>**In depth:** It sorts through all the nodes on the desktop and removes them.

- `refresh_app_list()` reads the installed apps and creates the appropriate buttons on the desktop.<br>**In depth:** It startes by removing all current buttons on the desktop and clearing the `apps` array. It then reads the installed apps file and checks to be sure the app exists in the apps folder. If it doesn't, it ignores it and moves on to the next app. If it exists, it then makes sure it isn't already on the desktop. If it does, it skips the creation of the button. If it succeeds, it then instances a new button and sets it up. When it grabs the app's icon it checks to be sure the app is or isn't supported by seeing if the image exists. If it doesn't, it removes the file and calls `update_apps()`. If that works, it finishes setting up the button and moves on to the next app in the list.

- `_on_button_pressed(button)` is called when an app button gets pressed on the desktop.<br>**In depth:** It starts off by getting the name of the button that was pressed. It then checks to see if the app exists or not. If not, it runs `update_apps()` in which case, removes the app from the desktop. If it does work, it makes loads in the pck app's contents and makes sure it can. If it can't, it prints an error and doesn't open the app. If it works, it then checks for a main scene. if that doesn't work, it doesn't open the app. If it does, it prepares and runs `open_app()` with the main scene and the name of the app (using the `pressed_button` variable from before).

- `_on_window_button_pressed(button, is_button: bool)` toggles taskbar app visibility visual when an app's minimize button is pressed or when it's taskbar button is toggled.<br>**In depth:** When the app's minimize button or taskbar icon is pressed, it loads different panel resources for the line under the app's icon. It then gets the apps name from the button pressed. It also grabs the window name of the current running app. It then checks to see if the minimize button was being pressed. If it was, then just change the visual. If not, it toggles the minimzation and the visual then and there.

- `window_anim_done(window_node, hiding: bool)` is used to reset `window_anim_playable` variable to true and optionally hide the window.<br>**In depth:** It first checks if the window should be hidden and hides accordingly. It then sets `window_anim_playable` to true.

- `open_app(app_node, app_name: String)` is called to open a custom app window, create the taskbar icon, and link the two together.<br>**In depth:** It first loads the app window scene and instances it. It then changes the name of the window node and the title to the app name. It then connects the window minimizing and closing to the desktop to help handle the app taskbar icon. Then an instance of a taskbar button gets made. It changes the taskbar icon to the app's icon. It then connects the signal for when the button is pressed to link to the window. Then this all checks for naming inconsistencies and continuously updates the name until it isn't already taken. This is why there can be multiple of the same app open and not interfere with each other. After all the setup, it then adds the taskbar button and window to their respective places.

- `open_built_in_app(app_node, app_name: String, icon)` is called to open a built in app from BlockyOS.<br>**In depth:** It doesn'y mainly the same thing as `open_app` with the key difference being it requires an icon to be passed through for the taskbar button.

- `dir_contents(path: String)` lists all the files in the specified path given.<br>**In depth:** It opens the listed directory and gets all listed directories and files in that directory. It then prints the files and directories listed. This function is not recursive.

- `dir_files_to_array(path: String)` gets all files in the specified path and returns an array of the files.<br>**In depth:** Similar to `dir_contents()`, it instead gets all files and skips over directories. It then stores those files into an array and returns that value.

- `dir_dirs_to_array(path: String)` gets all directories in the specified path and returns an array of the directories.<br>**In depth:** Similar to `dir_contents()`, it instead gets all directories and skips over files. It then stores those directories into and array and retruns that value.

- `get_pck_icon(app_name: String)` gets the icon from the file and returns a string of the path to the icon.<br>**In depth:** It creates a variable to the path of the pck app. It then loads the path to the app file and checks if it read properly. If not, it returns `"0"` which just means it didn't load correctly. Otherwise, it checks to see if the icon exists at `"app_name"/"app_name".png`. If it gets the file, it returns the path to the file. Otherwise, it returns `"0"`.

- `_on_window_closed(app_name: String)` emits a signal to an app's taskbar icon to get removed.

- `update_apps()` searches the apps directory to add new apps into the installed list and remove missing apps.<br>**In depth:** It first calls `dir_files_to_array` and removes the installed app list file. It then opens the installed apps file and writes the detected apps in the apps directory intot the file. In the installed apps file, it only contains the name of the app and not the extension since that's not required. It then calls `refresh_app_list()` to handle the rest.

- `hide_start_menu()` hides the start menu with an animation.<br>**In depth:** It makes a tween which changes the size, position, and transparency of the start menu over time. It also makes the start button un-toggled.

- `_on_StartButton_mouse_entered()` and `_on_StartButton_mouse_exited()` is used to change the size of the start menu button when hovered.

- `_on_StartButton_toggled(button_pressed: bool)` shows or hides the start menu.

- `_on_InstallApps_pressed()` opens the Install Apps app using `open_built_in_app()`.

- `_on_UpdateApps_pressed()` calls `update_apps()` to reload apps installed.

- `_on_UpdateDownloader_pressed()` opens the Update Downloader app using `open_built_in_app()`.

- `on_Settings_pressed()` opens the Settings app using `open_built_in_app()`.

## Useful Functions
The functions here wouldn't be useful to most app developers but would be more useful for understanding and changing the Desktop source.

Useful functions for app devs:
- `dir_contents()`
- `dir_files_to_array()`
- `dir_dirs_to_array()`

While those functions can be used directly, it's better to copy them and use them in the app itself so it doesn't need to connect to the desktop as that can get confusing. Trust me, I know.
# Layout
The layout for the desktop scene is not all to complicated but it's best to know what items are on what layers and when they can or cannot show up in the app.

## Desktop Layer
The first layer to show up in the desktop is the `Background` layer. It's just an image displayed behind everything and requires no interactivity. In the future, this could change to support live backgrounds as videos and would make for some interesting customization later on.

## Apps Grid
The next piece is the `AppsGridContainer` layer. This layer contains all of the buttons for installed apps and it just above the `Desktop` layer. You can think of it as a permanent app drawer. In the future, I might make it so that the apps can either be organized on the grid or they have their own container so your desktop can be clear and for other stuff.

## Menu Bar
Next up is the menu bar. This contains the `StartMenu`, `StartButton`, `OpenWindows`, and the `Clock` pieces. This altogether makes the taskbar and the start menu.

- `StartMenu` refers to the start menu. The start menu contains the main apps and functions that you may use constantly.

- `StartButton` is the button that is used to open the start menu. This button has one use and one use only.

- `OpenWindows` is the section of the taskbar that has all of your open apps. Apps here don't stack and currently just toggle minimize on the window. If too many apps show up in the bar, it makes a scroll bar and can then scroll horizontally. Possibly in the future it will allow for hover to show the window.

- `Clock` is the clock. Yeah. Just a clock. ._.

## Windows
After the `MenuBar`, we have the `Windows` layer. The windows layer contains all of your open windows. Not much to really say about the `Windows` layer.

## Debugging
The debugging layer will be the most important for working on new features on BlockyOS. This layer contains 3, unset buttons for debugging purposes. These buttons only will show on the debug releases of BlockyOS. Otherwise, they never show up to the end user.