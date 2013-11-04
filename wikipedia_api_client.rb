require 'json'
require 'open-uri'
require 'cgi'

class WikipediaApiClient
  def last_request_time
    @last_request_time ||= Time.now
  end

  # Be a good wiki-citizen and wait at least 100ms between requests.
  def next_request_time
    last_request_time + 0.1
  end

  def allow_request?
    Time.now > next_request_time
  end

  def request(method, *arguments)
    raise ArgumentError unless self.respond_to? :method
    sleep(0.2) until allow_request?
    @last_request_time = Time.now

    send :"api_#{method}", *arguments
  end

  def response(url)
    #puts "### requesting #{url}"
    JSON.parse open(url).read
  end

  def api_random_page_title
    url = 'http://en.wikipedia.org/w/api.php?format=json&action=query&list=random&rnnamespace=0&redirects'
    json = response(url)

    json['query']['random'].first['title']
  end

  def api_page(title)
    base_url = 'http://en.wikipedia.org/w/api.php?format=json&action=parse&prop=text&redirects&page='
    url = [base_url, CGI::escape(title)].join
    json = response(url)

    response = {
      :title   => json['parse']['title'],
      :content => json['parse']['text']['*']
    }
    OpenStruct.new response
  end
end

