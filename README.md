# Ukraine Verkhovna Rada Deputies

This is [a scraper that runs on morph.io](https://morph.io/openaustralia/ukraine_verkhovna_rada_deputies) to collect a list of all members of the Ukrainian parliament. It currently collects all data in Ukrainian.

It's designed to feed data into [EveryPolitician](http://everypolitician.org/) so that it can make [Popolo](http://www.popoloproject.com/) compatible data. It was built to be used by [Вони голосують для тебе](https://rada4you.org/).

## Refreshing data in EveryPolitician

You can [trigger a rebuild](https://github.com/everypolitician/everypolitician-data/issues/1230#issuecomment-156038088) of the EveryPolitician data by sending an empty POST request to https://everypolitician-rebuilder.herokuapp.com/Ukraine/Verkhovna_Rada — this will rebuild it an open a PR (if anything has changed). 

## Helpful URLs

All these URLs have obvious IDs you can change to get other pages:

* Current deputies list: http://w1.c1.rada.gov.ua/pls/site2/fetch_mps?skl_id=9
* Previous deputies list: http://w1.c1.rada.gov.ua/pls/site2/fetch_mps?skl_id=9&pid_id=-3

* Deputy's information page: http://itd.rada.gov.ua/mps/info/page/15669
* Deputy's faction changes: http://w1.c1.rada.gov.ua/pls/site2/p_deputat_fr_changes?d_id=15669

* Current faction members: http://w1.c1.rada.gov.ua/pls/site2/p_fraction_list?pidid=2613
