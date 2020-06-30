# Releasing Nesta

When it comes time to release a new version of the Nesta gem, these are
the steps:

1. Bump the version number in `lib/nesta/version.rb`. This will cause
   the version number in `Gemfile.lock` to be updated too, so regenerate
   it now and check them in together.

2. Update the `CHANGES` file with a summary of significant changes since
   the previous release.

3. Commit these changes with a commit message of 'Bump version to <version>'

4. Check the versions of Ruby used in `.travis.yml` are up to date. If new
   Ruby versions need testing, update the config and re-run the Travis build.

5. Generate a new site with the `nesta` command, install the demo content,
   check that it runs okay locally.

6. If everything seems fine, run `rake release`.

7. Publish an announcement blog post and email the list.
