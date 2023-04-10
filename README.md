# Lightweight file-based CMS and Static Site Generator

Nesta is a lightweight CMS for building content sites and blogs, written in
[Sinatra].

Content can be written in [Markdown] or [Textile], stored in text files on your
computer. There is no database.

You do your writing in your text editor.

Publish by pushing your changes to a git repository that's setup to deploy your
changes to the web.

[Sinatra]: http://www.sinatrarb.com/ "Sinatra"
[Markdown]: http://daringfireball.net/projects/markdown/
[Textile]: http://textism.com/tools/textile/

## Installation

Begin by [installing Ruby], then the Nesta gem:

    $ gem install nesta

Use the `nesta` command to generate a new site:

    $ nesta new mysite.com --git  # a git repo is optional, but recommended

Install a few dependencies, and you're away:

    $ cd mysite.com
    $ bundle

You'll find configuration options for your site in `config/config.yml`. The
defaults will work, but you'll want to tweak it before you go very far.

That's it - you can launch a local web server in development mode using
mr-sparkle...

    $ bundle exec mr-sparkle config.ru

...then point your web browser at http://localhost:8080. Start editing
the files in `content/pages` (see the [docs on writing content] for full
instructions).

You can either [deploy it] behind a web server, or build a static version of
your site:

    $ nesta build  # but see config.yml for related settings

[installing Ruby]: https://www.ruby-lang.org/en/documentation/installation/
[docs on writing content]: http://nestacms.com/docs/creating-content/
[deploy it]: https://nestacms.com/docs/deployment/

## Support

There's plenty of information on <http://nestacms.com>. If you need some
help with anything feel free to file an issue, or contact me on Mastodon
([@gma@hachyderm.io]) or Twitter ([@grahamashton]).

If you like Nesta you can keep up with developments by following [@nestacms]
on Twitter, and on [the blog].

[@gma@hachyderm.io]: https://hachyderm.io/@gma
[@grahamashton]: https://twitter.com/grahamashton
[@nestacms]: https://twitter.com/nestacms
[the blog]: https://nestacms.com/blog

![Tests](https://github.com/gma/nesta/actions/workflows/tests.yml/badge.svg)

## Contributing

If you want to add a new feature, please [create an issue] to discuss it before
you start coding. I might suggest that we implement it as a [plugin] (to keep
Nesta itself lean and simple), or be able to chip in with ideas on how to
approach it.

[create an issue]: https://github.com/gma/nesta/issues/new
[plugin]: https://nestacms.com/docs/plugins

-- Graham

