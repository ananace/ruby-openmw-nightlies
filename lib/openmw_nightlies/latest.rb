# frozen_string_literal: true

require 'digest/sha2'
require 'json'
require 'net/http'
require 'sinatra/base'
require 'time'

module OpenmwNightlies
  class Latest < Sinatra::Base
    SVG_TEMPLATE = <<~SVG
      <svg width="190" height="28" viewBox="0 0 190 28" xmlns="http://www.w3.org/2000/svg" version="1.1">
        <text x="95" y="14" font-family="sans-serif" font-size="13px" fill="black" text-anchor="middle">OpenMW-%<commit>.9s-win%<bits>s</text>
        <text x="95" y="28" font-family="sans-serif" font-size="13px" fill="black" text-anchor="middle">%<date>s</text>
      </svg>
    SVG
    INFO_URL = 'https://rgw.ctrl-c.liu.se/openmw/latest-%<bits>s'
    NIGHTLY_URL = 'https://rgw.ctrl-c.liu.se/openmw/Nightlies/OpenMW-%<commit>.9s-win%<bits>s.exe'

    Release = Struct.new :uri, :commit, :size, :date, :sha256

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

    get '/OpenMW-latest-win32.sha256' do
      source_information(32).sha256
    end

    get '/OpenMW-latest-win32.json' do
      content_type 'application/json'

      source_information(32).to_h.to_json
    end

    get '/OpenMW-latest-win32.exe' do
      redirect source_information(32).uri, 302
    end

    get '/OpenMW-latest-win64.svg' do
      content_type 'image/svg+xml'

      info = source_information(64)
      sprintf(SVG_TEMPLATE, commit: info.commit, date: info.date, bits: 64)
    end

    get '/OpenMW-latest-win64.json' do
      content_type 'application/json'

      source_information(64).to_h.to_json
    end

    get '/OpenMW-latest-win64.sha256' do
      source_information(64).sha256
    end

    get '/OpenMW-latest-win64.exe' do
      redirect source_information(64).uri, 302
    end

    def source_information(bits)
      raise ArgumentError, 'Bits must be 32/64' unless [32, 64].include? bits

      uri = URI(sprintf(INFO_URL, bits: bits))

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme = 'https') do |http|
        req = Net::HTTP::Get.new uri.path
        req['If-Modified-Since'] = @last_modified[bits] if @last_modified[bits]
        req['If-None-Match'] = @etag[bits] if @etag[bits]

        http.request req
      end

      return @source_information[bits] if response.is_a? Net::HTTPNotModified

      response.value

      @etag[bits] = response['etag']
      @last_modified[bits] = response['last-modified']

      commit = response.body.strip

      uri = URI(sprintf(NIGHTLY_URL, bits: bits, commit: commit))
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') { |http| http.get(uri.path) }
      response.value

      digest = Digest::SHA256.hexdigest(response.body)

      @source_information[bits] = Release.new uri.to_s, commit, response['content-length'], Time.parse(response['last-modified']), digest
    rescue Net::HTTPServerException => e
      halt 404 if e.response.is_a? Net::HTTPNotFound

      raise
    end
  end
end
