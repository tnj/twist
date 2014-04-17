require 'rubygems'
require 'bundler'
require 'em-twitter'
require 'json'
require 'hipchat'

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
  hipchat_client = HipChat::Client.new(ENV['HIPCHAT_API_TOKEN'])

  twitter_client.each do |result|
    result = JSON.parse(result)
    user = result['user']
    status_url = "https://twitter.com/#{user['screen_name']}/status/#{result['id']}"
    if result['retweeted_status']
      rt = result['retweeted_status']
      if rt['text'] != result['text']
        hipchat_client[ENV['HIPCHAT_ROOM_NAME']].send(ENV['HIPCHAT_SENDER_NAME'], status_url, message_format: 'text', color: 'gray')
      end
      if rt['retweet_count'] % 5 == 0
        hipchat_client[ENV['HIPCHAT_ROOM_NAME']].send('RT', <<"EOT", message_format: 'html', color: 'yellow')
<b>#{result['retweeted_status']['retweet_count']} retweets</b>: #{rt['text'].length > 30 ? rt['text'].slice(0,30) + '...' : rt['text']} - @<a href="#{status_url}">#{rt['user']['screen_name']}</a>
EOT
      end
    else
      hipchat_client[ENV['HIPCHAT_ROOM_NAME']].send(ENV['HIPCHAT_SENDER_NAME'], status_url, message_format: 'text', color: 'gray')
    end
  end
end
