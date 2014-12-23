require 'twitter'


#### Get your twitter keys & secrets:
#### https://dev.twitter.com/docs/auth/tokens-devtwittercom
twitter = Twitter::REST::Client.new do |config|
  config.consumer_key = 'CtGM7xy3jJUScc54u64f2w'
  config.consumer_secret = 'f260gHvVb8wrxEdMs5BufjER6pOFNPaoNT76UG6FQ'
  config.access_token = '229626707-pEVoCcOJBho56bazCjqYXkVoEk93tlEy2aMBqS5R'
  config.access_token_secret = '6HWpQUEFCp1MCUl5kXqQ6QL4nIigqehwHIwgxereLj8'
end

search_term = URI::encode('from:Azure')

SCHEDULER.every '10m', :first_in => 0 do |job|
  begin
    tweets = twitter.search("#{search_term}")

    if tweets
      tweets = tweets.map do |tweet|
        { name: tweet.user.name, body: tweet.text, avatar: tweet.user.profile_image_url_https }
      end
      send_event('twitter_mentions', comments: tweets)
    end
  rescue Twitter::Error
    puts "\e[33mFor the twitter widget to work, you need to put in your twitter API keys in the jobs/twitter.rb file.\e[0m"
  end
end