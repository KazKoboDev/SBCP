# Starbound Control Panel
[![Gem Version](https://badge.fury.io/rb/sbcp.svg)](https://badge.fury.io/rb/sbcp)

Starbound Control Panel, or SBCP for short, is a Ruby gem that allows server owners to easily manage their servers. It behaves similarly to a wrapper without intercepting connections, relying solely on output. It is my first released project on GitHub, as well as my first Ruby gem.

## Features

* Relatively easy to install and setup
* Fully automated backups
* Fully automated restarts (including recovery from crashes)
* Easy server managment commands (start, restart, stop, etc.)
* Intuitive configuration menu for adjusting internal settings

## Requirements

SBCP was designed for Linux and developed on Ubuntu. It has been tested on Ubuntu Server 16.04.

SBCP was developed on Ruby 2.3.0.

Your mileage may vary.

## Installation

If you don't have Ruby installed, you'll need it.
I reccommend using [RVM](https://rvm.io/rvm/install):

    $ gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    $ \curl -sSL https://get.rvm.io | bash -s stable --ruby=2.3.0

If you already have RVM:

    $ rvm install ruby-2.3.0
    $ rvm use ruby-2.3.0

Now just install the SBCP gem:

    $ gem install sbcp

## Usage

You'll find that SBCP won't work properly without some additional configuration.

Go ahead and start this process with the setup command:

    $ sbcp --setup
    
It will attempt to ascertain the location of your Starbound server's installation directory.

Afterwards, it will ask if you want to use the default values. All default directories are based out of the Starbound installation directory. These values are:
* Backup Directory: ../sbcp/backups
* Backup History: 90 days
* Backup Schedule: Hourly
* Log Directory: ../sbcp/logs
* Log History: 90 days
* Log Style: Daily
* Restart Schedule: Every 4 Hours

Once this is finished, you can just do this for commands:

    $ sbcp --help
    
Note that currently not all commands are implemented.

## Plugins

SBCP has rudimentary plugin support. You can override SBCP's behavior by adding your own Ruby files to the plugins folder that's created during initial setup. You'll need to examine the source material as plugins will entirely override methods, so if you're looking to make changes to existing methods you will need to copy/paste the source into your plugin before making changes. The filename of your plugin doesn't matter as all Ruby files inside the plugin folder are loaded shortly after the daemon starts.

You can find the plugins folder in /sbcp/plugins, in the installation directory of your Starbound folder.

## TODO

SBCP isn't anywhere near complete. I have some additional features planned:

* GUI mode
* Permissions System to Allow Multiple Users of GUI mode
* Output Parser (useful for emulating in-game commands, amongst other things)
* RCON support
* Better Plugin Support
* Ban/Kick/Unban commands
* Server announcements (including restart announcements)
* More that I can't think of right now, I'm sure

## Contributing

Bug reports and pull requests are welcome.

Although bear with me, I haven't used GitHub much before so I'll need to read up on pull requests.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

