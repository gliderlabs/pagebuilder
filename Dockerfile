FROM gliderlabs/alpine:3.2
RUN apk --update add python py-pip bash openssh-client git \
  && pip install mkdocs \
  && git config --global user.email "team@gliderlabs.com" \
  && git config --global user.name "Gliderbot" \
  && ln -s /root /home/ubuntu
ADD ./scripts/* /bin/
WORKDIR /project
EXPOSE 8000
