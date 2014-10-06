require 'padrino-core'
require 'padrino-helpers'
require 'slim'
require 'sqlite3'
require 'sequel'

module GemifiedApp
  extend Padrino::Module
  gem! "gemified-app"
end
