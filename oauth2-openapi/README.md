# OAuth 2.0 Fine-Grained API Authorization with Gate and OpenAPI

Protect your API against unauthorized access **without changing your application**. 
Our newest Gate plugin automatically enforces OpenAPI security checks, so you can implement fine-grained access control for your APIs and workloads without writing any extra code.

## Quick Start
The guide below provides context and a deeper-dive on how to set up OAuth 2.0 Client Credentials and enforce OAuth 2.0 scopes using an OpenAPI spec and Gate. 
To see this in action, you can follow these quick steps: 

1. Create a free account at https://console.slashid.dev/signup 
2. Navigate to https://console.slashid.dev/configuration/general to note down the Organization ID and to generate an API Key for SlashID
2. Run `docker-compose pull` to get the latest images
3. Make sure you have `curl` and `jq` installed and create a client ID/secret pair with SlashID using `./create_client.sh <Organization ID> <API Key>`
4. Set the client ID and secret in `gate.yaml`
5. Use the client ID/secret to calculate the basic authorization header with `./request_token.sh <client_id> <client_secret>`. Note down the access token, as it will be used as the bearer for future requests. This script requests a token with `customers:read` and `customers:create` scopes
6. Run `docker-compose up` to start Gate and the backend server

You can now make requests to `http://localhost:5000`.

**Note that for this example we are using an echo server, which means it does not implement the API described above, but is sufficient to demonstrate that the security schemes are being enforced.**

Let's see it in action: 

```bash
curl -X POST http://localhost:5000/customers -H "Authorization: Bearer <access_token>" --data '{ "customer_name": "test_customer", "customer_tax_id": "4"}'
< HTTP/1.1 200 OK
< Content-Length: 605
< Content-Type: text/plain
< Date: Tue, 14 Nov 2023 12:24:28 GMT
< Via: 1.0 gate
< 
...
{ "customer_name": "test_customer", "customer_tax_id": "4"}

```
We receive a 200 because we are authorized to create a customer - the access token has the correct scopes for the operation. Now let's try to delete a customer:

```bash
curl -X DELETE -v http://localhost:5000/customers/4 -H "Authorization: Bearer <access_token>" 
*   Trying 127.0.0.1:5000...
* Connected to localhost (127.0.0.1) port 5000 (#0)
> DELETE /customers/4 HTTP/1.1
> Host: localhost:5000
> User-Agent: curl/7.87.0
> Accept: */*
> Authorization: Bearer <access_token>
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 403 Forbidden

```
The request was forbidden because we lack the correct scope to delete a customer. 

You can customize the `request_token` and `openapi_customers.yaml` files to experiment with different scopes and different enforcement policies!

## Introduction

