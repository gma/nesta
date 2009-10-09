# Nesta - a CMS for Ruby Developers

A CMS for small web sites (and/or blogs), written in
[Sinatra](http://www.sinatrarb.com/ "Sinatra").

Content is written in [Markdown](http://daringfireball.net/projects/markdown/
"Daring Fireball: Markdown") and stored in text files. There is no database;
write your content in your editor. Publish by pushing to a git repository.

## Installation

You need a few gems:

    $ sudo gem install builder haml maruku rspec shotgun sinatra vlad

Then run it straight from the git repo:

    $ git clone git://github.com/gma/nesta.git
    $ cd nesta
    $ cp config/config.yml.sample config/config.yml
    $ rake setup:sample_content
    $ shotgun app.rb

Point your web browser at [http://localhost:9393](http://localhost:9393),
start editing the files in `nesta/content`, and you're off.

See [http://effectif.com/nesta](http://effectif.com/nesta) for documentation.
