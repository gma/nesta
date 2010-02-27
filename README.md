# Nesta - a CMS for Ruby Developers

A CMS for small web sites and blogs, written in
[Sinatra](http://www.sinatrarb.com/ "Sinatra").

Content can be written in
[Markdown](http://daringfireball.net/projects/markdown/ "Daring Fireball:
Markdown") or [Textile](http://textism.com/tools/textile/) and stored in text
files (though you can also use Haml if you need to add some HTML to your
pages). There's no database; write your content in your editor. Publish by
pushing to a git repository.

## Installation

Begin by cloning the git repository:

    $ git clone git://github.com/gma/nesta.git

Nesta's dependencies are managed with bundler, which handles installing the
necessary gems for you:

    $ gem install bundler
    $ cd nesta
    $ bundle install

You'll need a config file. You can start with the default and tweak it to suit
later:

    $ cp config/config.yml.sample config/config.yml

Create some sample web pages (optional):

    $ bundle exec rake setup:sample_content

That's it - you can launch a local web server in development mode using
shotgun...

    $ bundle exec shotgun app.rb

...then point your web browser at http://localhost:9393. Start editing the
files in `nesta/content`, and you're on your way.

See [http://effectif.com/nesta](http://effectif.com/nesta) for more
documentation.
