FROM ruby:2.5

RUN apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y

COPY . ./

RUN bundle install

WORKDIR /usr/src/app

ENTRYPOINT ["bundle", "exec"]
CMD ["rake", "test"]
