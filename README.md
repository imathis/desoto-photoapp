# Photoapp

This is a tool for automating the photo system at DeSoto Caverns.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'desoto-photoapp'
```

Install ImageMagick

```
brew remove imagemagick
brew update && brew install imagemagick@6"
brew link imagemagick@6
```

And then execute:

    $ bundle

Be sure your shell profile loads in executables.

```
export PATH="$HOME/bin:$PATH"
export PATH="/usr/local/bin:$PATH"

export RBENV_ROOT="$HOME/.rbenv"alias profile='vim ~/.bash_profile'
alias pprofile='source ~/.bash_profile'

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
```

Run the setup commands:

```
$ photoapp setup
```

This will do the following:

- Installs `imagemagick` with (using Homebrew).
- Copies the image processing Automator workflow to `~/Library/Workflows/Applications/Folder\ Actions/`
- Installs the `Reprint.app`, `Update.app`, and `Upload.app` to `/Applications`.

Finally you'll need to enable the folder action to trigger photo processing when photos are added to the import folder. Launch the folder actions setup app:

```
$ photoapp config action
```

Then click `+` below the left column to add a new folder. Choose the folder where photos will be imported to, and click the `+` beneath the right panel to add an
action. Select `photoapp-process.workflow` from the list and close the app.

Finally to ensure that photos are copied to that folder, plug in the camera or camera card reader and open Image Capture. Select your device in the sidebar and
click the "arrow in a box" icon in the bottom left to open up a drawer which will allow you to specify which app is opened when that device is plugged in. Select
the AutoImporter app. Next launch AutoImporter.

```
$ photoapp config import
```

Configure it to import to the folder you have set to trigger the photos workflow and be sure it is set to delete photos after import.

## Printing

This app uses CUPS to print. To configure your CUPS defaults:

```
$ photoapp config printer
```

- Visit [The CUPS printers page](http://127.0.0.1:631/printers/)
- Choose the printer you want to configure
- Select "Set Default Options" from the Administration drop-down. 
- Change the profile as explained below and save.


### Default printer settings

These are the default settings for an Epson Stylus Photo R280. If using a different printer, use whatever settings are equivalent.

```
Paper Size: 5x7
Media Type: Glossy
```
