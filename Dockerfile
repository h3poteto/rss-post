FROM ruby:3.3.1-slim

ADD . /app

WORKDIR /app

RUN bundle install

CMD ["bundle", "exec", "ruby", "hatena.rb"]
