FROM gliderlabs/alpine:3.2
RUN apk --update add python py-pip bash git \
  && pip install mkdocs
ADD ./scripts/* /bin/
WORKDIR /project
EXPOSE 8000
