require 'nokogiri'
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

class WikipediaPage
  attr_accessor :title
  attr_accessor :content
  attr_accessor :ignores

  def initialize(o)
    self.title   = o.title
    self.content = Nokogiri::HTML o.content
    self.ignores = 0
  end

  def parse_title(href)
    href.sub(/^\/wiki\//, '').gsub('_', ' ')
  end

  def first_link_title
    xpath_query = '//p//a[starts-with(@href, "/wiki/")]'
    unparsed_link = content.xpath(xpath_query).to_a.each.lazy.select do |a|
      previous_text = a.xpath('preceding::text()').collect(&:text).join

      left_parens  = previous_text.count('(')
      right_parens = previous_text.count(')')

      !a['href'].include?(':') && (left_parens == right_parens)
    end.take(ignores + 1).force.last

    parsed_title = parse_title unparsed_link['href']
    parsed_title
  end
end

class PhilosophyFinder
  def initialize(starting_point = nil)
    @client = WikipediaApiClient.new

    @start_page = starting_point ?
      page_for(starting_point) :
      random_page
  end

  def random_page
    title = @client.request :random_page_title
    page  = @client.request :page, title
    WikipediaPage.new page
  end

  def page_for(title)
    WikipediaPage.new(@client.request :page, title)
  end

  def trail
    @trail ||= []
  end

  def ignores
    @ignores ||= Hash.new(0)
  end

  def ignores_for(page)
    ignores[page.title]
  end

  def add_ignore_for(page)
    ignores[page.title] += 1
  end

  def trail_before(page)
    trail.first trail.index page.title
  end

  def visit(page)
    trail.push page.title
  end

  def visited?(page)
    trail.include? page.title
  end

  def terminal?(page)
    return :no_page if page.nil?
    return :already_visited if visited?(page)
    return :back_to_philosophy if page.title == "Philosophy"

    false
  end

  def backtrack_from(page)
    puts "◀◀ #{page.title}"
    destination = page_for trail_before(page).last
    destination.ignores = add_ignore_for destination
    next_page_from destination
  end

  def next_page_from(page)
    print "#{page.title} ▶ "
    page = page_for page.first_link_title
    puts "#{page.title}"

    visited?(page) ? backtrack_from(page) : page
  end

  def ruminate
    page = @start_page
    until reason = terminal?(page)
      visit page
      page = next_page_from page
    end

    puts "---"
    puts "! terminating at #{page.title} because #{reason}"
    puts "• trail: #{trail}"
    puts "• trail size: #{trail.count}"
    puts "• backtracks: #{ignores}"

    puts "\n\nYou made it to Philosophy!" if reason == :back_to_philosophy
  end
end

PhilosophyFinder.new(ARGV[0]).ruminate
