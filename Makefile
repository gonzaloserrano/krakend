.PHONY: all deps test build run benchmark cover

all: deps test build

deps:
	go get -u github.com/gin-gonic/gin
	go get -u github.com/spf13/viper
	go get -u github.com/op/go-logging

test:
	go fmt ./...
	go test -cover ./...
	go vet ./...

benchmark:
	go test -bench=. -benchtime=3s ./...

build: build_gin_example build_mux_example

build_gin_example:
	cd examples/gin/ && make && cd ../.. && cp examples/gin/krakend_gin_example* .

build_mux_example:
	cd examples/mux/ && make && cd ../.. && cp examples/mux/krakend_mux_example* .
