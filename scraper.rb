require_relative "lib/deputies_scraper"

scraper = DeputiesScraper.new

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

  detail_page_urls = scraper.extract_urls_from_index(current_deputies_url) + scraper.extract_urls_from_index(left_deputies_url)
end

puts "Fetching deputies' details..."
scraper.scrape_detail_pages(detail_page_urls)
puts "All done."
