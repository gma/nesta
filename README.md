# Nesta - a CMS for Ruby Developers

A CMS for small web sites and blogs, written in [Sinatra][frank].

Content can be written in [Markdown][markdown] or [Textile][textile] and
stored in text files (though you can also use Haml if you need to add
some HTML to your pages). There's no database; write your content in
your editor. Publish by pushing to a git repository.

[frank]: http://www.sinatrarb.com/ "Sinatra"
[markdown]: http://daringfireball.net/projects/markdown/
[textile]: http://textism.com/tools/textile/

## Installation

Begin by installing the gem:

    $ gem install nesta

Then use the `nesta` command to generate a new site:

    $ nesta new mysite.com --git

Install a few dependencies, and you're away:

    $ cd mysite.com
    $ bundle

You'll find basic configuration options for your site in
`config/config.yml`. The defaults will work, but you'll want to tweak it
before you go very far.

That's it - you can launch a local web server in development mode using
shotgun...

    $ bundle exec shotgun config.ru

...then point your web browser at http://localhost:9393. Start editing
the files in `content/pages` (see the [Writing content][content] docs
for full instructions).

[content]: http://nestacms.com/docs/creating-content

## Support

There's plenty of information on <http://nestacms.com>, but if you want to talk
to somebody, [get on the mailing list][].

[get on the mailing list]: http://nestacms.com/support

Like Nesta? You can follow [@nestacms][] on Twitter, and find the author
at [@grahamashton][].

[@grahamashton]: http://twitter.com/grahamashton
[@nestacms]: http://twitter.com/nestacms
