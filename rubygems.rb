
require 'rubygems/name_tuple'
require 'rubygems/remote_fetcher'

source = Gem::Source.new('https://rubygems.org')
source.load_specs(:released)
