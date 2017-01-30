python metacriticScraper.py | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), "[metacriticScraper]", $0 }' 2>&1
