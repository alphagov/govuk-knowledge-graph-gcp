FROM ruby:3.4.2-bookworm

WORKDIR /usr/src/app
COPY Gemfile* .

RUN bundle install

COPY . .

# Run the web service on container startup.
ENTRYPOINT ["bundle", "exec", "functions-framework-ruby", "--target", "data_loss_prevention"]
