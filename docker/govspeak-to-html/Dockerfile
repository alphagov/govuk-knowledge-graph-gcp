FROM ruby:3.2.7-alpine3.20

WORKDIR /usr/src/app
COPY Gemfile* .

RUN bundle install

COPY . .

# Run the web service on container startup.
ENTRYPOINT ["bundle", "exec", "functions-framework-ruby", "--target", "parse_html"]
