# frozen_string_literal: true

require 'sinatra/base'

module OpenmwNightlies
  class Server < Sinatra::Base
    set :public_folder, 'public'
    set :strict_paths, false

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    get '/' do
      send_file File.join(settings.public_folder, 'index.html')
    end
  end
end
