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

## Setup

This app uses CUPS to print. To configure your CUPS defaults:

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
