# Changelog

## 0.19.0 (Unreleased)

* Remove support for the Maruku Markdown processor.

  Maruku is considered obsolete by its maintainer, and is no longer used by
  Tilt (as of Tilt 2.5.0). As Nesta renders Markdown via Tilt, there's no need
  for us to continue loading Maruku via Tilt. It's recommended that you update
  your site to use kramdown.

  (Suggested by Brad Weslake)

* Handle errors raised when loading missing templating engine.

  When a templating engine is removed from the Tilt library (as recently
  happened with Maruku), Ruby was raising a `NameError` exception when Nesta
  attempted to load it. Nesta now ignores those errors, and tries to load
  another Markdown processor.

  (Graham Ashton, reported by Curtis Cooley)

* Fix whitespace in version.rb when generating new plugins. (Graham Ashton)

## 0.18.0 (19 November 2024)

* Update Sinatra to 4.1, to fix a vulnerability.

  Note that this is the same security alert that I believed I was fixing when I
  released Nesta 0.17.0. In actual fact, at that point the latest version of
  Sinatra (4.0.0) didn't yet include a fix.

  (Graham Ashton)

## 0.17.0 (6 November 2024)

 * Update Sinatra to verion 4.0, to fix a vulnerability. This has also
   required a jump to Rack 3. (Graham Ashton)

 * Update Sass parser to sass-embedded 1.80, which (due to changes in CSS 4)
   deprecates the global colour functions and the @import statement. Any Sass
   code that uses these features will need updating before Dart Sass 3.0 is
   released. The Sass maintainers are saying we've got about two years.

   In the meantime Sass will print deprecation warnings, some of which give
   hints on how you might update your code.

   See the Nesta commit history for an example of the kind of changes that are
   required, and these pages for more details:

   - https://sass-lang.com/documentation/breaking-changes/color-functions/
   - https://sass-lang.com/documentation/breaking-changes/import/

   This update has also forced us to drop support for Ruby 3.0, which is no
   longer supported by the sass-embedded gem.

   (Graham Ashton)

## 0.16.0 (11 April 2024)

 * Update Google Analytics JS code to GA4. (Matthew Bass)

 * Upgrade to Sinatra 3.1. (なつき)

 * Tilt renderers (e.g. for Markdown, Haml, or Textile) are now configurable.
   See #146 for details. (Graham Ashton)

 * Drop support for Ruby 2.7, which is no longer supported by Nokogiri,
   which is one of Nesta's dependencies. This is understandable; Ruby
   2.7 reached end-of-life in March 2023. (Graham Ashton)

 * Bug fix: Config variables that were defined for an environment (test,
   dev, production), but for which there was no default, were always read
   as nil. (Matthew Bass)

## 0.15.0 (11 July 2023)

 * Upgrade to Sinatra 3. (Graham Ashton)

 * The `models.rb` file has been long and unnecessarily hard to navigate
   for too long. It has been split up into multiple files, one for each
   class. (Graham Ashton, suggested by Lilith River)

 * Remove support for the BlueCloth markdown library. Nesta uses Tilt
   for rendering Markdown, and BlueCloth support has been removed in
   Tilt 2.2.0. See rtomayko/tilt#382 for details.

   If your site uses BlueCloth, remove your call to `Tilt.prefer`,
   and Nesta will use its default Markdown processor. See Nesta's docs
   on [configuring the Markdown processor] for more details.

   [configuring the Markdown processor]: https://nestacms.com/docs/creating-content/changing-the-markdown-processor

   (Graham Ashton)