The [latest plugin for SlashID Gate](https://developer.slashid.dev/docs/gate/plugins/enforce-openapi-security)
enforces all the security schemes defined in an OpenAPI document.
You can keep your OpenAPI document as the single source of truth for describing your API, and deploy Gate at the edge
to make sure all of your security schemes are fully enforced before a request reaches your service.
Did your API change? No problem - just roll out a new Gate deploy with the updated specification.

In this guide we'll explain the advantages of using OAuth 2.0 to secure your APIs, how you can describe this in an
OpenAPI document, and how to use Gate to enforce it - all without writing a single line of code.
This plugin works with any OAuth 2.0 provider, but for this example we'll use SlashID, as it only takes a few minutes to
get up and running with OAuth 2.0 client credentials.

## Background

Long-lived and overly privileged API keys are one of the primary sources of data breaches today.
As a result, enterprise companies' RFPs are increasingly requiring vendors to protect their APIs using two-legged or three-legged OAuth 2.0 flows with fine-grained access control.

In this guide, we'll demonstrate how to quickly add and enforce client credentials for your APIs to comply with
two-legged OAuth 2.0 flow requirements, including out-of-the-box fine-grained access control.

While there are many choices of Authorization Server, including SlashID, that can provision client credentials and access tokens,
SlashID is the only solution that also enforces access token validation for protected resources.

In this section we provide an overview of OAuth 2.0 Client Credentials and the OpenAPI specification.
If you are already familiar with these topics, feel free to skip them.

### OAuth 2.0 Client Credentials Flow

The OAuth 2.0 specification defines multiple authentication flows. One of the simplest is the [**client credentials** flow](https://oauth.net/2/grant-types/client-credentials/):

- Request an access token from the Authorization Server using client credentials (for example, an ID and secret)
- Make a request to the Resource Server that includes the access token
- Resource Server validates the token
- Resource Server responds with requested data or an error depending on the outcome.

This flow is well-suited to machine-to-machine (M2M) authentication as there is no user interaction required (unlike
other OAuth 2.0 flows). The client credentials flow offers two significant advantages over API keys, which are often
used for M2M authentication scenarios:

- Access tokens are typically short-lived
- Client credentials and access tokens are scoped by specification, meaning they have limited permissions.

Both of these features reduce the risk and limit the potential damage from credential theft, and help to enforce the
principle of least privilege, which is essential for both security and compliance.

Implementing a system that uses this flow to protect endpoints comes with challenges. While there are many choices of
Authorization Server (including SlashID) that can provision client credentials and access tokens, it is up to the
maintainer of the protected resource to correctly check access tokens. This means every endpoint needs
to validate an access token and its scope before deciding whether the request is allowed, and this logic needs to be kept
up to date and consistent with changing API requirements. A single missed scope can leave a sensitive API exposed to
clients that should not have access.

### OpenAPI

The [OpenAPI specification](https://www.openapis.org/) is an interface definition language for describing web services.
OpenAPI 3.0 and its predecessor Swagger are two of the [most popular technologies](https://www.postman.com/state-of-api/api-technologies/#api-technologies)
when working with APIs. An OpenAPI specification can completely describe your API, and is useful both as a source of truth
while developing and for generating code.

In particular, OpenAPI supports security schemes, which are used to describe how a given endpoint should be authorized.
OpenAPI supports HTTP, API key, OAuth 2.0, and OIDC security, each with their own set of fields. OAuth 2.0 security schemes
include a set of scopes that are required for a given operation (method on an endpoint) to be allowed.

However, this too presents implementation challenges - you need to make sure that your API server correctly enforces the latest
security schemes for each endpoint. Generated code can help with this, but again, a small mistake can leave sensitive
APIs exposed.

## Gate to the Rescue

How do you take advantage of the security of client credentials and the convenience of an OpenAPI specification while
making sure that security schemes are always correctly enforced? Enter Gate, SlashID's identity-aware authorization
service. Gate is flexible and simple-to-use, and can be deployed as a standalone proxy or as a sidecar to
your existing API gateway. Gate is part of a growing movement towards authentication/authorization at the edge, which
is being embraced by [organizations that are serious about security](https://www.slashid.dev/products/gate/).
For more information on Gate, check our [documentation](https://developer.slashid.dev/docs/gate).

By enforcing the security schemes in an OpenAPI document, our [new OpenAPI security plugin](https://developer.slashid.dev/docs/gate/plugins/enforce-openapi-security)
solves both of the problems described above (and more). Let's see this in action.

## Gate in Action

Let's see Gate's OpenAPI plugin in action. We're going to do four main steps:

- Write an OpenAPI document describing our API, using the OAuth 2.0 client credentials flow security scheme
- Create scoped client credentials and access tokens with SlashID
- Deploy Gate in front of a backend, configured to enforce the security from the OpenAPI document
- Make requests via Gate to the backend with different access tokens and see security enforcement in action.

In particular, the example backend service will not include any logic for validating access tokens - Gate takes care of it,
so you can focus on building the features your organization needs.

If you want to follow these steps yourself, you can run this example locally with the following steps.
All the necessary files and cURL commands are included in this repo.

#### Prerequisites

- Docker and Docker Compose installed
- A SlashID organization (create one for free [here](https://console.slashid.dev/signup?utm_source=gate-example-repo))
- `cURL` or other software for making HTTP requests (such as Postman)

#### Setup

- Clone this repository and navigate into its directory
- Run `docker-compose pull` to get the latest images
- Create a client ID/secret pair with SlashID using `create_client.sh`
- Set the client ID and secret in `gate.yaml`
- Use the client ID/secret to calculate the basic authorization header in `request_token.sh`
- Run `docker-compose up` to start Gate and the backend server

You can now make requests to `http://localhost:5000`.

#### Cleanup

Once you are finished, follow these steps to clean up your environment:

- Run `docker-compose down` to stop Gate and the backend server
- [Delete the OAuth 2.0 client ID/secret](https://developer.slashid.dev/docs/api/delete-oauth-2-clients-oauth-client-id) using the SlashID API (this will also revoke all associated tokens)

### OpenAPI Document

Below we have a short OpenAPI document describing a simple customer management API, which we imagine is exposed by one
of your services, intended for use by your other services and trusted partners. You want to make sure that least privilege
is honoured, and that access to each endpoint is controlled by fine-grained permissions.

As such, you have defined an OAuth 2.0 security scheme using the client credentials flow and four scopes: one each for
the usual CRUD operations on customers. For each operation, you have specified that the OAuth 2.0 security scheme should
be used, and which scopes apply (so a `POST /customers` request would require permissions to read and create customers).

Note that the document also has a top-level `security` field. This would be applied to any operation that did not have
its own security defined (although this is not the case for any operations in this document).

This is a good start - you have defined a straightforward API and described its security model. Now you need to enforce
it.

```yaml
openapi: 3.0.1

info:
  title: Test API
  version: '1.0'

servers:
  - url: 'https://example.local'

components:
  securitySchemes:
    OAuth2ClientCreds:
      type: oauth2
      flows:
        clientCredentials:
          tokenUrl: 'https://api.slashid.com/oauth2/tokens'
          scopes:
            customers:read: Read information about customers
            customers:create: Create a customer
            customers:modify: Modify existing customers
            customers:delete: Delete existing customers

paths:
  /customers:
    post:
      security:
        - OAuth2ClientCreds: [customers:read, customers:create]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required:
                - customer_name
                - customer_tax_id
              properties:
                customer_name:
                  type: string
                customer_tax_id:
                  type: string
        required: true
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema:
                type: object
                properties:
                  customer_id:
                    type: string

  /customers/{customer_id}:
    parameters:
      - name: customer_id
        in: path
        required: true
        schema:
          type: string

    get:
      security:
        - OAuth2ClientCreds: [customers:read]
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  customer_id:
                    type: string
                  customer_name:
                    type: string
                  customer_tax_id:
                    type: string

    patch:
      security:
        - OAuth2ClientCreds: [customers:read, customers:modify]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                customer_name:
                  type: string
                customer_tax_id:
                  type: string
        required: true
      responses:
        '200':
          description: OK

    delete:
      security:
        - OAuth2ClientCreds: [customers:read, customers:delete]
      responses:
        '200':
          description: OK

security:
  - OAuth2ClientCreds:
      [customers:read, customers:create, customers:modify, customers:delete]
```

### Client Credentials

The next step is to create some client credentials, as Gate will need these in its configuration. We will use SlashID
as the Authorization Server, but you can use any Oauth 2.0 provider that supports the client credentials flow.
You can [get started with SlashID](https://console.slashid.dev/signup) in 30 seconds, and then
creating a set of client credentials is a [straightforward API call](https://developer.slashid.dev/docs/api/post-oauth-2-clients):

```shell
curl --location 'https://api.slashid.com/oauth2/clients' \
--header 'SlashID-OrgID: <ORGANIZATION ID>' \
--header 'Content-Type: application/json' \
--header 'SlashID-API-Key: <API KEY>' \
--data '{
    "scopes": ["customers:read", "customers:create", "customers:modify", "customers:delete"],
    "client_name": "example",
    "grant_types": ["client_credentials"]
}'
```

```json
{
  "result": {
    "client_id": "<CLIENT ID>",
    "client_name": "example",
    "client_secret": "<CLIENT SECRET>",
    "grant_types": ["client_credentials"],
    "public": false,
    "response_types": [],
    "scopes": [
      "customers:create",
      "customers:delete",
      "customers:modify",
      "customers:read"
    ]
  }
}
```

Note the client ID and secret as we will need them for the next steps.

### Gate Deployment

We will deploy the Gate Docker image and a simple [echo server backend](https://hub.docker.com/r/kicbase/echo-server) using Docker Compose.
The backend service will respond to all incoming requests with a response describing the incoming request.
(Note that this means it does not implement the API described above, but is sufficient to demonstrate that the security schemes are being enforced.)

First, let's configure Gate to enforce the security schemes defined in the OpenAPI specification.
Note that the `enforce-openapi-security` plugin is enabled, meaning it is applied
to all URLs unless explicitly disabled. This means the plugin will be applied to all the endpoints defined in the
OpenAPI document.

```yaml
gate:
  mode: proxy
  port: 5000
  tls:
    enabled: false
  log:
    format: text
    level: trace
  default:
    target: backend:8080

  plugins:
    - id: customers_openapi
      type: enforce-openapi-security
      enabled: true
      parameters:
        openapi_spec_url: '/gate/openapi_customers.yaml'
        openapi_spec_format: yaml
        oauth2_token_format: opaque
        oauth2_token_introspection_url: 'https://api.slashid.com/oauth2/tokens/introspect'
        oauth2_token_introspection_client_id: '<CLIENT ID>'
        oauth2_token_introspection_client_secret: '<CLIENT SECRET>'
```

Now we can write the Docker Compose file with the two services: Gate and the echo backend.

```yaml
version: '3.7'

services:
  backend:
    image: kicbase/echo-server:1.0

  gate-proxy:
    image: slashid/gate-free:latest # or slashid/gate-enterprise:latest for enterprise customers
    volumes:
      - ./gate.yaml:/gate/gate.yaml
      - ./openapi_customers.yaml:/gate/openapi_customers.yaml
    ports:
      - '5000:5000'
    command: --yaml /gate/gate.yaml
    restart: on-failure
```

Note that the Gate container has two volumes defined:

- `gate.yaml` is the Gate configuration file from above
- `openapi_customers.yaml` is the OpenAPI document from above.

Run `docker-compose up` to start Gate and the backend service.

### Create Access Tokens and Make Requests

We'll begin by creating some access tokens using the client credentials from above. We will give each token a different
set of scopes:

- `customers:read`
- `customers:create`
- `customers:read`, `customers:create`
- `customers:read`, `customers:modify`
- `customers:read`, `customers:delete`
- `customers:read`, `customers:create`, `customers:modify`, `customers:delete`

To obtain an access token, make an API call to the [SlashID `/oauth2/tokens` endpoint]((https://developer.slashid.dev/docs/api/post-oauth-2-tokens)):

```shell
curl --location 'https://api.slashid.com/oauth2/tokens' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header 'Authorization: Basic <Encoded CLIENT ID and CLIENT SECRET>' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'scope=customers:read customers:create'
```

```json
{
  "access_token": "<ACCESS TOKEN>",
  "expires_in": 3599,
  "scope": "customers:read customers:create",
  "token_type": "bearer"
}
```

Note that this endpoint is authorized with HTTP Basic authorization using the client ID and client secret, and the scopes
are provided as a space-separated list (as per the [OAuth 2.0 specification](https://datatracker.ietf.org/doc/html/rfc7662)).
If you are using a different OAuth 2.0 provider you will need to modify the request accordingly.

We can repeat this with different `scope` value to obtain the six access tokens.

Now we can make requests to the backend via Gate with different tokens.

First, let's make a `GET` request using the token with scope `customers:read`:

```
curl --location 'http://localhost:5000/customers/cid123' \
--header 'Authorization: Bearer <ACCESS TOKEN WITH customers:read>'
```

```
< HTTP/1.1 200 OK

Request served by 96502fea2551

HTTP/1.1 GET /customers/cid123

Host: backend:8080
Accept: */*
Accept-Encoding: gzip, deflate, br
Authorization: Bearer <ACCESS TOKEN>
Cache-Control: no-cache
```

We got a `200` status code and a response body from the echo server describing the request it received.

However, if we try to `POST` a customer with the same token:

```
curl -X POST --location 'http://localhost:5000/customers' \
--header 'Authorization: Bearer <ACCESS TOKEN WITH customers:read>'
```

```
< HTTP/1.1 403 Forbidden
```

This time we receive a `403` status code - the request is forbidden because the token does not have the correct scope
to carry out this operation (creating a new customer).

On the other hand, if we create a token with scope `customers:read customers:create`, and make a POST request:

```
curl -X POST --location 'http://localhost:5000/customers' \
--header 'Authorization: Bearer <ACCESS TOKEN WITH customers:read customers:create>'
```

```
< HTTP/1.1 200 OK

Request served by 96502fea2551

HTTP/1.1 POST /customers

Host: backend:8080
Accept: */*
Accept-Encoding: gzip, deflate, br
Authorization: Bearer <ACCESS TOKEN>
Cache-Control: no-cache
```

This time we get a `200` response and the echo - we successfully created a new customer, since our token had the correct scope.
(We see here the difference between the echo server - which always responds with a `200` - and the OpenAPI document, which specifies a `201` response on a successful `POST`.)

The table below shows the response status code for each access token for different requests.

| Token scope                                                                              | POST /customers | GET /customers/cid123 | PATCH /customers/cid123 | DELETE /customers/cid123 |
| ---------------------------------------------------------------------------------------- | --------------- | --------------------- | ----------------------- | ------------------------ |
| `customers:read`                                                                         | 403 Forbidden   | 200 OK                | 403 Forbidden           | 403 Forbidden            |
| `customers:create`                                                                       | 403 Forbidden   | 403 Forbidden         | 403 Forbidden           | 403 Forbidden            |
| `customers:read` <br/>`customers:create`                                                 | 200 OK          | 200 OK                | 403 Forbidden           | 403 Forbidden            |
| `customers:read` <br/>`customers:modify`                                                 | 403 Forbidden   | 200 OK                | 200 OK                  | 403 Forbidden            |
| `customers:read` <br/>`customers:delete`                                                 | 403 Forbidden   | 200 OK                | 403 Forbidden           | 200 OK                   |
| `customers:read` <br/>`customers:create` <br/>`customers:modify` <br/>`customers:delete` | 201 Created     | 200 OK                | 200 OK                  | 200 OK                   |

In addition, we can try some other requests:

- for a path not defined in the spec: `404 Not Found`
- for a method not defined for a given path: `405 Method Not Allowed`
- for a defined path and method, but without a token, or with an invalid token: `403 Forbidden`

(Note that the first two behaviors can be modified with the `allow_requests_not_in_spec` parameter, which will
allow requests that do not have a matching operation in the provided OpenAPI document. This should be used with
caution.)

## Conclusion

In this guide we've described how OAuth 2.0 client credentials and OpenAPI can help secure your services, and how
Gate can simplify this down to a few simple steps.

In a future guide, we'll show you how to use similar approach to easily create custom rate limiting policies
for your APIs by using an OpenAPI document as the source of truth for Gate's configuration.

Want to try out Gate? Check our [documentation](https://developer.slashid.dev/docs/gate)!
Ready to try SlashID? Sign up [here](https://console.slashid.dev/signup)!

Is there a feature you’d like to see, or have you tried out Gate and have some feedback? [Let us know](mailto:contact@slashid.dev)!
