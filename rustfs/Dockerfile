FROM rustfs/rustfs:latest

# RustFS serves each top-level directory under its data dir as a bucket
RUN mkdir -p /data/ytown-listings

EXPOSE 9000 9001

VOLUME ["/data"]

CMD ["--address", ":9000", "--console-address", ":9001", "/data"]