## 0.14.0 (23 March 2023)

 * Nesta can now be used as a Static Site Generator (SSG) with its new
   `nesta build` command! Server Side Rendering (SSR) is still supported,
   as is development with a local web server.

   Back in the days when Heroku allowed us to deploy Nesta on their
   platform for free, there really didn't seem to be any point in
   converting a site to a bunch of static HTML and CSS files. If you
   enabled the appropriate HTTP cache-control headers, Heroku would
   automatically cache an entire site in memory, so there was no real
   performance benefit. That's why Nesta never had SSG support, even
   though everybody seemed to think it was cool.

   But Heroku is not free any more. And there's a wide choice of hosting
   platforms for static site generators. So why not?

   See the docs for full details, but in short:

   - If you run `bundle exec nesta build`, Nesta will generate a static
     copy of your site in a ./dist directory.

   - You might want to add ./dist to your .gitignore file.

   - There are a couple of new config settings in config.yml.

   - You can configure hosting platforms like Netlify, AWS Amplify,
     Vercel (and others) to redeploy your site by running the build
     command when you push changes to your git repository.

   This was fun to implement. (Graham Ashton)

 * Sass and SCSS files are now rendered with Dart Sass (the main implementation
   of Sass). We had been using the (now deprecated) libsass library.

   Sass has changed a bit since libsass was current, so you may need to make
   some small changes to your stylesheets. Documentation that should help with
   those changes can be found here:

   https://sass-lang.com/documentation/breaking-changes

 * Replace Nesta's custom template-locating code with Sinatra's #find_template
   method. (Graham Ashton, suggested by Lilith River)

 * Update multiple dependencies to fix security vulnerabilities; see commit
   history for details. (Graham Ashton)

 * Built-in support for configuring Nesta via environment variables has been
   dropped. (Graham Ashton)

   Should you still want to configure Nesta via the environment you can
   use Erb in `config.yml`, like this:

       some_value: <%= ENV.fetch('NESTA_VARIABLE') %>

 * During a tidy up of the config file code, the `yaml_conf` attribute on
   the Nesta::Config class has been renamed to `config`. This is unlikely
   to affect you, but if it does just change the name. (Graham Ashton)

 * The `yaml_path` attribute on the Nesta::Config class has been moved
   to `Nesta::ConfigFile.path`. Again, I can't imagine why anybody would
   have written code that used it, but it's a breaking change so I'm
   mentioning it. (Graham Ashton)

 * Support for loading plugins from a local directory (which was deprecated
   in version 0.9.10) has been removed. (Graham Ashton)

 * The local_stylesheet? helper method (deprecated in 0.9.1) has been
   removed. (Graham Ashton)

 * The breadcrumb_label helper method (deprecated in 0.9.3) has been removed.
   (Graham Ashton)

## 0.13.0 (28 September 2022)

 * Update dependencies in order to support Ruby 3.0 and above.
   (Graham Ashton)

 * Upgrade multiple dependencies to fix security vulnerabilities.
   (Graham Ashton)

 * Switch Git repository URLs to HTTPS (fixes the demo:content command).
   (Graham Ashton)

 * Update dependency on Haml; Nesta currently requires a version lower
   than 6.0. (Graham Ashton)

 * Refactor: Extracted logic for running external processes into
   a new `Nesta::SystemCommand` class. (Graham Ashton)

 * Refactor: Created a new `Nesta::Commands::Template` class for
   commands that create files from templates. (Graham Ashton)

 * Refactor: Move logic for editing the config file from within Nesta's
   commands into new `Nesta::ConfigFile` class. (Graham Ashton)

 * Stopped the test suite from executing external commands during tests.
   (Graham Ashton)

## 0.12.0 (30 June 2020)

 * Upgrade to Sinatra 2 and Rack 2. (Graham Ashton)

 * Upgrade from tilt 1.4 to 2.0. (Graham Ashton)

 * Replace the deprecated sass gem with sassc. (Brad Weslake)

 * Port the test suite from RSpec and Webrat to Minitest and Capybara.
   (Graham Ashton)

 * Silence deprecation warnings produced under Ruby 2.7. (Graham Ashton)

 * Stop running the test suite under Ruby 2.3 and 2.4, both of which
   have reached end-of-life. (Graham Ashton)

## 0.11.1 (26 March 2015)

 * Tighten dependency on Tilt, as version 2.x is incompatible.
   (Graham Ashton)

