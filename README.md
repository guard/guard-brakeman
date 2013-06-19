# Guard::Brakeman [![Build Status](https://secure.travis-ci.org/guard/guard-brakeman.png)](http://travis-ci.org/oreoshake/guard-brakeman)

Guard::Brakeman allows you to automatically run [Brakeman](http://brakemanscanner.org/) tests when files are modified.

Use guard-brakeman >= 0.4.0 for brakeman >= 1.5.3
--------------
And use < 0.4.0 for brakeman < 1.5.3

## Install

The simplest way to install Guard is to use [Bundler](http://gembundler.com/).
Please make sure to have [Guard](https://github.com/guard/guard) installed before continue.

Add Guard::Brakeman to your `Gemfile`:

```bash
group :development do
  gem 'guard-brakeman'
end
```

Add the default Guard::Brakeman template to your `Guardfile` by running:

```bash
$ guard init brakeman
```

## Use sublime Text 2?

Check out [sublime_guard](https://github.com/cyphactor/sublime_guard)!  It gives you control Guard without leaving the editor.  This is even more powerful with Growl notifications.  Enter distraction-free mode and never leave!

## Usage

Please read the [Guard usage documentation](https://github.com/guard/guard#readme).

## Guardfile

Guard::Brakeman can be adapted to all kind of projects and comes with a default template that looks like this:

```ruby
guard 'brakeman' do
  watch(%r{^app/.+\.(erb|haml|rhtml|rb)$})
  watch(%r{^config/.+\.rb$})
  watch(%r{^lib/.+\.rb$})
  watch('Gemfile')
end
```

Please read the [Guard documentation](http://github.com/guard/guard#readme) for more information about the Guardfile DSL.



### List of available options

```ruby
:output_files   => %w(donkey.html) # write the results to the specified files
:notifications  => false    # display Growl notifications, defaults to true
:run_on_start   => true     # run all checks on startup, defaults to false
:min_confidence => 3        # only alert on warnings above a threshold, defaults to 1
:chatty         => true     # notify on ALL changes.  Defaults to false, only new or fixed warnings trigger a Growl
```

## Brakeman configuration

Issues
------

You can report issues and feature requests to [GitHub Issues](https://github.com/oreoshake/guard-brakeman/issues). Try to figure out
where the issue belongs to: Is it an issue with Guard itself or with Guard::Brakeman? Please don't
ask the question in the issue tracker, instead join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

When you file an issue, please try to follow to these simple rules if applicable:

* Make sure you run Guard with `bundle exec` first.
* Add debug information to the issue by running Guard with the `--debug` option.
* Add your `Guardfile` and `Gemfile` to the issue.
* Make sure that the issue is reproducible with your description.

## Development

- Source hosted at [GitHub](https://github.com/netzpirat/guard-brakeman).

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Please create a topic branch for every separate change you make.
* Make sure your patches are well tested.
* Update the README.
* Update the CHANGELOG for noteworthy changes.
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

## Contributors

* [Neil Matatall](https://github.com/oreoshake)
* [Justin Collins](https://github.com/presidentbeef)

## Acknowledgment

The [Guard Team](https://github.com/guard/guard/contributors) for giving us such a nice pice of software
that is so easy to extend, one *has* to make a plugin for it!

All the authors of the numerous [Guards](http://github.com/guard) available for making the Guard ecosystem
so much growing and comprehensive.

## License

(The MIT License)

Copyright (c) 2010 - 2011 Neil Matatall

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
