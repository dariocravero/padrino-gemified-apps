# Gemified apps in Padrino

This repo intends to answer 
[How to access Padrino model and database in a “standalon” (bin/) script?](http://stackoverflow.com/questions/26222801/how-to-access-padrino-model-and-database-in-a-standalon-bin-script) and
[How to access a gemified Padrino Apps Model from other gem that requires that App](http://stackoverflow.com/questions/26213806/how-to-access-a-gemified-padrino-apps-model-from-other-gem-that-requires-that-ap).

There is also a GitHub issue for padrino-framework at padrino/padrino-framework#1784 .

## The issue

In short, there are two issues of the similar nature, both related to models defined in the gemified app:
* they need to be accessed from another gems/projects;
* they need to be accessed from the gemified app's `bin`, doing something else other than starting
the Padrino server.

## The example

First there's `gemified-app`. That's a Padrino app that is gemified. It also contains a model
called `SomeModel` that has one field called `property`.

Then there's `access-gemified-app-without-padrino`; a ruby script that loads the gemified app to
access the model.

Finally, there's `another-app` which is a regular Padrino app that just loads `gemified-app` to use
its model.

## Problems with the current Padrino setup

Creating an app with `padrino g project gemified-app --orm sequel --gem --tiny` will give you the
following `gemspec`:

```
# -*- encoding: utf-8 -*-
require File.expand_path('../lib/gemified-app/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Darío Javier Cravero"]
  gem.email         = ["dario@uxtemple.com"]
  gem.description   = %q{Padrino gemified app example}
  gem.summary       = %q{Padrino gemified app example}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "gemified-app"
  gem.require_paths = ["lib", "app"]
  gem.version       = GemifiedApp::VERSION

  gem.add_dependency 'padrino-core'
end
```

The key points are `gem.require_paths = ["lib", "app"]` and `gem.add_dependency 'padrino-core'`.

`gem.require_paths = ["lib", "app"]` explains why `models/some_model.rb` isn't available when we
load the gem somewhere else. It simple isn't added to `$LOAD_PATH` :(.

`gem.add_dependency 'padrino-core'` hints us that something might be missing later on. What happens
with dependencies like the ORM or the renderer? Should we load those? I reckon that it's a matter
of what you want to achieve but I'd say that most times yes.

Our gemified app dependencies are still listed in our `Gemfile` which will only be added in the 
current scope and not in any gems requiring our `gemified-app` gem.

## A first attempt at solving this

For this to work there are two things we should do:

Add `'models'` to `gem.require_paths = ["lib", "app"]` so that it becomes:
`gem.require_paths = ["lib", "app", "models"]`.
That will make sure that anything inside the `gemified-app/models` directory is included in your
gem.

To make it easier to test this, we'll use `bundler` and in our `access-gemified-app-without-padrino`
test script we'll add a `Gemfile` that looks like this:

```
source 'https://rubygems.org'

gem 'gemified-app', path: '../gemified-app'
gem 'pry'
```

Now in your new app, go to the REPL `bundle exec pry` and try to `require 'gemified-app'`.
Then try `SomeModel.all`. It will fail. Why? Because you didn't `require 'some_model'`.

It will still not work if you do that though. Why? Because none of the model's dependencies,
i.e. `sequel` and `sqlite3` (not a direct dependency but it is through the connection) are loaded.

Here you have two choices: you load them manually on your `Gemfile` or you define them as
dependencies on `gemified-app.gemspec`.
I regard the latter one as a better choice since you're already including the model and you're
expecting its dependencies to come with it. It would like this:

```
# gemified-app/gemified-app.gemspec

  # ...

  gem.add_dependency 'padrino-core'
  gem.add_dependency 'padrino-helpers'
  gem.add_dependency 'slim'
  gem.add_dependency 'sqlite3'
  gem.add_dependency 'sequel'
  gem.add_development_dependency 'rake'

  # ...
```

```
# gemified-app/Gemfile
source 'https://rubygems.org'

# Distribute your app as a gem
gemspec
```

You would have to explicitly include all the gems you will need. This may seem cumbersome but in
all fairness it gives you a greater understanding of what your app needs. Eventually you will
realise you don't even need bundler and the Gemfile :).

Alright, so, go ahead launch your REPL and type `require 'gemified-app'` and `require 'some_model'`.
Then try `SomeModel.all`. And... It will fail :(. Why? Because `Sequel::Base` isn't defined. Now you might be wondering:
what happened to the reference to `sequel` I put in my `gemified-app.gemspec`? Well, it's just that:
a reference and it won't require the gem for you.
This won't happen with Padrino either because we're using
```
require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, RACK_ENV)
```
in our `config/boot.rb` and that only loads required gems on our `Gemfile`.

So the question is... Should we load that manually? And if so, where?

Well, since this is a gem itself, I believe that the best place to do so would be in `lib/gemified-app.rb`.
Loading all the gems needed will make this file look like:

```
require 'padrino-core'
require 'padrino-helpers'
require 'slim'
require 'sqlite3'
require 'sequel'

module GemifiedApp
  extend Padrino::Module
  gem! "gemified-app"
end
```

Alright, so we're all set... Back to the REPL, do your requires
```
require 'gemified-app'
require 'some_model'
```
and try `SomeModel.all`. And... It will fail :(. Again! :/ Why? Because there's no connection to the
database. Padrino was loading this for us through `config/database.rb`.

Another question arises... Should we include `config/database.rb` in the gem too?
The way I see it, we shouldn't. The way I see it, the database connection is something every app
should locally define as it may contain specific credentials to access it or stuff like that.
Our sample, `access-gemified-app-without-padrino/do-somethin.rb` script will then look like this:

```
require 'gemified-app'

Sequel::Model.plugin(:schema)
Sequel::Model.raise_on_save_failure = false # Do not throw exceptions on failure
Sequel::Model.db = Sequel.connect("sqlite:///" + File.expand_path('../../gemified-app/db/gemified_app_development.db', __FILE__), :loggers => [logger])

require 'some_model'

SomeModel.all.each do |model|
  puts %Q[#{model.id}: #{model.property}]
end
```

Yes, the connection code is pretty much the same than our Padrino app and we're reusing its database
for this example.

That was some ride :) but we finally made it. See the sample apps in the repo for some working
examples.

### require `some_model` :/

I don't know you but I don't like that at all. Having to do something like that means that I
really have to pick my models' names very carefully not to clash with anything I may want to use
in the future.
I reckon that modules are the answer to it but that's the current state of affairs. See the
conclusion for more on this.

## An alternative approach

Separate your model layer into its own gem and require it from your (gemified or not) Padrino app.
This might probably be the cleanest as you can isolate tests for your models and even create
different models for different situations that may or may not use the same database underneath.

It could also encapsulate all of the connection details.

## Conclusion

I think we should review Padrino's approach to gemified apps.

Should we use the gemspec instead of the Gemfile for hard dependencies?

Should we namespace the models (I know we had some issues in the past with this)?

Should we teach users to do explicit requires in their gems or to inspect the dependecies and
require them for them?

Should we teach our users how to load their dependencies and be more reponsible about it? At the end
of the day, if they went the gemified app route they are clearly much more proficient in Ruby and
should be aware of this kind of stuff.

Thoughts? :)
