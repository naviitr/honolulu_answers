pipelines = []

pipelines.add(["trigger", "commit", "build-and-deploy", "test-application", "terminate-environment"])
pipelines.add(["production-trigger", "build-and-deploy-for-prod", "smoke-test", "bluegreen"])

for (i = 0; i < jobs.size; ++ i) {
  job {
      name "${jobs[i]}-dsl"
      scm {
          git("https://github.com/stelligent/honolulu_answers.git", "master") { node ->
              node / skipTag << "true"
          }
      }
    if (jobs[i].equals("trigger-stage")) {
        triggers {
          scm("* * * * *")
        }
    }
    steps {
      shell("pipeline/${jobs[i]}.sh")
      if (i + 1 < jobs.size) {
        downstreamParameterized {
          trigger ("${jobs[i+1]}-dsl", "ALWAYS"){
            currentBuild()
            propertiesFile("environment.txt")
          }
        }
      }
    }
    wrappers {
        rvm("1.9.3")
    }
    publishers {
      extendedEmail("jonny@stelligent.com", "\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS!", """\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS:

Check console output at \$BUILD_URL to view the results.""") {
          trigger("Failure")
          trigger("Fixed")
      }
    }
  }
}