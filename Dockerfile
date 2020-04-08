FROM buildkite/puppeteer:v1.15.0

COPY src/index.js src/default_config.json /app/

WORKDIR /app

CMD node /app/index.js
