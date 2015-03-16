# Releasing Nesta

When it comes time to release a new version of the Nesta gem, these are
the steps:

1. Bump the version number in `lib/nesta/version.rb`. This will cause
   the version number in `Gemfile.lock` to be updated too, so regenerate
   it now and check them in together.

2. Update the `CHANGES` file with a summary of significant changes since
   the previous release.

3. Update the versions of Ruby used in `.travis.yml` and
   `smoke-test.sh`. If not, commit and push. Verify that all relevant
   versions of Ruby have been installed locally, with `chruby`.

4. Run `smoke-test.sh`.

5. Once you're confident the freshly generated sites work okay in the
   previous step, run `rake release`.

6. Publish an announcement blog post and email the list.
