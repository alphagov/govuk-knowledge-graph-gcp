FROM ruby:3.4.2-alpine3.21

# build-base is needed for bundle to install ruby gems
RUN apk --no-cache add \
    build-base \
    pandoc-cli

WORKDIR /usr/src/app
COPY Gemfile* ./

RUN bundle install

COPY . ./

# Run the web service on container startup.
ENTRYPOINT ["bundle", "exec", "functions-framework-ruby", "--target", "html_to_text"]
