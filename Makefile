appName = dd-java-http-server
appVersion = 1.0
appPort = 8500

compile: *.java
	echo "Compiling Java samples"
	javac BasicHttpServerExample.java 
	javac BasicHttpServerExample2.java
	mkdir -p com/logicbig/example
	mv *.class com/logicbig/example

docker: compile
	docker build --tag httpsample:1.0 .
	echo "[INFO] HTTP Service will be available at http://localhost:8500/example"
	docker run -ti \
	 -p 8500:8500/tcp \
	 -e APP_NAME_ON_DD="my-container-app" \
	 -e APP_VERSION_ON_DD="1.1" \
	 -e PP_ENV_ON_DD="testing" \
	 -e DD_AGENT_URL="http://192.168.49.1:8126" \
	 --name http-sample httpsample:1.0

clean:
	-rm -rf *.class ./com
	-docker kill http-sample
	-docker rm http-sample
	-docker rmi httpsample:1.0
