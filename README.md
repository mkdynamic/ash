# Ash

An experiment to build a terminal based IM client. Currently, only a Campfire adapter is implemented, but the idea is to support multiple backends. Scope `vendor/ash-campfire` to get the idea.

This is a work in progress, but the Campfire implementation is solid enough to use. Check out the walkthrough below for some screenshots.

## Requirements

* Ruby 2.0+ (probably 1.9 too, but not tested)

## Install

* Clone the project
* Copy `ash.yml.example` to `~/.ash.yml`, and set `subdomain` and `token` for Campfire
* Install dependencies with `bundle install`
* Run with `bin/ash`

## Walkthough

Type `:help` and hit return to show a full list of commands:

![](http://cl.ly/image/2X0A0Z1J2T0w/content)

Type `:rooms` to show a list of rooms (as per your config YAML file):

![](http://cl.ly/image/290w1R0w2k1t/`content)

Join room 1 by typing `:room 1`:

![](http://cl.ly/image/2B143q1F100o/content)

List people in the current room with `:people`:

![](http://cl.ly/image/3x0F3Y0F021q/content)

Type messages and hit return to post. You can clear the screen buffer at any time, type `:clear`:

![](http://cl.ly/image/1I0W1l1a1E2e/content)

Switch to room 2 with `:room 2`:

![](http://cl.ly/image/3z0N0v0H0L0p/content)

You can switch back to room 1 with `:room 1`:

![](http://cl.ly/image/1M18353o3m2Z/content)

## Contributions

Contributions very welcome! I'd love somebody to pick this up and run with it. Happy to give helpful contributors commit rights.

## License

Copyright (c) 2014 by Mark Dodwell

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
