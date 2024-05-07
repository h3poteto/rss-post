require 'rss'
require 'open-uri'
require 'redis'
require "time"

url = 'https://koogawa.sakura.ne.jp/hb/rss.php?id=h3poteto'
webhook = ENV['POST_URL']

redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'])

last_updated = redis.get('last_updated')

URI.open(url) do |rss|
  feed = RSS::Parser.parse(rss)
  puts "Scanning: #{feed.channel.title}"

  if last_updated == nil
    redis.set('last_updated', feed.items[0].dc_date)
    return
  end

  last_updated_date = Time.parse(last_updated)

  feed.items.reverse_each do |item|
    next if item.content_encoded.length < 1
    next if item.dc_date <= last_updated_date
    body = "#{item.content_encoded} / #{item.title} - #{item.link}"
    if webhook != nil
      raise "No access token" if ENV['ACCESS_TOKEN'] == nil
      uri = URI.parse(webhook)
      params = { access_token: ENV['ACCESS_TOKEN'], status: body, visibility: "public" }
      response = Net::HTTP.post_form(uri, params)
      puts "Posted: #{response.code} #{response.body}"
      next if response.code != "200" || response.code != "201"
      redis.set('last_updated', item.dc_date)
    else
      puts "Dry-run: #{body}"
      redis.set('last_updated', item.dc_date)
    end
  end
end
