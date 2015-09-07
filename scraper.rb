require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

# The full list of deputies is available at a link on this page:
# http://w1.c1.rada.gov.ua/pls/site2/p_deputat_list
# ...that page fires JavaScript that loads the following URL
index_page = agent.get("http://w1.c1.rada.gov.ua/pls/site2/fetch_mps?skl_id=9")

detail_page_urls = index_page.search(".title").map { |e| e.at(:a).attr(:href) }

# record = {
#   id:
#   name:
#   area:
#   group:
#   term:
#   start_date:
#   end_date:
# }
