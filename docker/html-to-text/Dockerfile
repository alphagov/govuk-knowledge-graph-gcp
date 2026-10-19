FROM ruby:4.0.7-alpine

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
