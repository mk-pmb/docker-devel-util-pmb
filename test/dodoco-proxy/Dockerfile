FROM alpine:latest
WORKDIR /
COPY ./envdump.sh .
RUN ./envdump.sh build
CMD [ "/envdump.sh", "default" ]
