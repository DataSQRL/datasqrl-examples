package com.datasqrl.data;

import com.datasqrl.cmd.RootGenerateCommand;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

@Disabled("only used for data generation")
public class TestDataGenerators {

  @Test
  public void testClickStream() {
    new RootGenerateCommand().getCmd().execute(new String[]{"clickstream","-n","20000","-o", "data/clickstream"});
  }

  @Test
  public void testSensorIoT() {
    new RootGenerateCommand().getCmd().execute(new String[]{"sensors","-n","10000"});
  }

  @Test
  public void testPatientSensors() {
    new RootGenerateCommand().getCmd().execute(new String[]{"patients","-n","1"});
  }

  @Test
  public void testLoan() {
    new RootGenerateCommand().getCmd().execute(new String[]{"loan","-n","100"});
  }

  @Test
  public void testCreditCard() {
    new RootGenerateCommand().getCmd().execute(new String[]{"creditcard","-n","365","-o","data/creditcard"});
  }

  @Test
  public void TestWarrants() {
    new RootGenerateCommand().getCmd().execute(new String[]{"warrants","-n","100","-o","data/warrants"});
  }

  @Test
  public void testMeasurements() {
    new RootGenerateCommand().getCmd().execute(new String[]{"measurement","-n","8000","-o","data/well"});
  }



}