## 0.11.0 (16 March 2015)

 * Allow Haml pages to use the built-in Markdown filter again, by
   including the haml-contrib gem.
   (Jordan Owens)

 * When building the breadcrumb (e.g. "Home > Category > Page") for a
   page whose URL is at the top level of a site, include a page's first
   category in the breadcrumb.
   See https://github.com/gma/nesta/issues/147 for an example.
   (Jordan Owens)

 * Print an error message when one of Nesta's command line tools calls
   an external process (e.g. `git`), but the command doesn't return
   successfully. (Graham Ashton)

 * When the menu.txt pointed to a page that didn't exist, Nesta would
   silently stop generating the menu, and links to pages further down
   the file would be ignored. This is now fixed; the missing page is
   ignored and the rest of the menu is generated. (Jordan Owens)

 * Nesta previously expected all Markdown files to be named with a
   `.mdown` extension. The (commonly used) `.md` extension is now
   supported as well. (Phillip Miller)

 * The Google Analytics JavaScript code has been updated to their
   Universal Analytics version. (Graham Ashton)

 * Relax restrictions on how Nesta can be configured. Previously Nesta
   would only read if `config.yml` file if there weren't any environment
   variables set. This restriction is historic, and unhelpful.
   See https://github.com/gma/nesta/commit/bac50974 for details.
   (Glenn Gillen)

 * Plugins are distributed as gems. We've previously relied upon Bundler
   to generate plugin gems for us, but when Bundler changed the format
   of its generated gems they no longer worked with Nesta. Nesta now
   generates gems from scratch (from a template), which removes our
   dependency on a third party tool.
   (Jordan Owens, Glenn Gillen, Graham Ashton)

 * Support for Ruby 2.2. (Graham Ashton)

