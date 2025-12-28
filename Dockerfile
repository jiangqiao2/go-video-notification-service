FROM golang:1.24-alpine AS builder
WORKDIR /app

# Base dependencies
RUN apk add --no-cache ca-certificates tzdata
# Use Go module proxy for China mainland
ENV GOPROXY=https://goproxy.cn,direct

# First copy go.mod/go.sum and download deps to leverage build cache
COPY go.mod go.sum ./
RUN go mod download

# Copy application source
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /bin/notification-service ./main.go

FROM alpine:3.19
WORKDIR /app

RUN apk add --no-cache tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone

COPY --from=builder /bin/notification-service /usr/local/bin/notification-service
# Copy configs
COPY --from=builder /app/configs ./configs

ARG CONFIG_PATH=/app/configs/config.dev.yaml
ENV CONFIG_PATH=${CONFIG_PATH}
EXPOSE 8086
ENTRYPOINT ["notification-service"]
