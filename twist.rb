require 'rubygems'
require 'bundler'
require 'em-twitter'
require 'json'
require 'slack-notifier'

Bundler.require

track_keywords = ENV['TWITTER_TRACK_KEYWORDS']

options = {
  path:   '/1/statuses/filter.json',
  params: { track: track_keywords },
  oauth:  {
    consumer_key:    ENV['TWITTER_CONSUMER_KEY'],
    consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
    token:           ENV['TWITTER_OAUTH_TOKEN'],
    token_secret:    ENV['TWITTER_OAUTH_SECRET']
  }
}

EM.run do
  twitter_client = EM::Twitter::Client.connect(options)
  slack_notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK_URL'],
    icon_url: ENV['SLACK_ICON_URL'], channel: ENV['SLACK_ROOM_NAME'], username: ENV['SLACK_SENDER_NAME']

  $stdout.sync = true
  puts "Notifier started, will notify to #{ENV['SLACK_ROOM_NAME']} on #{ENV['SLACK_TEAM']}"
  slack_notifier.ping "Notifier started"

  twitter_client.each do |result|
    result = JSON.parse(result)
    user = result['user']
    status_url = "https://twitter.com/#{user['screen_name']}/status/#{result['id']}"
    if result['retweeted_status']
      if result['in_reply_to_status_id']
        slack_notifier.ping status_url, username: ENV['SLACK_RT_SENDER_NAME'] 
      end
      rt = result['retweeted_status']
      if rt['retweet_count'] % 5 == 0
        text = "#{result['retweeted_status']['retweet_count']} retweets: #{rt['text'].length > 30 ? rt['text'].slice(0,30) + '...' : rt['text']} - @<#{status_url}|#{rt['user']['screen_name']}>"
        slack_notifier.ping text, username: ENV['SLACK_RT_SENDER_NAME'] 
      end
    else
      slack_notifier.ping status_url, unfurl_links: true
    end
  end
end
