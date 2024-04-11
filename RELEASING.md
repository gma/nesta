# Releasing Nesta

When it comes time to release a new version of the Nesta gem, these are
the steps:

1. Check the versions of Ruby used in `.github/workflows` are up to date. If
   new Ruby versions need testing, update the config and re-run the build.

2. Bump the version number in `lib/nesta/version.rb`. This will cause
   the version number in `Gemfile.lock` to be updated too, so regenerate
   it now (e.g. run `bundle install`) and check them in together.

3. Update the `CHANGLOG.md` file with a summary of significant changes since
   the previous release.

4. Commit these changes with a commit message of 'Bump version to <version>'

5. Install the gem locally (`rake install`), then generate a new site
   with the `nesta` command. Install the demo content site, check that
   it runs okay locally.

6. If everything seems fine, run `rake release`.

7. Publish an announcement blog post and email the list.
