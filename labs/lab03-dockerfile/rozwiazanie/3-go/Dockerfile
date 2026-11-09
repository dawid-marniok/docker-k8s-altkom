# etap 1: kompilacja
FROM golang:1.25 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /hello .

# etap 2: tylko gotowy plik wykonywalny
FROM gcr.io/distroless/static-debian12
COPY --from=build /hello /hello
EXPOSE 8080
USER nonroot
CMD ["/hello"]
