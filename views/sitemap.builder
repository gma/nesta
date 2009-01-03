xml.instruct!
xml.urlset :xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc base_url
    xml.changefreq "daily"
    xml.priority "1.0"
    xml.lastmod @last.xmlschema
  end
  @pages.each do |page|
    xml.url do
      xml.loc url_for(page)
      xml.lastmod page.last_modified.xmlschema
    end
  end
end
