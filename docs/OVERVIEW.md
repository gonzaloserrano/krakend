# Overview

## The KrakenD rules

* [Reactive is key](http://www.reactivemanifesto.org/)
* Reactive is key (yes, it is very very important)
* Failling fast is better than successing slowly (say it one more time!)
* The simplest, the better
* Everything is plugglable
* Each request must be processed in its own request-scoped context

## The big picture

The KrakenD framework is composed by a set of packages designed as builging blocks for creating pipes and processors between an exposed endpoint and one or several API resources served on your backends.

The most important packages are:

1. the `config` package defines the service.
2. the `router` package sets up the enpoints exposed to the clients.
3. the `proxy` package adds the required middlewares and components to further process the requests to send and the received responses, and to manage the connections against the backends. 

The rest of the packages of the framework contain some helpers and adapters for complementary tasks, like encoding, logging or service discovery.

## The `config` package

The `config` package contains the structs required for the service description.

The `ServiceConfig` struct defines the entire service. It should be initialized before using it in order to be sure all parameters has been normalized and default values has been applied.

The `config` package also defines an interface for a file config parser and a parser based on the [viper](https://github.com/spf13/viper) library.

## The `router` package

The `router` package contains an interface and several implementations for the KrakenD router layer using the `mux` router from the `net/http` and the `httprouter` wrapped in the `gin` framework.

The router layer is responsible for setting up the http(s) services, bind the endpoints defined at the `ServiceConfig` struct and transform the http request into proxy requests before delegating the task to the inner layer (proxy). Once the internal proxy layer returns a proxy response, the router layer converts it into a proper http response and sends it to the user.

This layer can be easily extended in order to use any http router, framework or middleware of your choice. Adding transport layer adapters for other protocols (thrift, gRPC, amqp, nats, etc) is in the roadmap. As always, PR are welcome!

## The `proxy` package

The `proxy` package is where the most part of the KrakenD components and features are placed. It defines two important interfaces, designed to be stacked:

* *Proxy* is a function that converts a given context and request into a response.
* *Middleware* is a function that accepts one or more proxies and returns a single proxy wrapping them.

This layer transforms the request received from the outter layer (router) into a single or several requests to your backend services, processes the responses and returns a single response.

Middlewares generates custom proxies that are chained depending on the workflow defined in the configuration until each possible branch ends in a transport-related proxy. Every one of these generated proxies is able to transform the input or even clone it several times and pass it or them to the next element in the chain. Finaly, they can also modify the received response or responses adding all kinds of features to the generated pipe.

The KrakenD framework provides a default implementation of the proxy stack factory

### Middlewares available

* The `balancing` middleware uses some type of strategy for selecting a the backend host to query
* The `concurrent` middleware improves the QoS by sending several concurrent requests to the next step of the chain and returning the first succesful response using a timeout for cancelling the generated work load.
* The `logging` middleware logs the received request and response and also the duration of the segment execution
* The `merging` middleware is a frok-and-join middleware. It is intended to split the process of the request into several concurrent processes, each one against a different backend, and to merge all the received responses from those created pipes into a single one. It applies a timeout, as the `concurrent` one does.
* The `http` middleware completes the received proxy request by replacing the params extracted from the user request in the defined `URLPattern`

### Proxies available

* The `http` proxy translates a proxy request into a HTTP one, sends it to the backend API using a `HTTPClientFactory`, decodes the returned HTTP response with a `Decoder`, manipulates the response data with an `EntityFormatter` and returns it to the caller.

### Other components of the `proxy` package

The `proxy` package also defines the `EntityFormatter`, the block responsible for enabling a powerful and fast response manipulation