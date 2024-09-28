package com.datasqrl.data;

import com.datasqrl.cmd.AbstractGenerateCommand;
import com.datasqrl.util.Configuration;
import com.datasqrl.util.RandomSampler;
import com.datasqrl.util.SerializerUtil;
import com.datasqrl.util.WriterUtil;
import java.text.SimpleDateFormat;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import lombok.EqualsAndHashCode;
import lombok.EqualsAndHashCode.Include;
import lombok.Value;
import picocli.CommandLine;

@CommandLine.Command(name = "patients", description = "Generates Healthcare data")
public class GeneratePatients extends AbstractGenerateCommand {

  public static final String SENSOR_FILE = "sensorplacements_part%04d.jsonl";
  public static final String MEASUREMENTS_FILE = "clinicalindicator_part%04d.jsonl";
  public static final String PATIENT_FILE = "patients.jsonl";
  public static final String METADATA_FILE = "metadata.jsonl";
  public static final String GROUP_FILE = "observationgroup.jsonl";

  public static final int SENSOR_READINGS_PER_DAY = 60*24; //one per minute
  public static final ChronoUnit SENSOR_READING_UNIT = ChronoUnit.MINUTES;

  @Override
  public void run() {
    initialize();
    Config config = getConfiguration(new Config());

    long numDays = root.getNumber();
    Instant startTime = getStartTime(numDays);
    Instant initialTimestamp = startTime.minus(1, ChronoUnit.DAYS);

    SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd");

    //Patients
    List<Patient> patients = IntStream.range(1,1+config.numPatients)
        .mapToObj(i -> new Patient(i, faker.name().name(), faker.name().bloodGroup(),
            formatter.format(faker.date().birthday()), faker.medical().diseaseName(),
            initialTimestamp.toString()))
        .toList();

    //Group
    List<ObservationGroup> groups = new ArrayList<>();
    for (int i = 1; i <= Math.round(patients.size()*1.0/config.observationGroupSize) ; i++) {
      int groupSize = (int)Math.ceil(super.sampler.nextPositiveNormal(config.observationGroupSize, config.getObservationGroupSizeDev));
      groups.add(new ObservationGroup(i, faker.medical().hospitalName(), initialTimestamp.toString(),
          sampler.withoutReplacement(groupSize, patients).stream().map(p -> new GroupMember(p.getPatientId())).toList()));
    }

    //Metadata
    List<Metadata> metadata = IntStream.range(1, 1+config.numMetadata)
        .mapToObj(i -> {
          long midPoint = Math.round(sampler.nextDouble(0, config.metadataRangeInterval));
          long width = (long)Math.ceil(sampler.nextDouble(0.001, midPoint));
          return new Metadata(i, faker.medical().symptoms()+" Marker",
            midPoint-width, midPoint+width,
            initialTimestamp.toString());
        })
        .toList();
    Map<Integer,Metadata> metadataById = metadata.stream().collect(Collectors.toMap(Metadata::getMetadataId, Function.identity()));

    List<SensorPlacement> sensors = IntStream.range(1,1+patients.size()*config.avgSensorsPerPatient)
        .mapToObj(i -> new SensorPlacement(i, sampler.next(patients).patientId, sampler.next(metadata).getMetadataId(), UUID.randomUUID().toString(), initialTimestamp.toString()))
        .collect(Collectors.toList());

    WriterUtil.writeToFile(patients, getOutputDir().resolve(PATIENT_FILE), null, null);
    WriterUtil.writeToFile(metadata, getOutputDir().resolve(METADATA_FILE), null, null);
    WriterUtil.writeToFile(groups, getOutputDir().resolve(GROUP_FILE), null, null);
    WriterUtil.writeToFile(sensors, getOutputDir().resolve(String.format(SENSOR_FILE,0)), null, null);

    long totalRecords = 0;
    Instant startOfDay = startTime;
    for (int i = 0; i < numDays; i++) {
      int numReadings = SENSOR_READINGS_PER_DAY;
      List<ClinicalIndicator> readings = new ArrayList<>(numReadings*sensors.size());
      for (int j = 0; j < numReadings; j++) {
        Instant timestamp = startOfDay.plus(j,SENSOR_READING_UNIT);
        for (SensorPlacement sensor : sensors) {
          Metadata meta = metadataById.get(sensor.getMetadataId());
          double value = meta.generateReading(sampler);
          readings.add(new ClinicalIndicator(sensor.getSensorId(), timestamp.toEpochMilli(),
              value));
        }
      }
      WriterUtil.writeToFileSorted(readings, getOutputDir().resolve(String.format(MEASUREMENTS_FILE,i+1)),
          Comparator.comparing(ClinicalIndicator::getTime),
          null, null);
      totalRecords += readings.size();

      int numReassignments = (int)Math.round(sampler.nextPositiveNormal(
          config.avgSensorReassignments, config.avgSensorReassignmentsDeviation));
      List<SensorPlacement> reassignments = new ArrayList<>(numReassignments);
      for (int j = 0; j < numReassignments; j++) {
        SensorPlacement sensor = sampler.next(sensors);
        reassignments.add(sensor.replaced(sampler.next(patients).patientId,
            sampler.nextTimestamp(startOfDay, 1, ChronoUnit.DAYS)));
      }
      WriterUtil.writeToFileSorted(reassignments, getOutputDir().resolve(String.format(SENSOR_FILE,i+1)),
          Comparator.comparing(SensorPlacement::getPlacedTimestamp),
          null, null);


      startOfDay = startOfDay.plus(1, ChronoUnit.DAYS); //next day
    }
  }

  @Value
  @EqualsAndHashCode(onlyExplicitlyIncluded = true)
  public static class SensorPlacement {

    @Include
    int sensorId;
    int patientId;
    int metadataId;
    String eventId;
    String placedTimestamp;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

    public SensorPlacement replaced(int patientId, Instant placementTime) {
      return new SensorPlacement(sensorId, patientId, metadataId, UUID.randomUUID().toString(), placementTime.toString());
    }

  }

  @Value
  public static class Patient {

    int patientId;
    String name;
    String bloodGroup;
    String dateOfBirth;
    String diagnosis;
    String lastUpdated;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }
  }

  @Value
  public static class Metadata {

    int metadataId;
    String name;
    double lowRange;
    double highRange;
    String lastUpdated;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

    public double generateReading(RandomSampler sampler) {
      double mean = (lowRange + highRange)/2;
      double stdDev = (highRange - mean)/3;
      return sampler.nextNormal(mean, stdDev);
    }

  }

  @Value
  public static class ClinicalIndicator {

    int sensorId;
    long time;
    double metric;


    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

  }

  @Value
  public static class ObservationGroup {

    int groupId;
    String groupName;
    String createdDate;
    Collection<GroupMember> patients;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

  }

  @Value
  public static class GroupMember {

    int patientId;

  }

  public static class Config implements Configuration {

    public int numPatients = 30;

    public int numMetadata = 20;

    public int avgSensorsPerPatient = 2;

    public int observationGroupSize = 5;

    public int getObservationGroupSizeDev = 2;

    public int avgSensorReassignments = 3;

    public int avgSensorReassignmentsDeviation = 1;

    public int metadataRangeInterval = 100;


    @Override
    public void scale(long scaleFactor, long number) {
      //do nothing
    }
  }


}
