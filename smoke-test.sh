#!/bin/sh

# This script just makes it easy to test that Nesta can install a new
# site, launch it, and that it runs properly on supported versions of
# Ruby.
#
# It assumes you've got the relevant versions of Ruby installed locally
# via rbenv.


RUBIES="1.9.3-p392 2.0.0-p353 2.1.0 2.1.1"


## Functions

log()
{
    cat <<-EOF

###############################################################################
##
## $1
##
###############################################################################

EOF
}

nesta_version()
{
    grep VERSION lib/nesta/version.rb | sed -e 's/ //g' | cut -f 2 -d "'"
}

gem_file()
{
    echo "nesta-$(nesta_version).gem"
}

get_ruby()
{
    # Why not just use RUBY_VERSION? Because tmux can prevent rbenv from
    # changing the local version if the RBENV_VERSION variable is set in
    # another session. If we don't notice we'll think we've been testing
    # Nesta under multiple versions, but in fact we'll just have been
    # testing it under the same copy of Ruby every time.
    ruby --version | cut -f 2 -d ' '
}

run_tests()
{
    bundle install
    bundle exec rake spec
}

build_and_install()
{
    echo rm -f pkg/$(gem_file)
    bundle install
    bundle exec rake install
}

site_folder()
{
    echo "test-site-${RUBY_VERSION}"
}

create_and_test_new_site()
{
    bundle exec nesta new $(site_folder)
    cd $(site_folder)
    echo "gem 'haml-contrib'" >> Gemfile
    bundle install
    bundle exec nesta demo:content

    log "Starting server in $(site_folder)"
    set +e
    bundle exec mr-sparkle
    set -e

    cd - >/dev/null
    rm -rf $(site_folder)
}


## Main program

set -e
[ -n "$DEBUG" ] && set -x

for RUBY_VERSION in $RUBIES; do
    rbenv local $RUBY_VERSION
    log "Rebuilding nesta gem with Ruby $(get_ruby)"

    run_tests
    build_and_install
    create_and_test_new_site

    read -p "Was Ruby ${RUBY_VERSION} okay? Press return to continue..."
done

rm -f .ruby-version
log "Reset Ruby version to $(get_ruby)"