## 0.10.0 (25 April 2014)

 * Upgraded the default theme to a responsive design, using Google's
   Roboto Slab web font. (Graham Ashton)

 * Reduced the amount of I/O required to load a page with some judicious
   in memory caching of filenames. Expect a speed boost! (Graham Ashton)

 * Added 'Link text' metadata. When working out how to link to your
   pages from the automatically generated menus and breadcrumbs, Nesta
   uses the page's heading. It still does, but if you want to use
   different words when linking to the page in breadcrumbs or in the
   menu you can by defining the "Link text" metadata. (Micah Chalmer)

   NOTE: Some existing sites may have pages that don't define a heading.
   Those sites will not work with Nesta 0.10.0 until they've been
   upgraded; either add an h1 level heading at the top of your pages
   (preferred) or define the 'Link text' metadata. If you don't want
   h1 headings to appear at the top of your web pages, hide them with
   CSS (this is the best approach for accessibility), or define the
   "Link text" metadata.

 * The text used in the 'Read more' link is now configurable in config.yml.
   The config key is called `read_more`. (Pete Gadomski)

   See the config.yml template (on GitHub) for more details.
   https://github.com/gma/nesta/blob/master/templates/config/config.yml

 * Added the skip-sitemap flag, to prevent a page from being listed in
   the XML sitemap. Add 'Flags: skip-sitemap' to the top of your page to
   enable it. Draft pages have also been removed from the sitemap.
   (Suggested by Joshua Mervine, implemented by Graham Ashton)

 * Added support for user-defined config settings in config.yml.
   If you've ever wanted to add config settings to config.yml and then
   access them from within your app.rb file or templates, this is for
   you.

   There's a new `Nesta::Config.fetch` method for reading these
   settings. It can also read settings from the environment, looking for
   variables whose names are prefixed with "NESTA_". For example, the
   value in the `NESTA_MY_SETTING` variable can be returned by
   calling `Nesta::Config.fetch(:my_setting)`.

   If the setting you're trying to read isn't defined a NotDefined
   exception (a subclass of KeyError) will be raised. Similarly to
   Ruby's Hash#fetch method, you can avoid the exception by specifying a
   second argument (such as nil) that will be returned if the setting
   isn't defined.

   (Sean Redmond, Graham Ashton)

 * The built-in file caching (where Nesta could write generated HTML for
   rendered pages to disk) has been removed. If you'd like to cache
   pages to disk, use the sinatra-cache gem.

   See http://nestacms.com/docs/deployment/page-caching for more
   details, and instructions for installing and testing sintra-cache.

   (Graham Ashton)

 * The nesta script's theme:create command now copies default templates
   into a new theme. (Jake Rayson)

 * Added the --zsh-completion option to the nesta command, which outputs
   code that will configure command line completion in Zsh for the nesta
   command. (Wynn Netherland)

 * Page titles no longer include the heading from the parent page.
   Behaviour was a little inconsistent, and it's arguably not a great
   feature in the first place. Since the Title metadata appeared you can
   ovverride the page title to something more useful if you need to too.
   (Graham Ashton)

 * When commenting via Disqus is configured, comments appeared on every
   page in earlier versions of Nesta. From now on only pages with a date
   set (i.e. articles) will display the comment form by default. If
   you've copied the comments.haml template into your ./views folder (or
   into a theme) you'll need to modify it slightly. See the `if`
   statement in the latest version.

   If you'd actually like comments to appear on every page of your site,
   redefine the Page#receives_comments? method in your app.rb file, so
   that it returns `true`.

   (Graham Ashton)

 * Breadcrumbs include Microdata for use by search engines. See:
   http://support.google.com/webmasters/bin/answer.py?hl=en&answer=185417
   (Sean Schofield)

 * The menu and breadcrumb helper methods can now generate HTML that
   identifies the current page. When viewing a page that appears in the
   menu, its menu item will have the class "current". To change the name
   of the class, override the Nesta::Navigation::current_menu_item_class
   method.

   The current page doesn't have a class applied by default. If you want
   to add a class to style it, override the ::current_breadcrumb_class
   method (also in the Nesta::Navigation module), returning a string.

   (Pete Gadomski)

 * Version 0.9.13 used Sinatra's `url` helper method to generate links
   to pages on the site. When these pages were cached by proxy servers
   the hostname in the URL could be set incorrectly, as it would be
   determined from the HTTP headers (see issue #103 for more details).

   The solution was to link to pages on the current site using an
   absolute path, rather than a full URL. The `path_to` helper was added,
   and used in place of Sinatra's `url` helper method.

   (Micah Chalmer)

 * Updated the test suite from RSpec 1.3 to RSpec 2.
   (Wynn Netherland, Graham Ashton)

 * Support for Ruby 1.8 has been dropped. Ruby 1.9.3 or above is
   recommended.

 * There were also plenty of small bug fixes that didn't make it into
   this list. See GitHub for the full list of commits.
   https://github.com/gma/nesta/compare/v0.9.13...v0.10.0

## 0.9.13 (3 March 2012)

 * The nesta script has a new command; edit. You can pass it the path
   to a file within your content/pages folder and it will open the file
   in your default editor (as set by the EDITOR environment variable).

 * The nesta script has a new option; --bash-completion. Run nesta with
   this option and it will print some Bash that will configure command
   line completion for the nesta command.

   You can type `nesta edit <TAB>` and Bash will complete the names of
   the files in your content/pages directory. :-)

   Installation instructions at the top of the Bash script.

 * Nesta can now be mounted cleanly at a path, rather than at a site's
   root, and assets and links will be served correctly.
   (Max Sadrieh, Graham Ashton)

 * The default config.ru file that is generated when you create a new
   project now enables Etag HTTP headers. (Max Sadrieh)

 * Two helper methods have been removed; url_for and base_url. Use
   Sinatra's url helper instead. They would have been deprecated rather
   than removed, but if you try and load Nesta's helpers in a Rails app
   url_for breaks Rails's rendering. (Max Sadrieh, Graham Ashton)

 * The Page class has a new method; body_markup. It can be overridden by
   a plugin, and is used by the foldable plugin. (Micah Chalmer)

 * The `current_item?` helper has been created in `Nesta::Navigation`.
   You can override it to implement your own logic for determining
   whether or not a menu item rendered by the menu helpers are
   considered to be "current". (Chad Ostrowski)

 * The FileModel class has a new method; parse_metadata. It can be
   overriden by plugins that implement an alternate metadata syntax.
   Used by the yaml-metadata plugin.

 * Erb templates in your ./views folder, or in a theme's folder, will
   now be found when you call Sinatra's erb helper method.

 * config.yml can now contain Erb (and therefore inline Ruby), which
   will be interpreted when loaded. (Glenn Gillen)

 * Extended the `nesta` command to support new commands that could (for
   example) be added by a plugin. The class to be instantiated within
   the Nesta::Commands module is determined from the command line
   argument (e.g. `nesta plugin:create` will instantiate the class
   called Nesta::Commands::Plugin::Create).

 * Bug fix: Don't crash if a page's metadata only contains the key, with
   no corresponding value. You could argue this wasn't a bug, but the
   error message was difficult to trace. See #77.

 * Bug fix: Summaries on Haml pages were not marked up as paragraphs.
   See #75.

