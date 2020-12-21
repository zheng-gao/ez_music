release: ./mvnw -e -X flyway:clean && ./mvnw -e -X flyway:migrate
web: java $JAVA_OPTS -Dserver.port=$PORT -jar target/*.jar