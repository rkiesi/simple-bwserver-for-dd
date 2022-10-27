# simple test for DD integration with straight foreward automation
sampleApps = BasicHttpServerExample.java BasicHttpServerExample2.java
appName = dd-java-http-server
appVersion = 1.0
appStage = testing
appPort = 8888
# change the interface name to your main network interface (DHCP)
hostIpInterface = br-a34a00c10e70
#ddAgentSRV = $(shell sh -c "ifconfig $(hostIpInterface) | grep 'inet' | awk '{print $2}'" ) <-- awk $ paramerts causing problems!
ddAgentSRV = $(shell ifconfig $(hostIpInterface) | grep 'inet' | sed -e 's/.*inet //' -e 's/ .*//' )
ddAgentURL = "http://$(ddAgentSRV):8126"

compile: *.java
	echo "Compiling all Java samples"
	javac $(sampleApps)
	mkdir -p com/logicbig/example
	mv *.class com/logicbig/example

build: compile
	-docker rmi $(appName):$(appVersion)
	docker build --tag $(appName):$(appVersion) .
	echo
	docker image ls $(appName) > docker_image.txt
	cat docker_image.txt
#	docker image inspect $(appName):$(appVersion)

run: docker_image.txt
	-docker rm $(appName)
	echo "[INFO] HTTP Service will be available at http://localhost:$(appPort)/example"
	echo "[INFO] DD Agent URL $(ddAgentURL)"
	docker run -ti \
	 -p $(appPort):8500/tcp \
	 -e APP_NAME_ON_DD=$(appName) \
	 -e APP_VERSION_ON_DD=$(appVersion) \
	 -e APP_ENV_ON_DD=$(appStage) \
	 -e DD_AGENT_URL=$(ddAgentURL) \
	 --name $(appName) $(appName):$(appVersion)

clean:
	-rm -rf *.class docker_image.txt ./com
	-docker kill $(appName)
	-docker rm $(appName)
	-docker rmi $(appName):$(appVersion)
