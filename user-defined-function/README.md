
# Custom User-Defined Functions in Flink
This guide will lead you through the process of creating, compiling, and deploying a user-defined functions (UDFs) in Apache Flink using DataSQRL.
We will specifically focus on a function called `MyScalarFunction`, which will double the values of input numbers, and then deploy and execute the function in Flink.

## Introduction
User-defined functions (UDFs) in Flink are powerful tools that allow for the extension of the system's built-in functionality.
UDFs can be used to perform operations on data that are not covered by the built-in functions.

We support two main ways to ship UDFs for SQRL applications:
1. [**JBang**](./jbang): For simple, standalone UDFs that has no or only lightweight dependencies, DataSQRL can build and ship UDFs on the fly via [JBang](https://www.jbang.dev/). 
2. [**Assemble JAR Manually**](./maven-project): For more complex UDF projects with common abstract UDF layers, complex logic, a custom Maven or Gradle project can be crated.
  Then the manually built JAR(s) can be placed to a project folder, which DataSQRL will recognize and ship.  

To learn more about each option, please see the example project and their specific readme.

The next sections contain instructions about how to run and interact with the example projects, and those steps are the same for both variants.

## SQRL Compilation and Packaging
1. **SQRL Compilation:** Compile the SQRL using DataSQRL's command interface, which prepares your script for deployment in the Flink environment.

```shell
# "cd jbang" OR "cd maven-project"

docker run --rm -v $PWD:/build datasqrl/cmd:latest compile myudf.sqrl
```

## Deployment and Testing
### Run Example
```shell
docker run -it -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest run myudf.sqrl
```
### Creating and Testing Records
1. Creating a Record: Test the function by creating a record via a GraphQL query.
```shell
curl -X POST 'http://localhost:8888/graphql' \
    -H 'Content-Type: application/graphql' \
    -d '
mutation {
  InputData(event: { val: 2 }) {
    val
  }
}'
```

2. Verifying Function Execution: Confirm the function's execution and output with another GraphQL query. You should see two values come back, 2 and 4.

```shell
curl -X POST 'http://localhost:8888/graphql' \
    -H 'Content-Type: application/graphql' \
    -d '
query {
  MyTable {
    val
    myFnc
  }
}'
```
