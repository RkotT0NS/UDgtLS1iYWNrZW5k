# === Base Stage ===
# Use a Java 21 JDK image
FROM eclipse-temurin:21-jdk-jammy AS deps
WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY .gradle/ .gradle
COPY gradle/wrapper/gradle-wrapper.jar ./gradle/wrapper/
COPY gradle/wrapper/gradle-wrapper.properties ./gradle/wrapper/
COPY build.gradle gradlew system.properties settings.gradle ./

# Download dependencies first to leverage Docker cache
RUN ./gradlew dependencies --no-daemon

FROM deps AS builder
WORKDIR /app
# Copy all source code
COPY src ./src
# Build the application (skipping tests for speed, adjust if needed)
# Extract the spring boot layers for optimal image layering
RUN ./gradlew bootJar --no-daemon && \
    java -Djarmode=layertools -jar build/libs/*.jar extract


# === Dev Stage ===
# For 'docker compose watch'
# Relies on spring-boot-devtools for hot reloading
FROM builder AS dev
EXPOSE 8080
# Run with the Maven wrapper's spring-boot plugin
CMD ["./mvnw", "spring-boot:run", "--debug"]

# === Build Stage ===
# Compiles and packages the application
FROM builder AS build
WORKDIR /app

## This is broken
# RUN addgroup -S spring && adduser -S spring -G spring
# USER spring:spring

COPY --from=builder /app/dependencies/ ./
COPY --from=builder /app/spring-boot-loader/ ./
COPY --from=builder /app/snapshot-dependencies/ ./
COPY --from=builder /app/application/ ./
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
# === Test Stage ===
# For headless testing
# Runs tests against the compiled code
FROM builder AS test
CMD ["./gradlew", "clean", "test"]

# === Prod Stage ===
# Creates the final, lightweight production image
FROM eclipse-temurin:21-jre-jammy AS prod
WORKDIR /app
# CORRECT PATHS: Copy from the /app folder of the builder stage
# (Do not look for /app/target/...)
COPY --from=build /app/dependencies/ ./
COPY --from=build /app/spring-boot-loader/ ./
COPY --from=build /app/snapshot-dependencies/ ./
COPY --from=build /app/application/ ./

EXPOSE 8080
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
# CMD ["java", "-jar", "/app/app.jar"]
