## Creating a UDF Maven Project

1. **Project Structure:** The `myjavafunction` folder contains a sample Java project, demonstrating the structure and necessary components of a Flink UDF.
2. **Defining the Function:** The main component of this project is the `MyScalarFunction` class.
   This is the implementation of a custom flink function. DataSQRL recognizes flink functions that extend any base Flink UDF class.
3. **ServiceLoader Entry:** The function must be registered with a ServiceLoader entry. This is essential for DataSQRL to recognize and use your UDF.
4. **AutoService Library:** The example includes the AutoService library by Google, simplifying the creation of ServiceLoader `META-INF` manifest entries.
5. **JAR Compiling:** Compile the sample project and build a jar. This jar is what DataSQRL will use to discover your function.
   It reads the manifest entries for any UserDefinedFunction classes and load them into DataSQRL for use in queries.
   It can be placed into any folder relative to the sqrl root folder which will translate to the import path.
   In the example, we will use the `target` directory that the compilation process creates.
