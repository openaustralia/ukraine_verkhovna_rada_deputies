require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

# To test just scraping one detail page run the script with the page ID as an argument
if ARGV[0]
  detail_page_urls = ["http://itd.rada.gov.ua/mps/info/page/" + ARGV[0]]
else
  # The full list of deputies is available at a link on this page:
  # http://w1.c1.rada.gov.ua/pls/site2/p_deputat_list
  # ...that page fires JavaScript that loads the following URL
  index_page = agent.get("http://w1.c1.rada.gov.ua/pls/site2/fetch_mps?skl_id=9")

  detail_page_urls = index_page.search(".title").map { |e| e.at(:a).attr(:href) }
end

detail_page_urls.each do |url|
  puts "Fetching #{url}"
  detail_page = agent.get(url)

  party_dt = detail_page.at(".mp-general-info").search(:dt).find { |d| d.inner_text.strip == "Партія:" }
  party = party_dt.next.inner_text if party_dt

  faction = detail_page.at(".simple_info").at(:br).next.inner_text.strip

  record = {
    ## Required fields
    id: url[/\d+/],
    name: detail_page.at(:h2).inner_text,
    area: detail_page.at(".mp-general-info").search(:dt).find { |d| d.inner_text.strip == "Обраний по:" || d.inner_text.strip == "Обрана по:" }.next.inner_text,
    # TODO: Just set this to party?
    # group:
    term: 8,
    # TODO: parse to a date
    start_date: detail_page.at(".mp-general-info").search(:dt).find { |d| d.inner_text.strip == "Дата набуття депутатських повноважень:" }.next.next.inner_text,
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
    faction: faction
  }

  puts "Saving record: #{record.inspect}"
  ScraperWiki::save_sqlite([:id], record)
end
