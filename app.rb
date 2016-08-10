require 'sinatra'
require './wekb_reminder'

# exposes a register and remind endpoint for temporize which we use for cron jobs on heroku
# on a qick look it was the easiest to use "secret" URL to secure the endpoints. To do this a SECRET_URL env variable must be set

post "/#{ENV['SECRET_URL']}/fact" do
  WekbReminder.fact!
end

post "/#{ENV['SECRET_URL']}/register" do
  WekbReminder.register!
  "registered"
end

post "/#{ENV['SECRET_URL']}/remind" do
  WekbReminder.remind!
  "reminded"
end
