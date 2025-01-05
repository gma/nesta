# File Based CMS and Static Site Generator

Nesta is a lightweight CMS for building content sites and blogs, written in
Ruby using the [Sinatra] web framework.

- Write your content in [Markdown] or [Textile], in your text editor (drop into
  HTML or Haml if you need more control)
- Files are stored in text files on your hard drive (there is no database)
- Publish changes by putting these files online (Git recommended, not required)
- Deploy either as a static site (SSG) or by rendering HTML on the server (SSR)

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

That's it — you can launch a local web server in development mode using the
`mr-sparkle` dev server:

    $ bundle exec mr-sparkle config.ru

Point your web browser at http://localhost:8080. Start editing the files in
`content/pages` (see the [docs on writing content] for full instructions).

You can either [deploy it] behind a web server, or build a static version of
your site:

    $ nesta build  # but see config.yml for build settings

[installing Ruby]: https://www.ruby-lang.org/en/documentation/installation/
[docs on writing content]: http://nestacms.com/docs/creating-content/
[deploy it]: https://nestacms.com/docs/deployment/

## Support

There's plenty of information on <https://nestacms.com>. If you need some
help with anything feel free to [file an issue], or contact me on Mastodon
([@gma@hachyderm.io]).

[file an issue]: https://github.com/gma/nesta/issues/new
[@gma@hachyderm.io]: https://hachyderm.io/@gma
[the blog]: https://nestacms.com/blog

![Tests](https://github.com/gma/nesta/actions/workflows/tests.yml/badge.svg)

## Contributing

If you want to add a new feature, consider [creating an issue] so we can
have a chat before you start coding. I might be able to chip in with ideas on
how to approach it, or suggest that we implement it as a [plugin] (to keep Nesta
itself lean and simple).

[creating an issue]: https://github.com/gma/nesta/issues/new
[plugin]: https://nestacms.com/docs/plugins

-- Graham

