# frozen_string_literal: true

require 'openmw_nightlies'

map '/latest' do
  run OpenmwNightlies::Latest
end

map '/' do
  run OpenmwNightlies::Server
end
