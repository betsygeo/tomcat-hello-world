FROM maven:3.9.9-eclipse-temurin-24-alpine AS build
WORKDIR /app
# Create a robust pom.xml that correctly configures the non‐standard project layout.
# The source files are in the "src" folder and the web resources (WEB-INF, JSPs, etc.) are in "web".
RUN printf '<?xml version="1.0" encoding="UTF-8"?>\n\
<project xmlns="http://maven.apache.org/POM/4.0.0"\n\
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n\
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">\n\
  <modelVersion>4.0.0</modelVersion>\n\
  <groupId>com.example</groupId>\n\
  <artifactId>sample</artifactId>\n\
  <version>1.0-SNAPSHOT</version>\n\
  <packaging>war</packaging>\n\
  <build>\n\
    <finalName>sample</finalName>\n\
    <sourceDirectory>src</sourceDirectory>\n\
    <plugins>\n\
      <plugin>\n\
        <artifactId>maven-compiler-plugin</artifactId>\n\
        <version>3.8.1</version>\n\
        <configuration>\n\
          <source>8</source>\n\
          <target>8</target>\n\
        </configuration>\n\
      </plugin>\n\
      <plugin>\n\
        <artifactId>maven-war-plugin</artifactId>\n\
        <version>3.3.2</version>\n\
        <configuration>\n\
          <warSourceDirectory>web</warSourceDirectory>\n\
        </configuration>\n\
      </plugin>\n\
    </plugins>\n\
  </build>\n\
</project>\n' > pom.xml

# Copy the application source code and web resources.
COPY src/ ./src/
COPY web/ ./web/

# Run Maven to compile the Java source and package the WAR.
RUN mvn clean package

# ----- Stage 2: Deploy the WAR on Tomcat -----
# Use an approved Tomcat image (version 9.0) as the runtime base.
FROM tomcat:9.0
WORKDIR /usr/local/tomcat

# Set environment variables for database connection (to be passed in at runtime).
ENV DB_URL="" \
    DB_USERNAME="" \
    DB_PASSWORD=""

# Remove the default ROOT webapp provided by Tomcat.
RUN rm -rf webapps/ROOT

# Copy the generated WAR file from the build stage into Tomcat's webapps directory as ROOT.war.
COPY --from=build /app/target/sample.war webapps/ROOT.war

# Expose Tomcat’s default port.
EXPOSE 8080

# Launch Tomcat.
CMD ["catalina.sh", "run"]