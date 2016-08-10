require 'sequel'
require 'twitter'

DB = Sequel.connect(ENV['DATABASE_URL'])
DB.create_table?(:wekbers) do
  primary_key :id
  String :name
  String :twitter_username, unique: true
end
DB.create_table?(:tweets) do
  primary_key :id
  String :tweet_id
  DateTime :created_at
end

TWITTER = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
end


class WekbReminder

  # check for direct messages and register people who want a DM reminder
  # send a DM with the content "stop" to unsubscribe
  def self.register!
    last_tweet = DB[:tweets].order(:created_at).limit(1).first
    last_id = last_tweet ? last_tweet[:tweet_id] : 0
    TWITTER.direct_messages(:since_id => last_id).each do |t|
      next unless DB[:tweets].where(:tweet_id => t.id.to_s).first.nil?
      twitter_username = t.sender.screen_name.to_s.downcase
      name = t.sender.name
      if t.text.strip.downcase == 'stop'
        DB[:wekbers].where(:twitter_username => twitter_username).limit(1).delete()
        TWITTER.unfollow(twitter_username)
        TWITTER.create_direct_message(twitter_username, "Hi #{twitter_username}, I still hope to see you in the future again.")
      elsif DB[:wekbers].where(:twitter_username => twitter_username.strip).first.nil?
        DB[:wekbers].insert(:name => name, :twitter_username => twitter_username)
        TWITTER.follow(twitter_username)
        TWITTER.create_direct_message(twitter_username, "Hi #{twitter_username}, great! See you on Tuesday. I will send you a WEKB reminder.")
      end
      DB[:tweets].insert(:tweet_id => t.id.to_s, :created_at => Time.now)
    end
  end

  # send a public reminder tweet and direct messages to the subscribers
  def self.remind!
    return unless Time.now.tuesday? #make sure it is tuesday :D
    tweet = TWITTER.update('It is Tuesday again. Time for #WEKB \o/ who will be there?')
    DB[:wekbers].each do |w|
      text = "Hello #{w[:twitter_username]}, this is your friendly #WEKB reminder. It is Einklangs-time! Same time, same place...see you later. \o/ \n\n #{tweet.url} (RSVP by replying to that tweet)"
      TWITTER.create_direct_message(w[:twitter_username], text) rescue "we simply ignore errors :)"
    end
  end

end

if ARGV[0] == 'remind'
  WekbReminder.remind!
  puts "reminded"
elsif ARGV[0] == 'register'
  WekbReminder.register!
  puts "registered"
end
