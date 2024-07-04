package com.datasqrl;

import com.amazonaws.services.kinesisanalytics.runtime.KinesisAnalyticsRuntime;
import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import org.apache.flink.api.java.utils.ParameterTool;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.environment.LocalStreamEnvironment;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.TableResult;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

public class FlinkMain {

  public static void main(String[] args) throws Exception {
    new FlinkMain().run(args);
  }

  public TableResult run(String[] args) throws Exception {
    Map<String, String> flinkConfig = new HashMap<>();
<#if config["values"]?? && config["values"]["flink-config"]??>
<#list config["values"]["flink-config"] as key, value>
<#if key?contains(".")>
    flinkConfig.put("${key}", "${value}");
</#if>
</#list>
</#if>
    Configuration sEnvConfig = Configuration.fromMap(flinkConfig);
    StreamExecutionEnvironment sEnv = StreamExecutionEnvironment.getExecutionEnvironment(
        sEnvConfig);
    EnvironmentSettings tEnvConfig = EnvironmentSettings.newInstance()
        .withConfiguration(Configuration.fromMap(flinkConfig)).build();
    StreamTableEnvironment tEnv = StreamTableEnvironment.create(sEnv, tEnvConfig);

    ParameterTool applicationParameters = loadApplicationParameters(args, sEnv);

    TableResult tableResult = null;
    String[] statements = readResourceFile("flink.sql").split("\n\n");
    for (String statement : statements) {
      if (statement.trim().isEmpty()) continue;
      tableResult = tEnv.executeSql(replaceWithEnv(statement, applicationParameters));
    }
    return tableResult;
  }

  public String replaceWithEnv(String command, ParameterTool applicationParameters) {
      Map<String, String> envVariables = System.getenv();
      Pattern pattern = Pattern.compile("\\$\\{(.*?)\\}");

      StringBuffer result = new StringBuffer();
      // First pass to replace environment variables
      Matcher matcher = pattern.matcher(command);
      while (matcher.find()) {
        String key = matcher.group(1);
        String value = envVariables.getOrDefault(key, null);
        if (value == null) {
          value = applicationParameters.get(key, "");
        }
        matcher.appendReplacement(result, Matcher.quoteReplacement(value));
      }
      matcher.appendTail(result);

      return result.toString();
    }

    private static String readResourceFile(String fileName) {
      try (var inputStream = Thread.currentThread().getContextClassLoader().getResourceAsStream(fileName);
        BufferedReader reader = new java.io.BufferedReader(new java.io.InputStreamReader(inputStream, StandardCharsets.UTF_8))) {
        return reader.lines().collect(Collectors.joining("\n"));
      } catch (IOException | NullPointerException e) {
        System.err.println("Error reading the resource file: " + e.getMessage());
        throw new RuntimeException(e);
      }
    }

  private static ParameterTool loadApplicationParameters(String[] args, StreamExecutionEnvironment env) throws IOException {
    if (env instanceof LocalStreamEnvironment) {
      return ParameterTool.fromArgs(args);
    } else {
      Map<String, Properties> applicationProperties = KinesisAnalyticsRuntime.getApplicationProperties();
      Properties flinkProperties = applicationProperties.get("FlinkApplicationProperties");
      if (flinkProperties == null) {
        throw new RuntimeException("Unable to load FlinkApplicationProperties properties from the Kinesis Analytics Runtime.");
      }
      Map<String, String> map = new HashMap<>(flinkProperties.size());
      flinkProperties.forEach((k, v) -> map.put((String) k, (String) v));
      return ParameterTool.fromMap(map);
    }
  }
}
