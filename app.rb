#coding: utf-8

require 'sinatra'
require 'haml'

# IEがクソ過ぎてこう書かないと文字化ける(METAタグ単独は無駄)
get '/' do
	@base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
	content_type :html, :charset => 'utf-8'
	haml :index, :charset => 'utf-8'
end

get '/s' do
	params.reject! do |k, v|
		v == ""
	end
	locals = {"shussha_sub" => 20, "taisha_sub" => 20, "kyukei_time" => "0130"}.merge(params)
	erb :script, :locals => locals
end
