# GemifiedApp

A padrino gem

## Usage

Add the following to your `Gemfile`:

```ruby
gem 'gemified-app'
```

and mount the app in your `apps.rb`:

```ruby
Padrino.mount("GemifiedApp::App").to("/gemified-app")
```

## Development

For development, this gem can be run as a standalone Padrino application
as you would expect from a normal one:

```ruby
$ bundle exec padrino start
```

The Rakefile also works like the normal Padrino one and supports all standard
components.
