require 'sinatra'
require 'faraday'

$faraday = Faraday.new(:url => 'https://api.justyo.co/') do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

$locations = {}
ENV.each do |key, value|
  next unless key.start_with?("YO_API_TOKEN_")
  $locations[key.gsub("YO_API_TOKEN_", "").downcase] = value
end

puts $locations.inspect

get '/:location' do
  if api_token = $locations[params[:location].downcase]
    puts params.inspect
    $faraday.post('/yoall', {api_token: api_token})
    "thanks, buddy"
  else
    raise Sinatra::NotFound, params[:location]
  end
end
