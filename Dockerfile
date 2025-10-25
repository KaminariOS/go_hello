
# ---- Build stage ----
FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.25-alpine AS builder

# Enable Go modules and configure working directory
WORKDIR /app

# Buildx sets TARGETOS/TARGETARCH; default to linux/amd64 for local builds.
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Copy go.mod and go.sum first (for caching dependencies)
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the code
COPY main.go main.go

# Build a statically linked binary
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-w -s"  -o server .

# ---- Runtime stage ----
FROM --platform=${TARGETPLATFORM:-linux/amd64} scratch

# Copy binary from builder
COPY --from=builder /app/server /server

# Expose HTTP port
EXPOSE 8080

# Run the binary
ENTRYPOINT ["/server"]
