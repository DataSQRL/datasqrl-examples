## Creating JBang UDFs

1. **Structure:** The `usrlib` contains a sample Java UDF file, but any folder name or subfolder can be used inside the DataSQRL project root.
2. **Defining the Function:** The main component of this project is the `MyScalarFunction` class.
   This is the implementation of a custom flink function. DataSQRL recognizes flink functions that extend any base Flink UDF class.
3. **Defining Dependencies:** To fetch dependencies JBang will look for lines that start with `//DEPS` and define a proper artifact. 
  The bare minimum that any Flink UDF will require is `flink-table-common`, because the custom UDF has to extend a Flink built-in UDF parent class.
4. **JAR Compiling:** The compile and JAR build is handled by JBang, that DataSQRL will do automatically on the fly.
