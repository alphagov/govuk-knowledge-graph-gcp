FROM ruby:4.0.7-bookworm

WORKDIR /usr/src/app
COPY Gemfile* .

RUN bundle install

COPY . .

# Run the web service on container startup.
ENTRYPOINT ["bundle", "exec", "functions-framework-ruby", "--target", "govspeak_to_html"]
