# How to Run

1. Run the following command in the root directory to compile: `docker run -it -p 8888:8888 -p 8081:8081 -v $PWD:/build datasqrl/cmd compile recommendation.sqrl recommendation.graphqls --mnt $PWD`
2. Then run cd into the `build/deploy` directory
3. Start with `docker compose up`
4. Take down with `docker compose down -v`

Open GraphiQL to see if you can query:
`http://localhost:8888/graphiql/`

