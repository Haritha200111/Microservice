FROM golang:1.23.4 AS builder
WORKDIR /app
COPY . .
RUN go build -o main .

FROM alpine:3.17
WORKDIR /root/
COPY --from=builder /app/main .
CMD ["./main"]
