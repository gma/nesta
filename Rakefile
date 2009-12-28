require "rubygems"
require "sinatra"
require "spec/rake/spectask"
begin
  require "vlad"
  Vlad.load(:scm => :git, :app => nil, :web => nil)
rescue LoadError
end

require File.join(File.dirname(__FILE__), *%w[spec model_factory])
require File.join(File.dirname(__FILE__), *%w[lib models])
require File.join(File.dirname(__FILE__), *%w[lib configuration])

desc "Run all specs in spec directory"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList["spec/*_spec.rb"]
end

class Factory
  include ModelFactory
end

namespace :setup do
  desc "Create the content directory"
  task :content_dir do
    FileUtils.mkdir_p(Nesta::Configuration.content_path)
  end
  
  desc "Create some sample pages"
  task :sample_content => :content_dir do
    factory = Factory.new
    
    File.open(Nesta::Configuration.content_path("menu.txt"), "w") do |file|
      file.puts("fruit")
    end
    
    factory.create_category(
      :heading => "Fruit",
      :path => "fruit",
      :content => <<-EOF
This is a category page about Fruit. You can find it here: `#{File.join(Nesta::Configuration.page_path, 'fruit.mdown')}`.

The general idea of category pages is that you assign articles to categories (in a similar way that many CMS or blog systems allow you to tag your articles), and then write some text introductory text on the topic. So this paragraph really ought to have some introductory material about fruit in it. Why bother? Well it's a great way to structure your site and introduce a collection of articles. It can also help you to [get more traffic](http://www.wordtracker.com/academy/website-structure).

The articles assigned to the Fruit category are listed below, typically with a short summary of the article and a link inviting you to "read more". If you'd rather show the entire text of your article inline you can just omit the summary from your article.

Have a look at the files that define the articles that follow, and you should find that you can get the hang of it very quickly.
      EOF
    )

    %w[Pears Apples Bananas].each do |fruit|
      summary = <<-EOF
This would be an article on #{fruit} if I'd bothered to research it.
EOF
      file = File.join(Nesta::Configuration.page_path, "#{fruit.downcase}.mdown")
      location = "You can change this article by editing `#{file}`."
      factory.create_article(
        :heading => "The benefits of #{fruit}",
        :path => fruit.downcase,
        :metadata => {
          "date" => (Time.new - 10).to_s,
          "categories" => "fruit",
          "read more" => "Read more about #{fruit}",
          "summary" => summary.chomp
        },
        :content => "#{fruit} are good because... blah blah.\n\n#{location}"
      )
    end
    
    summary = <<-EOF
You can edit this article by opening `#{File.join(Nesta::Configuration.page_path, 'example.mdown')}` in your text editor. Make some changes, then save the file and reload this web page to preview your changes.
    EOF

    factory.create_article(
      :heading => "Getting started",
      :path => "getting-started",
      :metadata => {
        "date" => Time.new.to_s,
        "read more" => "Read more tips on getting started",
        "summary" => summary.chomp
      },
      :content => <<-EOF
#{summary}

Checkout the [Markdown Cheat Sheet](http://effectif.com/articles/markdown-cheat-sheet) to find out how to format your text to maximum effect.

If you want to add attachments to your pages you can drop them in the `#{Nesta::Configuration.attachment_path}` directory and refer to them using a URL such as [/attachments/my-file.png](/attachments/my-file.png) (`my-file.png` doesn't exist, but you get the idea). You can obviously refer to inline images using the same URL structure.
      EOF
    )
  end
end
