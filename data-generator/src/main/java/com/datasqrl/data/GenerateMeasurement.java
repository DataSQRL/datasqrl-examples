package com.datasqrl.data;

import com.datasqrl.cmd.AbstractGenerateCommand;
import com.datasqrl.util.Configuration;
import com.datasqrl.util.RandomSampler;
import com.datasqrl.util.SerializerUtil;
import com.datasqrl.util.WriterUtil;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.concurrent.Flow;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;
import lombok.EqualsAndHashCode;
import lombok.EqualsAndHashCode.Include;
import lombok.Value;
import org.apache.commons.lang3.StringUtils;
import picocli.CommandLine;

@CommandLine.Command(name = "measurement", description = "Generates Measurements")
public class GenerateMeasurement extends AbstractGenerateCommand {


  @Override
  public void run() {
    initialize();
    Config config = getConfiguration(new Config());
    long numMeasurements = root.getNumber();
    Instant end = Instant.now().truncatedTo(ChronoUnit.SECONDS);
    DataFunction normalTemperature = new DataFunction(190, 190, 0, 1);
    DataFunction normalPressure = new DataFunction(3000, 3000, 0, 4);
    DataFunction normalFlow = new DataFunction(250, 250, 0, 2);
    Map<Integer, List<DataFunction>> assets = Map.of(
        12221, List.of(normalPressure.with(3400, -3600), normalTemperature, normalFlow.with(180, -3600)),
        21112, List.of(normalPressure.with(1800, -4000), normalTemperature, normalFlow.with(150, -1400)),
        34443, List.of(normalPressure.with(3800, -100), normalTemperature, normalFlow.with(120, -40)),
        45555, List.of(normalPressure.with(2000, -190), normalTemperature, normalFlow.with(100, -70)),
        59995, List.of(normalPressure, normalTemperature, normalFlow)
    );
    System.out.println(assets.keySet());

    List<Measurement> measurements = new ArrayList<>();
    List<FlowRate> flowrates = new ArrayList<>();
    for (int i = 1; i <=numMeasurements ; i++) {
      long past = i-numMeasurements;
      Instant timestamp = end.plus(past, ChronoUnit.SECONDS);
      assets.forEach((id, functions) -> {
        measurements.add(new Measurement(//UUID.randomUUID().toString(),
            id,
            functions.get(0).getValue(past),
            functions.get(1).getValue(past),
            timestamp.toString()));
        flowrates.add(new FlowRate(id,
            functions.get(2).getValue(past),
            timestamp.toString()));
      });


    }

    WriterUtil.writeToFileSorted(measurements, getOutputDir().resolve("measurement.jsonl"),
        Comparator.comparing(Measurement::getTimestamp),
        null, null);
    WriterUtil.writeToFileSorted(flowrates, getOutputDir().resolve("flowrate.jsonl"),
        Comparator.comparing(FlowRate::getTimestamp),
        null, null);
  }

  @Value
  public class DataFunction {
    double startValue;
    double endValue;
    long startTime;
    double noiseStdDev;

    public double getValue(long past) {
      double value = startValue;
      if (past>startTime) {
        long delta = past - startTime;
        value = value + (endValue - startValue) * (delta/Math.abs(startTime*1.0));
      }
      return roundToOneDecimalPlace(value + sampler.nextNormal(0, noiseStdDev));
    }

    public DataFunction with(double endValue, long startTime) {
      return new DataFunction(startValue, endValue, startTime, noiseStdDev);
    }

    public static double roundToOneDecimalPlace(double value) {
      return Math.round(value * 10.0) / 10.0;
    }


  }


  @Value
  public static class Measurement {

    int assetId;
    double pressure_psi;
    double temperature_f;
    String timestamp;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

  }

  @Value
  public static class FlowRate {

    int assetId;
    double flowrate;
    String timestamp;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

  }


  public static class Config implements Configuration {

    public int numSensors = 10;

    public int avgSensorsPerMachine = 2;

    public int avgSensorReassignments = 3;

    public int avgSensorReassignmentsDeviation = 1;

    public int avgGroupPerDay = 5;

    public double avgGroupPerDayDeviation = 4.0;

    public int avgMachinesPerGroup = 10;

    public double avgMachinesPerGroupDeviation = 20.0;

    public double temperatureBaselineMin = 97;

    public double temperatureBaselineMax = 99;

    public double maxNoise = 0.05;

    public double maxTemperaturePeakStdDev = 2.0;

    public int minMaxRampWidth = 600;

    public int maxMaxRampWidth = 10000;

    public double errorProbability = 0.00;



    @Override
    public void scale(long scaleFactor, long number) {
      numSensors = (int)Math.min(10000000,Math.max(20, number/(86400*60)));
    }
  }


}
