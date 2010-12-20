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

Begin by installing the gem:

    $ gem install nesta

Then use the `nesta` command to generate a new site:

    $ nesta new mysite.com

If you intend to deploy to Heroku, you'll also want the Heroku rake
tasks, so run this version instead:

    $ nesta new --heroku mysite.com

Install a few dependencies, and you're away:

    $ cd mysite.com
    $ bundle install

You'll find basic configuration options for your site in
`config/config.yml`. The defaults will work, but you'll want to tweak it
before you go very far.

That's it - you can launch a local web server in development mode using
shotgun...

    $ bundle exec shotgun config.ru

...then point your web browser at http://localhost:9393. Start editing
the files in `content/pages` (see [Creating Your
Content](http://effectif.com/nesta/creating-content) for full
instructions).
