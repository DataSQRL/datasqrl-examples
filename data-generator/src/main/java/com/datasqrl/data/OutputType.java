package com.datasqrl.data;

public enum OutputType {

  JSONL, CSV;

  public String extension() {
    return name().toLowerCase();
  }

}