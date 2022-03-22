FROM ruby:3.0-slim

RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y

RUN apt-get install git -y

# COPY Gemfile Gemfile.lock nesta.gemspec nesta/version.rb ./
COPY . ./

RUN bundle install

WORKDIR /usr/src/app

ENTRYPOINT ["bundle", "exec"]
CMD ["rake", "test"]
