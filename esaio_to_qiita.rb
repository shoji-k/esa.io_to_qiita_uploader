!#/usr/bin/env ruby

require 'faraday'
require 'json'

require './config.rb'

begin
  if QIITATEAM.empty?
    url = 'http://qiita.com'
  else
    url = 'http://' + QIITATEAM + '.qiita.com'
  end
  conn = Faraday::Connection.new(:url => url) do |builder|
    builder.use Faraday::Request::UrlEncoded  # リクエストパラメータを URL エンコードする
    builder.use Faraday::Response::Logger     # リクエストを標準出力に出力する
    builder.use Faraday::Adapter::NetHttp     # Net/HTTP をアダプターに使う
  end

  Dir.glob(ESABACKUPDIRECTORY + '/**/*').each do |file_path|
    next if File.directory?(file_path)

    title = ''
    body = ''
    tags = [name: 'esa.io-import']
    param = {
      title: '', body: '', tags: [],
      coediting: false, gist: false, private: false, tweet: false
    }
    File.open(file_path) do |file|
      file.read.split("\n").each_with_index do |t, i|
        # 0: ---
        # 1: title: "sample title"
        # 2: category: sample-category
        # 3: tags: sampletag
        # 4: created_at: 2015-04-09 16:22:43 +0900
        # 5: updated_at: 2015-04-09 16:23:32 +0900
        # 6: published: false
        # 7: ---
        if i == 0 || i == 4 || i == 5 || i == 6 || i == 7
          # skip
          next
        elsif i == 1
          match = t.match(/title: "(.+)"/)
          title = match[1] unless match.nil?
        elsif i == 2
          match = t.match(/category: (.+)/)
          title = match[1] + '/' + title unless match.nil?
        elsif i == 3
          match = t.match(/tags: (.+)/)
          tagstring = match[1] unless match.nil?
          unless tagstring.nil?
            tags.push name: tagstring
          end
        else
          body += t + "\n"
        end
      end

    end
    param[:title] = title
    param[:body] = body
    param[:tags] = tags

    response = conn.post do |request|
      request.url '/api/v2/items'
      request.headers = {
        'Authorization' => 'Bearer ' + QIITATOKEN,
        'Content-Type' => 'application/json'
      }
      request.body = JSON.generate(param)
    end
    json = JSON.parser.new(response.body)
  end

rescue SystemCallError => e
  puts %Q(class=[#{e.class}] message=[#{e.message}])
rescue IOError => e
  puts %Q(class=[#{e.class}] message=[#{e.message}])
end

