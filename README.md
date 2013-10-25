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
mr-sparkle...

    $ bundle exec mr-sparkle config.ru

...then point your web browser at http://localhost:8080. Start editing
the files in `content/pages` (see the [docs on writing content][] for
full instructions).

[docs on writing content]: http://nestacms.com/docs/creating-content

## Support

There's plenty of information on <http://nestacms.com>. If you need some
help with anything just jump on the [mailing list][].

[mailing list]: http://nestacms.com/support

If you like Nesta you can show your support by following [@nestacms][]
on Twitter. It's written and maintained by [@grahamashton][].

[@grahamashton]: http://twitter.com/grahamashton
[@nestacms]: http://twitter.com/nestacms
