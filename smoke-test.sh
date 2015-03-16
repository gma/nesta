#!/bin/sh

# This script just makes it easy to test that Nesta can install a new
# site, launch it, and that it runs properly on supported versions of
# Ruby.
#
# It assumes you've got the relevant versions of Ruby installed locally
# via chruby.


source /usr/local/opt/chruby/share/chruby/chruby.sh

RUBIES="ruby-2.0.0-p451 ruby-2.1.3 ruby-2.2.1"


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

run_with_ruby()
{
    chruby-exec $RUBY_VERSION -- $@
}

get_ruby()
{
    # Why not just use RUBY_VERSION? Because tmux can prevent child
    # processes from changing the local version if the RBENV_VERSION
    # variable is set in another session. If we don't notice we'll think
    # we've been testing Nesta under multiple versions, but in fact
    # we'll just have been testing it under the same copy of Ruby every
    # time.
    run_with_ruby ruby --version | cut -f 2 -d ' '
}

run_tests()
{
    run_with_ruby bundle install
    run_with_ruby bundle exec rake spec
}

build_and_install()
{
    echo rm -f pkg/$(gem_file)
    run_with_ruby bundle install
    run_with_ruby bundle exec rake install
}

site_folder()
{
    echo "test-site-${RUBY_VERSION}"
}

create_and_test_new_site()
{
    run_with_ruby bundle exec nesta new $(site_folder)
    cd $(site_folder)
    echo "gem 'haml-contrib'" >> Gemfile
    run_with_ruby bundle install
    run_with_ruby bundle exec nesta demo:content

    log "Starting server in $(site_folder)"
    set +e
    run_with_ruby bundle exec mr-sparkle
    set -e

    cd - >/dev/null
    rm -rf $(site_folder)
}


## Main program

set -e
[ "$DEBUG" ] && set -x

for RUBY_VERSION in $RUBIES; do
    log "Rebuilding nesta gem with Ruby $(get_ruby)"

    run_tests
    build_and_install
    create_and_test_new_site

    read -p "Was Ruby ${RUBY_VERSION} okay? Press return to continue..."
done

rm -f .ruby-version
log "Reset Ruby version to $(get_ruby)"
