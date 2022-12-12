FROM golang:1.19-alpine AS build

#Install git
RUN apk add --no-cache git

WORKDIR /app

# Copy everything from the current directory to the PWD (Present Working Directory) inside the container
COPY . .

# Build the project and send the output to /bin/app
RUN export GO111MODULE=on && go get . && go build -o /bin/app

FROM golang:1.19-alpine
#Copy the build's output binary from the previous build container
COPY --from=build /bin/app /bin/app

ENTRYPOINT ["/bin/app"]
EXPOSE 8080
