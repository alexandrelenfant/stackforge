FROM eclipse-temurin:25-jdk AS api_dev

WORKDIR /app

CMD ["sh", "-c", "if [ -x ./mvnw ]; then ./mvnw spring-boot:run -Dspring-boot.run.jvmArguments='-Dserver.address=0.0.0.0 -Dserver.port=${SERVER_PORT:-8080}'; else echo 'Maven wrapper ./mvnw not found or not executable'; exit 1; fi"]

FROM eclipse-temurin:25-jdk AS api_build

WORKDIR /app

COPY . .

RUN if [ -x ./mvnw ]; then ./mvnw clean package -DskipTests; else echo 'Maven wrapper ./mvnw not found or not executable'; exit 1; fi

FROM eclipse-temurin:25-jre AS api_prod

WORKDIR /app

COPY --from=api_build /app/target/*.jar /app/app.jar

CMD ["sh", "-c", "java -jar /app/app.jar --server.address=0.0.0.0 --server.port=${SERVER_PORT:-8080}"]