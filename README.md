# Shelly

Shelly is a small tool designed to create interactive shells out of common
terminal commands.

## Installation

Add this line to your application's Gemfile:

    gem 'shelly'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install shelly

### Dependencies

Shelly requires ruby1.9 (or ruby1.8 with a backported `shellwords` library)
built with readline support.

## Usage

To make a shell with shelly, simply invoke it with the prefix you'd like each
command to have. For example,

    $ shelly git

starts an interactive session where each command entered is prefixed with `git`
and run in your default shell.

To create an executable script 