require 'gemified-app'

Sequel::Model.plugin(:schema)
Sequel::Model.raise_on_save_failure = false # Do not throw exceptions on failure
Sequel::Model.db = Sequel.connect("sqlite:///" + File.expand_path('../../gemified-app/db/gemified_app_development.db', __FILE__), :loggers => [logger])

require 'some_model'

SomeModel.all.each do |model|
  puts %Q[#{model.id}: #{model.property}]
end
