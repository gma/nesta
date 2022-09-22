# Nesta - a CMS for Ruby Developers

A file-based CMS for web sites and blogs, written in [Sinatra][frank].

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
help with anything feel free to file an issue, or contact me (@grahamashton)
on Twitter.

If you like Nesta you can keep up with developments by following [@nestacms][]
on Twitter, and on [the blog][].

[@nestacms]: http://twitter.com/nestacms
[the blog]: http://nestacms.com/blog

## Contributing

If you want to add a new feature, I recommend that you file an issue to discuss
it before you start coding. I'm likely to suggest that we implement it as a
[plugin][] (to keep Nesta itself lean and simple), so you might save yourself
some time if we chat about a good approach before you start.

[plugin]: http://nestacms.com/docs/plugins

-- Graham ([@grahamashton][] on Twitter).

[@grahamashton]: http://twitter.com/grahamashton
