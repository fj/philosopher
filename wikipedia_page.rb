require 'nokogiri'

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

