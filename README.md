# Shelly

Shelly is a small tool designed to create interactive shells out of common
terminal commands.

## Installation

To install Shelly, clone this repo, then run `rake install` from its root.
Alternatively, run `rake build` to generate a gem in pkg/shelly-VERSION.gem and
install that normally.

If you need to include Shelly in one of your projects, you can add the following
to your Gemfile:

    gem 'shelly', :git => 'git://github.com/davidh-raybeam/shelly.git'

### Dependencies

Shelly requires ruby1.9 (or ruby1.8 with a backported `shellwords` library)
built with readline support.

## Usage

To make a shell with shelly, simply invoke it with the prefix you'd like each
command to have. For example,

    $ shelly git

starts an interactive session where each command entered is prefixed with `git`
and run in your default shell.

To create an executable script, run `shelly --script COMMAND_PREFIX`.