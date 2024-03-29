FROM --platform=${TARGETPLATFORM:-linux/amd64} openfaas/of-watchdog:0.8.0 as watchdog
FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.13-alpine3.11 as build

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN apk --no-cache add git

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

ENV CGO_ENABLED=0

RUN mkdir -p /go/src/handler
WORKDIR /go/src/handler
COPY . .

# Add user overrides to the root go.mod, which is the only place "replace" can be used
RUN cat function/GO_REPLACE.txt >> ./go.mod || exit 0

# Run a gofmt and exclude all vendored code.
RUN test -z "$(gofmt -l $(find . -type f -name '*.go' -not -path "./vendor/*" -not -path "./function/vendor/*"))" || { echo "Run \"gofmt -s -w\" on your Golang code"; exit 1; }

ARG GO111MODULE="off"
ARG GOPROXY=""
ARG GOFLAGS=""
ARG GOPRIVATE="github.com/BillotP"
# Setup Go private package
ARG CI_USER=${CI_USER}
ARG CI_TOKEN=${CI_TOKEN}
ENV CI_TOKEN=$CI_TOKEN \
    CI_USER=$CI_USER
RUN echo -e "\n\
 machine gitlab.com\n\
   login $CI_USER\n\
   password $CI_TOKEN\n\
 " >> /root/.netrc
# Setup Go needed test secrets
ARG arango_host
ARG arango_port
ARG arango_scheme
ARG arango_user
ARG arango_password
ARG arango_dbname
ARG arango_tlsverify
ARG jwt_private_key
ARG jwt_public_key
ARG xsrf_token_seed
ARG jwt_issuer
ARG jwt_audience
ARG jwt_key_id
ARG jwt_expiracy

WORKDIR /go/src/handler/function

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go test ./... -cover

WORKDIR /go/src/handler
RUN CGO_ENABLED=${CGO_ENABLED} GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build --ldflags "-s -w" -a -installsuffix cgo -o handler .

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.11
# Add non root user and certs
RUN apk --no-cache add ca-certificates \
    && addgroup -S app && adduser -S -g app app \
    && mkdir -p /home/app \
    && chown app /home/app

WORKDIR /home/app

COPY --from=build --chown=app /go/src/handler/handler    .
COPY --from=build --chown=app /usr/bin/fwatchdog         .
COPY --from=build --chown=app /go/src/handler/function/  .

USER app

ENV fprocess="./handler"
ENV mode="http"
ENV upstream_url="http://127.0.0.1:8082"

CMD ["./fwatchdog"]
