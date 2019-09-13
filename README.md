We have two containers: `server` waits 30sec, then starts a node server that echos anything sent on port 8001.  `client` starts up and sends "hello" to `server`.

What settings do we have for [healthcheck](https://docs.docker.com/engine/reference/builder/#healthcheck)?

* retries - number of failed tests it takes to be considered unhealthy - default: 3
* interval - how frequently tests are run - default: 30sec
* timeout - if a test exceeds the timeout its considered a failed test - default: 30sec
* start_period - initialization time, a failed test here doesn't count towards the retries. but a successful check does put the container into a "started state" - default: 0sec

A `docker-compose up` looks like this:

``` bash
$ docker-compose up
Creating network "heath-check_default" with the default driver
Creating server ... done
Creating client ... done
Attaching to server, client
server    | Fri Sep 13 14:26:59 UTC 2019 Sleeping first
server    | Fri Sep 13 14:27:29 UTC 2019 Launching server
client    | Fri Sep 13 14:27:30 UTC 2019 Server says hello
```

You can inspect the last 5 health checks with `docker inspect server`.  The first failed check happens @ 14:27:09.  The `client` container launches and we can talk to `server`.

``` json
{
  "Status": "healthy",
  "FailingStreak": 0,
  "Log": [
    {
      "Start": "2019-09-13T14:27:09.3049552Z",
      "End": "2019-09-13T14:27:09.4649784Z",
      "ExitCode": 1,
      "Output": ""
    },
    {
      "Start": "2019-09-13T14:27:19.4691874Z",
      "End": "2019-09-13T14:27:19.6174443Z",
      "ExitCode": 1,
      "Output": ""
    },
    {
      "Start": "2019-09-13T14:27:29.6292309Z",
      "End": "2019-09-13T14:27:29.7892456Z",
      "ExitCode": 0,
      "Output": "hello\n"
    }
  ]
}
```

It's important to note was a failure looks like!  If I change to `interval: 5s` we will get 3 failed health checks in the 30s seconds the `server` container sleeps.

`docker-compose up` exits with a failure.  The `server` container does eventually become healthy, but the one unhealthy status causes docker-compose to never launch the `client` container.

``` bash
$ docker-compose up
Creating network "heath-check_default" with the default driver
Creating server ... done

ERROR: for client  Container "4c8dffed0518" is unhealthy.
ERROR: Encountered errors while bringing up the project.

$ docker-compose ps
 Name         Command            State       Ports
--------------------------------------------------
server   /scripts/launch.sh   Up (healthy)
```

Note the `"FailingStreak": 3` because the first failure occured within the `start_period: 10s`.

``` json
{
  "Status": "unhealthy",
  "FailingStreak": 3,
  "Log": [
    {
      "Start": "2019-09-13T14:37:35.8334418Z",
      "End": "2019-09-13T14:37:35.9811258Z",
      "ExitCode": 1,
      "Output": ""
    },
    {
      "Start": "2019-09-13T14:37:40.9858378Z",
      "End": "2019-09-13T14:37:41.1200684Z",
      "ExitCode": 1,
      "Output": ""
    },
    {
      "Start": "2019-09-13T14:37:46.1266745Z",
      "End": "2019-09-13T14:37:46.2563832Z",
      "ExitCode": 1,
      "Output": ""
    },
    {
      "Start": "2019-09-13T14:37:51.2618981Z",
      "End": "2019-09-13T14:37:51.484465Z",
      "ExitCode": 1,
      "Output": ""
    }
  ]
}
```