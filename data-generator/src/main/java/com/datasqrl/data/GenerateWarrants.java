package com.datasqrl.data;

import com.datasqrl.cmd.AbstractGenerateCommand;
import com.datasqrl.util.Configuration;
import com.datasqrl.util.RandomSampler;
import com.datasqrl.util.SerializerUtil;
import com.datasqrl.util.WriterUtil;
import java.time.Instant;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import lombok.EqualsAndHashCode;
import lombok.EqualsAndHashCode.Include;
import lombok.Value;
import net.datafaker.Faker;
import picocli.CommandLine;

@CommandLine.Command(name = "warrants", description = "Generates Law Enforcement Data")
public class GenerateWarrants extends AbstractGenerateCommand {

  public static final String DRIVER_FILE = "driver.jsonl";
  public static final String VEHICLE_FILE = "vehicle.jsonl";
  public static final String WARRANT_FILE = "warrant.jsonl";
  public static final String BOLO_FILE = "bolo.jsonl";

  @Override
  public void run() {
    initialize();
    Config config = getConfiguration(new Config());

    long numDays = root.getNumber();
    Instant startTime = getStartTime(numDays);
    Instant initialTimestamp = startTime.minus(1, ChronoUnit.DAYS);

    List<Driver> drivers = IntStream.range(0,config.numDrivers)
        .mapToObj(i -> Driver.generate(faker, sampler, initialTimestamp))
        .toList();

    List<Vehicle> vehicles = IntStream.range(0, config.numVehicles)
        .mapToObj(i -> Vehicle.generate(faker, sampler.next(drivers).driver_id, sampler, initialTimestamp))
        .toList();

    WriterUtil.writeToFile(drivers, getOutputDir().resolve(DRIVER_FILE), null, null);
    WriterUtil.writeToFile(vehicles, getOutputDir().resolve(VEHICLE_FILE), null, null);

    List<Warrant> warrants =new ArrayList<>();
    List<Bolo> bolos =new ArrayList<>();

    Instant startOfDay = startTime;
    for (int i = 0; i < numDays; i++) {
      Instant nextDay = startOfDay.plus(1, ChronoUnit.DAYS);
      int numWarrants = (int)Math.round(sampler.nextPositiveNormal(config.avgWarrantsPerDay, config.stdDev));
      int numBolos = (int)Math.round(sampler.nextPositiveNormal(config.avgBolosPerDay, config.stdDev));

      for (int w = 0; w < numWarrants; w++) {
        Instant timestamp = sampler.nextTimestamp(startOfDay, nextDay);
        warrants.add(Warrant.generate(faker, sampler.next(drivers).driver_id, sampler, timestamp));
      }

      for (int b = 0; b < numBolos; b++) {
        Instant timestamp = sampler.nextTimestamp(startOfDay, nextDay);
        bolos.add(Bolo.generate(faker, sampler.next(vehicles).vehicle_id, sampler, timestamp));
      }
      startOfDay = nextDay;
    }

    warrants.sort(Comparator.comparing(Warrant::getLast_updated));
    bolos.sort(Comparator.comparing(Bolo::getLast_updated));
    WriterUtil.writeToFile(warrants, getOutputDir().resolve(WARRANT_FILE), null, null);
    WriterUtil.writeToFile(bolos, getOutputDir().resolve(BOLO_FILE), null, null);

  }

  @Value
  @EqualsAndHashCode(onlyExplicitlyIncluded = true)
  public static class Driver {

    public static String[] LICENSE_STATUS = {"active", "suspended"};

    @Include
    String driver_id;
    String first_name;
    String last_name;
    String license_number;
    String license_state;
    String date_of_birth;
    String license_status;
    String license_expiry_date;
    String last_updated;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

    public static Driver generate(Faker faker, RandomSampler sampler, Instant timestamp) {
      return new Driver(UUID.randomUUID().toString(), faker.name().firstName(),  faker.name().lastName(),
          faker.regexify("[A-Z]{2}[0-9]{6}"), faker.address().stateAbbr(),
          faker.date().birthday().toString(),
          LICENSE_STATUS[sampler.flipCoin(0.9)?0:1],
          timestamp.minus(sampler.nextInt(-100, 1800), ChronoUnit.DAYS).toString(),
          timestamp.toString()
          );
    }

  }

  @Value
  @EqualsAndHashCode(onlyExplicitlyIncluded = true)
  public static class Vehicle {

    @Include
    String vehicle_id;
    String registration_number;
    String registration_state;
    String registration_expiry;
    String make;
    String model;
    int year;
    String owner_driver_id;
    String last_updated;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

    public static Vehicle generate(Faker faker, String driverId, RandomSampler sampler, Instant timestamp) {
      String state = faker.address().stateAbbr();
      String make = faker.vehicle().make();
      return new Vehicle(UUID.randomUUID().toString(),
          faker.vehicle().licensePlate(), state,
          timestamp.minus(sampler.nextInt(-100, 365), ChronoUnit.DAYS).toString(),
          make, faker.vehicle().model(make),
          timestamp.atZone(ZoneId.systemDefault()).getYear()-sampler.nextInt(0,15),
          driverId, timestamp.toString());
    }

  }


  @Value
  @EqualsAndHashCode(onlyExplicitlyIncluded = true)
  public static class Warrant {

    public static final String[] WARRANT_STATUS = {"active", "active", "urgent", "suspended", "closed"};
    public static final String[] CRIMES = {
        "Murder",
        "Arson",
        "Robbery",
        "Burglary",
        "Assault with a deadly weapon",
        "Drug trafficking",
        "Kidnapping",
        "Rape",
        "Human trafficking",
        "Fraud",
        "Embezzlement",
        "Terrorism-related offenses",
        "Money laundering",
        "Hit and run with injuries",
        "Attempted murder",
        "Weapons trafficking",
        "Extortion",
        "Aggravated assault",
        "Child abuse",
        "Domestic violence"
    };

    @Include
    String warrant_id;
    String person_id;
    String warrant_status;
    String crime_description;
    String state_of_issuance;
    String issue_date;
    String last_updated;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

    public static Warrant generate(Faker faker, String driverid, RandomSampler sampler, Instant timestamp) {
      return new Warrant(UUID.randomUUID().toString(),
          driverid,
          WARRANT_STATUS[sampler.nextInt(0,WARRANT_STATUS.length)],
          CRIMES[sampler.nextInt(0, CRIMES.length)],
          faker.address().stateAbbr(),
          timestamp.toString(),
          timestamp.toString()
          );
    }

  }

  @Value
  @EqualsAndHashCode(onlyExplicitlyIncluded = true)
  public static class Bolo {

    public static final String[] BOLO_STATUS = {"active", "active", "active", "resolved", "canceled"};

    @Include
    String bolo_id;
    String vehicle_id;
    String issue_date;
    String status;
    String last_updated;

    @Override
    public String toString() {
      return SerializerUtil.toJson(this);
    }

    public static Bolo generate(Faker faker, String vehicleId, RandomSampler sampler, Instant timestamp) {
      return new Bolo(UUID.randomUUID().toString(),
          vehicleId,
          timestamp.toString(),
          BOLO_STATUS[sampler.nextInt(0, BOLO_STATUS.length)],
          timestamp.toString()
      );
    }

  }

  public static class Config implements Configuration {

    public int numDrivers = 5000;

    public int numVehicles = 10000;

    public int avgWarrantsPerDay = 10;

    public int avgBolosPerDay = 25;

    public double stdDev = 2.0;


    @Override
    public void scale(long scaleFactor, long number) {
      //do nothing
    }
  }


}
