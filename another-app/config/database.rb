Sequel::Model.plugin(:schema)
Sequel::Model.raise_on_save_failure = false # Do not throw exceptions on failure
Sequel::Model.db = Sequel.connect("sqlite:///" + File.expand_path('../../../gemified-app/db/gemified_app_development.db', __FILE__), :loggers => [logger])
