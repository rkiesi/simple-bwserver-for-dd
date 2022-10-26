# the bwappnode start procedure must be patched to allow for Datadog instrumentation and monitoring

# BW_STARTUP_SCRIPT=$(find ~/Downloads/bwce/BWCEv273/bwce-runtime -name bwappnode)
BW_STARTUP_SCRIPT=$(find /tmp -name bwappnode)

echo "BW_STARTUP_SCRIPT = ${BW_STARTUP_SCRIPT}"
if [ -z "$BW_STARTUP_SCRIPT" ]
then
  echo "[ERROR] BW node startup script \'bwappnode\' could not be found"
  exit 1
fi
JVM_STARTUP_COMMAND=$(grep '^exec $JAVA_HOME/bin/java ' ${BW_STARTUP_SCRIPT})
JVM_STARTUP_COMMAND=$(echo "$JVM_STARTUP_COMMAND" | sed -e 's#exec $JAVA_HOME/bin/java #exec $JAVA_HOME/bin/java -javaagent:${DD_INSTRUMENTATION_LIBRARY} ${DD_INSTRUMENTATION_PARAMETER} #')

grep -v '^exec $JAVA_HOME/bin/java ' ${BW_STARTUP_SCRIPT} > ${BW_STARTUP_SCRIPT}.dd


cat >> ${BW_STARTUP_SCRIPT}.dd << EOF

# Check for DataDog Monitoring Instrumentation
export DD_INSTRUMENTATION_LIBRARY=/resources/instrumentation/dd-java-agent.jar
export DD_INSTRUMENTATION_PARAMETER="-Ddd.profiling.enabled=true \
-XX:FlightRecorderOptions=stackdepth=256 \
-Ddd.logs.injection=true \
-Ddd.service=${APP_NAME_ON_DD} \
-Ddd.version=${APP_VERSION_ON_DD} \
-Ddd.env=${APP_ENV_ON_DD} \
-Ddd.trace.agent.url=${DD_AGENT_URL}"

if [ -f ${DD_INSTRUMENTATION_LIBRARY} ]
then
  echo "[ERROR] DATADOG intrsumentaion library not found at ${DD_INSTRUMENTATION_LIBRARY}"
  exit 1
fi
if [ "${APP_NAME_ON_DD}" == "" ] || [ "${APP_VERSION_ON_DD}" ] == "" ] || [ "${APP_ENV_ON_DD}" == "" ] || [ "${DD_AGENT_URL}"  == "" ]
then
  echo "[ERROR] DATADOG intrsumentaion parameters not provided"
  exit 2
fi

EOF

echo ${JVM_STARTUP_COMMAND} >> ${BW_STARTUP_SCRIPT}.dd

chmod u+x ${BW_STARTUP_SCRIPT}.dd
mv ${BW_STARTUP_SCRIPT}.dd ${BW_STARTUP_SCRIPT}