## 0.9.12 (Released then pulled, due to rubygems [still] being a total mess)

## 0.9.11 (22 September 2011)

 * Use Tilt to render the Markdown, Textile and Haml in content/pages.
   RDiscount is now the default Markdown processor. To continue using
   Maruku add it to Gemfile and call `Tilt.prefer Tilt::MarukuTemplate`
   in your app.rb file.

 * Remove trailing slashes from all URLs, redirecting to the URL without
   the slash. See ticket #60 on GitHub.

 * Added the 'Articles heading' metadata key. When articles are listed
   on a category page, Nesta adds a heading above the articles based on
   the category's title (e.g. "Articles on Thing").  If you set the
   'Articles heading' metadata Nesta will allow you to override the
   entire heading for a given page.

 * Bug fix: require nesta/plugin automatically on load. The
   Nesta::Plugin.register method is called by plugins as soon as they
   are loaded, so we need to make it available. In 0.9.10 this method
   wasn't available until too late.

 * Bug fix: Minor updates to the files generated by `nesta plugin:create`.

 * Bug fix: Don't allow retrieval of the contents of any file
   within the content folder by crafting a relative path containing
   the string '../' (Louis Nyffenegger).

## 0.9.10 (9 September 2011)

 * Load Nesta plugins from gems. Any gem whose name begins with
   nesta-plugin- can be used in a project by adding it to the project's
   Gemfile beneath the `gem "nesta"` line. New plugins can be created
   with the `nesta plugin:create` command.

 * Mark pages as draft by setting a flag. Draft pages won't be shown in
   production, but will be visible on your local copy of your site (as
   it's running in production).

 * Upgraded Sinatra to version 1.2.6. Upgraded other dependencies to
   latest compatible versions.

 * Bug fix: The `stylesheet` helper method assumes that you're using
   the Sass rendering engine by default, which allows it to find .sass
   files within the gem if no matching files are found locally.

## 0.9.9 (24 August 2011)

 * Bug fix: What a debacle this is turning into. The new Nesta::Env
   class must be required before the code in 'nesta/app' is loaded.
   The previous release only loaded Nesta::Env when your started Nesta
   via config.ru. Running Nesta any other way lead to an immediate
   crash.

## 0.9.8 (22 August 2011)

 * Bug fix: The Sinatra app's root directory wasn't set which meant
   that Nesta couldn't always find the ./public directory (such as when
   running on Heroku).

   The modifications made in 0.9.6 to make Nesta easier to mount inside
   another Rack application moved Nesta::App.root to the (new)
   Nesta::Env class. In 0.9.6 I forgot to actually set Nesta::App.root
   as well, which was a big mistake. Whoops.

## 0.9.7 (19 August 2011)

 * No code changes from 0.9.6; version number increased to allow new gem
   to be deployed to rubygems.org.

## 0.9.6 (18 August 2011) [never released due to packaging bug]

 * Nesta no longer cares whether you write your Sass stylesheets in the
   original indented Sass format or the default SCSS syntax (which is a
   superset of CSS). To use this functionality within your own site or
   theme change change any calls to the existing `sass` or `scss`
   helpers to `stylesheet`. (Isaac Cambron, Graham Ashton)

 * Add an HTML class ("current") to the menu items whose path matches
   the current page.

 * Bug fix: Strip trailing # characters from Markdown headings at the
   top of a page.

 * Bug fix: Don't render the return value of local_stylesheet_link_tag
   directly into the page (haml_tag now writes direct to the output
   buffer).

 * Bug fix: Removed trailing whitespace inside <a> tags generated by
   the display_breadcrumbs() helper.

 * Bug fix: Nesta::App.root couldn't be set until after nesta/app was
   required. Odd that, as the only reason to want to change
   Nesta::App.root would be before requiring nesta/app. Fixed by
   creating Nesta::Env and moving root to there instead.

