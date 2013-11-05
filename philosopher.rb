require_relative 'wikipedia_page'
require_relative 'wikipedia_api_client'

class Philosopher
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
    visit page

    puts "---"
    puts "! terminating at #{page.title} because #{reason}"
    puts "• trail: #{trail}"
    puts "• trail size: #{trail.count}"
    puts "• backtracks: #{ignores}"
    puts "\nmade it to Philosophy!" if reason == :back_to_philosophy
  end
end

Philosopher.new(ARGV[0]).ruminate
