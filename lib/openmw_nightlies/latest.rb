# frozen_string_literal: true

require 'net/http'
require 'sinatra/base'
require 'time'

module OpenmwNightlies
  class Latest < Sinatra::Base
    SVG_TEMPLATE = <<~SVG
      <svg width="190" height="28" viewBox="0 0 190 28" xmlns="http://www.w3.org/2000/svg" version="1.1">
        <text x="95" y="14" font-family="sans-serif" font-size="13px" fill="black" text-anchor="middle">OpenMW-%<commit>s-win%<bits>s</text>
        <text x="95" y="28" font-family="sans-serif" font-size="13px" fill="black" text-anchor="middle">%<date>s</text>
      </svg>
    SVG
    INFO_URL = 'https://rgw.ctrl-c.liu.se/openmw/latest-%<bits>s'
    NIGHTLY_URL = 'https://rgw.ctrl-c.liu.se/openmw/Nightlies/OpenMW-%<commit>s-win%<bits>s.exe'

    Release = Struct.new :uri, :commit, :size, :date

    def initialize
      super
      @etag = {}
      @last_modified = {}
      @source_information = {}
    end

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    get '/OpenMW-latest-win32.svg' do
      content_type 'image/svg+xml'

      info = source_information(32)
      sprintf(SVG_TEMPLATE, commit: info.commit, date: info.date, bits: 32)
    end

    get '/OpenMW-latest-win32.exe' do
      redirect source_information(32).uri, 302
    end

    get '/OpenMW-latest-win64.svg' do
      content_type 'image/svg+xml'

      info = source_information(64)
      sprintf(SVG_TEMPLATE, commit: info.commit, date: info.date, bits: 64)
    end

    get '/OpenMW-latest-win64.exe' do
      redirect source_information(64).uri, 302
    end

    def source_information(bits)
      raise ArgumentError, 'Bits must be 32/64' unless [32, 64].include? bits

      headers = {}
      headers['If-Modified-Since'] = @last_modified[bits] if @last_modified[bits]
      headers['If-None-Match'] = @etag[bits] if @etag[bits]
      uri = URI(sprintf(INFO_URL, bits: bits))
      puts uri.inspect
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme = 'https') { |http| http.request_get(uri.path, headers) }

      return @source_information[bits] if response.is_a? Net::HTTPNotModified

      response.value
      commit = response.body.strip

      uri = URI(sprintf(NIGHTLY_URL, bits: bits, commit: commit))
      puts uri.inspect
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') { |http| http.head(uri.path) }
      response.value

      @etag[bits] = response['etag']
      @last_modified[bits] = response['last-modified']
      @source_information[bits] = Release.new uri.to_s, commit, response['content-length'], Time.parse(response['last-modified'])
    rescue Net::HTTPServerException => e
      halt 404 if e.response.is_a? Net::HTTPNotFound

      raise
    end
  end
end
