require 'scraperwiki'
require 'mechanize'

@agent = Mechanize.new

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

def extract_urls_from_index(url)
  puts "Fetching detail page urls from: #{url}"
  page = @agent.get(url)
  page.search(".title").map { |e| e.at(:a).attr(:href) }
end

# Fetches the history of a deputy's faction changes
def deputy_faction_changes(id)
  page = @agent.get("http://w1.c1.rada.gov.ua/pls/site2/p_deputat_fr_changes?d_id=#{id}")

  page.at(:table).search(:tr)[1..-1].map do |row|
    end_date_value = row.search(:td)[2].text.strip
    end_date = end_date_value == "-" ? nil : Date.parse(end_date_value)

    {
      name: row.search(:td).first.text.strip,
      id: row.at(:a).attr(:href)[/\d+/],
      start_date: Date.parse(row.search(:td)[1].text.strip),
      end_date: end_date
    }
  end
end

# Checks for any gaps between faction changes so these can be filled in with
# an "independent" record
def check_independent_periods(faction_changes)
  periods = []

  faction_changes.each_with_index do |r,i|
    next if i == 0
    previous_end_date = faction_changes[i - 1][:end_date]

    if (r[:start_date] - previous_end_date).to_i > 1
      periods << {
        name: "Позафракційні",
        id: "",
        start_date: previous_end_date,
        end_date: r[:start_date]
      }
    end
  end

  periods
end

# To test just scraping one detail page run the script with the page ID as an argument
if ARGV[0] || ENV["MORPH_ID_TO_SCRAPE"]
  detail_page_urls = ["http://itd.rada.gov.ua/mps/info/page/" + (ARGV[0] || ENV["MORPH_ID_TO_SCRAPE"])]
else
  # The full list of deputies is available at a link on this page:
  # http://w1.c1.rada.gov.ua/pls/site2/p_deputat_list
  # ...that page fires JavaScript that loads the following URL
  current_deputies_url = "http://w1.c1.rada.gov.ua/pls/site2/fetch_mps?skl_id=9"
  # Deputies that are no longer in the Rada
  left_deputies_url = "http://w1.c1.rada.gov.ua/pls/site2/fetch_mps?skl_id=9&pid_id=-3"

  detail_page_urls = extract_urls_from_index(current_deputies_url) + extract_urls_from_index(left_deputies_url)
end

puts "Fetching deputies' details..."
detail_page_urls.each do |url|
  puts "Fetching #{url}"
  detail_page = @agent.get(url)

  party_element = detail_page.at(".mp-general-info dt:contains('Партія:') + dd")
  party = party_element.text if party_element

  start_date_parts = detail_page.at(".mp-general-info dt:contains('Дата набуття депутатських повноважень:') + dd").text.split
  start_date = Date.new(start_date_parts[2][/\d+/].to_i, ukrainian_month_to_i(start_date_parts[1]), start_date_parts[0].to_i)

  end_date_element = detail_page.at(".mp-general-info dt:contains('Дата припинення депутатських повноважень:') + dd")
  end_date = if end_date_element
    end_date_parts = end_date_element.text.split
    Date.new(end_date_parts[2][/\d+/].to_i, ukrainian_month_to_i(end_date_parts[1]), end_date_parts[0].to_i)
  end

  name = detail_page.at(:h2).inner_text
  # Ukrainian full names are written out: last name, first name, patronymic name
  name_parts = name.split

  id = url[/\d+/]

  record = {
    id: id,
    name: name,
    given_name: name_parts[1],
    patronymic_name: name_parts[2],
    family_name: name_parts[0],
    area: detail_page.at(".mp-general-info dt:contains('Обраний по:') + dd, dt:contains('Обрана по:') + dd").text,
    term: 8,
    start_date: start_date,
    end_date: end_date,
    image: detail_page.at(".simple_info img").attr(:src),
    party: party,
    source_url: url
  }

  puts "Saving current deputy record for #{record[:name]}"
  ScraperWiki::save_sqlite([:id, :start_date], record)

  faction_changes = deputy_faction_changes(id)
  independent_periods = check_independent_periods(faction_changes)
  (faction_changes + independent_periods).each do |faction|
    # Add `end_date` to earlier records if it's missing
    # https://github.com/openaustralia/ukraine_verkhovna_rada_deputies/issues/15
    ScraperWiki.sqliteexecute(
      "UPDATE data SET end_date = ? WHERE id = ? AND start_date < ? AND end_date IS NULL",
      [(faction[:start_date] - 1).to_s, id, faction[:start_date].to_s]
    )

    puts "Saving #{record[:name]} in faction #{faction[:name]}"
    ScraperWiki::save_sqlite(
      [:id, :start_date],
      record.merge(faction: faction[:name],
                   faction_id: faction[:id],
                   start_date: faction[:start_date],
                   end_date: faction[:end_date])
    )
  end

  if !record[:end_date] && faction_changes.any? && faction_changes.last[:end_date]
    # This person is still in parliament, albeit not in a faction
    # any more. So we need to create a new factionless record.
    puts "Saving factionless current deputy record for #{record[:name]}"
    ScraperWiki::save_sqlite(
      [:id, :start_date],
      record.merge(start_date: faction_changes.last[:end_date] + 1)
    )
  end
end
