# Example Data Generator

This Java project implements the data generators for the various examples in this repository.

All examples come with a small set of example data. You can use the data generator to generate larger
amounts of test data for experiments and benchmarks.

To run the data generator, you follow these steps:

1. Build the Project: `mvn package`
2. Run the command: `java -jar target/[jar file with dependencies] sensors -n 1000 -o sensordata`

This runs the `sensors` data generator and produces the output files in the director `sensordata`.

Replace `sensors` to run one of the other data generators:

- `clickstream`: Generates clickstream data
- `loan`: Generates loan data
- `creditcard`: Generates credit card data

The `-n` option specifies the size of the dataset you want to generate.
The `-o` option specifies the output directory.

Take a look at each of the data generation classes for additional configuration options.


