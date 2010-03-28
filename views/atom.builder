xml.instruct!
xml.feed :xmlns => "http://www.w3.org/2005/Atom" do
  xml.title @title, :type => "text"
  xml.generator "Nesta", :uri => "http://effectif.com/nesta"
  xml.id atom_id
  xml.link :href => "#{base_url}/articles.xml", :rel => "self"
  xml.link :href => base_url, :rel => "alternate"
  xml.subtitle @subtitle, :type => "text"
  xml.author do
    xml.name @author["name"] if @author["name"]
    xml.uri @author["uri"] if @author["uri"]
    xml.email @author["email"] if @author["email"]
  end if @author
  @articles.each do |article|
    xml.entry do
      xml.title article.heading
      xml.link :href => url_for(article),
               :type => "text/html",
               :rel => "alternate"
      xml.id atom_id(article)
      xml.content absolute_urls(article.body), :type => "html"
      xml.published article.date(:xmlschema)
      article.categories.each do |category|
        xml.category :term => category.permalink
      end
    end
  end
end
