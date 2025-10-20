
# ---- Build stage ----
FROM golang:1.25-alpine AS builder

# Enable Go modules and configure working directory
WORKDIR /app

# Copy go.mod and go.sum first (for caching dependencies)
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the code
COPY . .

# Build a statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

# ---- Runtime stage ----
FROM scratch

# Copy binary from builder
COPY --from=builder /app/server /server

# Expose HTTP port
EXPOSE 8080

# Run the binary
ENTRYPOINT ["/server"]
