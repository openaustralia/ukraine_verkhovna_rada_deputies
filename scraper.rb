require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

# To test just scraping one detail page run the script with the page ID as an argument
if ARGV[0] || ENV["MORPH_ID_TO_SCRAPE"]
  detail_page_urls = ["http://itd.rada.gov.ua/mps/info/page/" + (ARGV[0] || ENV["MORPH_ID_TO_SCRAPE"])]
else
  # The full list of deputies is available at a link on this page:
  # http://w1.c1.rada.gov.ua/pls/site2/p_deputat_list
  # ...that page fires JavaScript that loads the following URL
  index_page = agent.get("http://w1.c1.rada.gov.ua/pls/site2/fetch_mps?skl_id=9")

  detail_page_urls = index_page.search(".title").map { |e| e.at(:a).attr(:href) }
end

def ukrainian_month_to_i(string)
  case string
  when "січня"
    1
  when "лютого"
    2
  when "березня"
    3
  when "квітня"
    4
  when "травня"
    5
  when "червня"
    6
  when "липня"
    7
  when "серпня"
    8
  when "вересня"
    9
  when "жовтня"
    10
  when "листопада"
    11
  when "грудня"
    12
  else
    raise "Unknown month #{string}"
  end
end

detail_page_urls.each do |url|
  puts "Fetching #{url}"
  detail_page = agent.get(url)

  party_dt = detail_page.at(".mp-general-info").search(:dt).find { |d| d.inner_text.strip == "Партія:" }
  party = party_dt.next.inner_text if party_dt

  faction_dt = detail_page.at(".simple_info").at(:br)
  faction = faction_dt.next.inner_text.strip if faction_dt

  start_date_parts = detail_page.at(".mp-general-info").search(:dt).find { |d| d.inner_text.strip == "Дата набуття депутатських повноважень:" }.next.next.inner_text.split
  start_date = Date.new(start_date_parts[2][/\d+/].to_i, ukrainian_month_to_i(start_date_parts[1]), start_date_parts[0].to_i)

  record = {
    ## Required fields
    id: url[/\d+/],
    name: detail_page.at(:h2).inner_text,
    area: detail_page.at(".mp-general-info").search(:dt).find { |d| d.inner_text.strip == "Обраний по:" || d.inner_text.strip == "Обрана по:" }.next.inner_text,
    term: 8,
    start_date: start_date,
    # end_date:
    ## Optional fields
    # given_name
    # family_name
    # honorific_prefix
    # honorific_suffix
    # patronymic_name
    # sort_name
    # email
    # phone
    # fax
    # cell
    # gender
    # birth_date
    # death_date
    image: detail_page.at(".simple_info").at(:img).attr(:src),
    # summary
    # national_identity
    # twitter
    # facebook
    # blog
    # flickr
    # instagram
    # wikipedia
    # website
    ## Added fields
    party: party,
    faction: faction,
    source_url: url
  }

  puts "Saving record: #{record[:name]}"
  ScraperWiki::save_sqlite([:id], record)
end
