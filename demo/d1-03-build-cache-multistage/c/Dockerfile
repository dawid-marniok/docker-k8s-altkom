# Multi-stage: kompilujemy w jednym etapie, do obrazu końcowego trafia tylko binarka.
FROM alpine:3.22 AS build
RUN apk add --no-cache build-base
WORKDIR /src
COPY hello.c .
RUN gcc -static -O2 -o /hello hello.c

FROM scratch
COPY --from=build /hello /hello
CMD ["/hello"]
