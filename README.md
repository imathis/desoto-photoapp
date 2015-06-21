# Photoapp

This is a tool for automating the photo system at DeSoto Caverns.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'desoto-photoapp'
```

And then execute:

    $ bundle

Install the [Automator actions](https://photosautomation.com/index.html) for importing photos. Download the [installer here](https://photosautomation.com/installer.zip).


Run the setup command:

```
$ photoapp setup
```

This will do the following:

- Installs `imagemagick` with (using Homebrew).
- Installs [Automator actions](https://photosautomation.com/index.html) for importing pictures into Photos.app [Manually install from here](https://photosautomation.com/installer.zip)
- Copies the image processing Automator workflow to `~/Library/Workflows/Applications/Folder\ Actions/`
- Installs the `Reprint.app` to `/Applications` (You should add this app to the dock for easy reprinting).

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
Page Setup: Sheet Feeder - Borderless
Paper Size: 5x7 in
Media Type: Ulta Premium Photo Paper Glossy

... further down ...

MediaType: Ulta Premium Photo Paper Glossy
Media Size: 5x7 in (Sheet Feeder - Borderless)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
