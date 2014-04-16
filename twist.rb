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
    unless track_keywords.include?(user['screen_name'])
      status_url = "https://twitter.com/#{user['screen_name']}/status/#{result['id']}"
      status_message = <<-"EOS"
<table>
  <tr>
    <td valign="top">
      <a href="#{status_url}"><img src="#{user['profile_image_url']}" width="48" height="48"></a>
    </td>
    <td>
      <p>#{result['text']}</p>
      <font color="#666">- <a href="#{user['url']}">@#{user['screen_name']}</a>
      (#{user['name']} / #{user['followers_count']} followers)
      via #{result['source']}</font>
    </td>
  </tr>
</table>
      EOS
      hipchat_client[ENV['HIPCHAT_ROOM_NAME']].send(ENV['HIPCHAT_SENDER_NAME'], status_message, message_format: 'html')
    end
  end
end
