# Gathered here: https://github.com/h43z/rssify/
# 2023-01-06: Add support for relative links
import configparser
from datetime import datetime
import requests
from feedgen.feed import FeedGenerator
from bs4 import BeautifulSoup
from pytz import timezone
from re import match

config = configparser.ConfigParser()
config.read('config.ini')

for section in config.sections():
    s = dict(config.items(section))
    r = requests.get(s['url'])
    soup = BeautifulSoup(r.text, 'lxml')
    titles = soup.select(s['item_title'])
    urls = soup.select(s['item_url'])

    if 'item_date' in s:
        dates = soup.select(s['item_date'])
    else:
        dates = None

    fg = FeedGenerator()
    fg.title(section)
    fg.description(section)
    fg.link(href=s['url'], rel='alternate')

    main_url = match("https?://[^/]+", s['url']).group(0)

    for i in range(len(titles)):
        if i > len(urls) - 1:
            break

        url = urls[i].get('href')
        if url.startswith('/'):
            url = main_url + url

        fe = fg.add_entry()
        fe.title(titles[i].text)
        fe.link(href=url, rel='alternate')
        if dates is not None:
            date = datetime.strptime(dates[i].text.strip(), s['item_date_format'])
            if config.has_option(section, 'item_timezone'):
                localtz = timezone(s['item_timezone'])        
                date = localtz.localize(date)
        else:
            #date = datetime.now(timezone("Europe/Berlin")) 
            date = '1970-01-01 00:00:00+02:00'

        fe.published(date)

    fg.rss_file(section.replace(' ', '_') + '.xml')
