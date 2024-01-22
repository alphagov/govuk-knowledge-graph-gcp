FROM ruby:3.3.0-alpine3.19

RUN apk --no-cache add \
    build-base \
    chromium \
    chromium-chromedriver

ENV CHROMEDRIVER_PATH /usr/bin/chromedriver
ENV CHROME_BIN /usr/bin/chromium-browser

WORKDIR /usr/src/app
COPY Gemfile* .

RUN bundle install

COPY . .

# Run the web service on container startup.
ENTRYPOINT ["bundle", "exec", "functions-framework-ruby", "--target", "parse_html"]
