FROM alpine:latest
WORKDIR /
COPY ./*.sh ./
RUN ./envdump.sh build
CMD [ "/envdump.sh", "default" ]
