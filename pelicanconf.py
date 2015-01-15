#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = u'Arnulf Heimsbakk'
SITENAME = u'> /dev/null > 2>&1'
SITEURL = ''

PATH = 'content'

TIMEZONE = 'Europe/Oslo'

DEFAULT_LANG = u'en'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None

# Menu
MENUITEMS = (
             ('home', '/index.html'),
             ('|', '#'),
            )

# Blogroll
LINKS =  (
          ('isc', 'https://isc.sans.edu'),
          ('schneier', 'https://www.schneier.com'),
          ('krebs', 'http://krebsonsecurity.com'),
          ('security now!', 'https://www.grc.com/securitynow.htm'),
          ('eff','https://www.eff.org'),    
          (';login:','https://www.usenix.org/publications/login'),
          ('hacker news',   'https://news.ycombinator.com'),
          ('mailinator',   'https://mailinator.com'),
          ('duckduckgo', 'https://duckduckgo.com'),
        )
        
# Social widget
SOCIAL = (
          ('twitter', 'https://twitter.com/aheimsbakk'),
          ('google+', 'https://plus.google.com/+ArnulfHeimsbakk/posts/p/pub'), 
          ('linkedin', 'http://linkedin.com/in/arnulfheimsbakk'),
          ('instagram', 'http://instagram.com/1uff3#'),
          )

DEFAULT_PAGINATION = 10

# code blocks with line numbers
PYGMENTS_RST_OPTIONS = {'linenos': 'table'}

# Uncomment following line if you want document-relative URLs when developing
RELATIVE_URLS = True

CHECK_MODIFIED_METHOD="md5"

THEME = "pelican-fresh"
DISPLAY_PAGES_ON_MENU=False
DISPLAY_CATEGORIES_ON_MENU=True
YEAR_ARCHIVE_SAVE_AS = 'posts/{date:%Y}/index.html'
SITESUBTITLE = u''
SUMMARY_MAX_LENGTH = 250
READERS = {'html': None}
TEMPLATE_PAGES = {
                'google0d727ca9bbbd1220.html': 'google0d727ca9bbbd1220.html',
                'robots.txt': 'robots.txt'
                }
TAG_CLOUD_MAX_ITEMS=100
TAG_CLOUD_STEPS=4