## 0.9.5 (1 May 2011)

 * Added --version option to nesta command (Christopher Lindblom).

 * Upgraded Haml and Sass to version 3.1 (Andrew Nesbitt).

 * Updated the URL from which the Disqus JavaScript is loaded
   (Sidharta Surya Kusnanto).

 * Bug fix: Don't use parent's heading in page title if parent's heading
   is blank (Christopher Lindblom).

 * Bug fix: Removed trailing whitespace inside <a> tags generated by
   the display_menu() helper.

 * Bug fix: Made article_summaries render summaries for the pages
   passed into it (Robert Syme).

 * Bug fix: Empty files in the content directory would cause the site to
   crash - they are now served properly.

 * Bug fix: When pages written in Haml were included on a category page
   the default theme didn't provide access to Sinatra's helper methods
   within Haml templates. See https://github.com/gma/nesta/pull/18
   (Carl Furrow).

## 0.9.4 (18 February 2011)

 * Updated the link colours in the default theme.

 * Set the default encoding to UTF-8. Without it Heroku would sometimes
   fail to render pages (issue 14).

## 0.9.3 (18 January 2011)

 * The route and view for serving the home page (/) has been removed,
   and the home page must now be created as an index page in
   content/pages.

   You will have to create `content/pages/index.haml` manually when
   upgrading. Running `nesta new mysite.com` will create a
   `content/pages/index.haml` file that is suitable for a blog.

 * The URL /my-page can be served from `pages/my-page/index.mdown` as
   well as pages/my-page.mdown (index pages can also be created with
   Textile or Haml, just like any other page).

 * The description and keywords settings have been removed from
   config.yml as they can now be set on `content/pages/index.haml`.

 * Added the Title metadata key to override a page's default title tag.

 * Specify the sort order of pages that are listed on a category page.
   Optionally append a colon and a number to a path in the 'Categories'
   metadata to control the sort order of pages listed on the category
   page.

   See these files for the syntax:
   https://github.com/gma/nesta-demo-content/tree/master/pages/examples

 * Support arbitrarily deep hierarchies when generating the breadcrumb
   (see the new helper method added to Nesta::Navigation).

 * Dropped the --heroku switch (Heroku runs fine without it and there is
   less chance that committing config.yml to your repository will be an
   issue now that Nesta sites live in their own repositories).

 * Re-implemented /articles.xml and /sitemap.xml in Haml, dropping the
   dependency on builder. This side steps a bug in Ruby 1.9.1, so Nesta
   can now run on 1.9.1 again. Also fixed a validity error in the Atom
   feed.

 * Bug fix: Don't output empty <li> tags for nested submenus that are
   beneath the requested number of levels.

## 0.9.2 (10 January 2011)

 * Made the FileModel.metadata method public, to allow for custom
   metadata at the top of each page. (Wynn Netherland)

 * Relaxed the stringent dependency specifications, using pessimistic
   version constraints (see http://docs.rubygems.org/read/chapter/16).

 * Added templates required by `nesta theme:create`.

## 0.9.1 (31 December 2010)

 * Re-implemented the default theme, using semantic HTML5 and
   Andy Clarke's Universal Internet Explorer 6 CSS. Named the previous
   default theme "slate" and moved it into a separate GitHub project.
   https://github.com/gma/nesta-theme-slate

 * Added `--git` switch to `nesta new`, that will create a new git
   repository and make an initial commit.

 * Moved the navigation helpers into the Nesta::Navigation::Renderers
   module.

## 0.9.0 (20 December 2010)

 * Packaged Nesta as a gem for the first time, instead of as a template
   site that can be cloned, edited and deployed. Added the `nesta`
   command for generating new sites and managing themes.

## Previous versions (from 26 November 2008)

 * Prior to 0.9.0 Nesta was distributed as a git repository that could
   be forked, edited and deployed. The only change log for these
   versions is the commit history:

   https://github.com/gma/nesta/commits/master
