---
layout: post
title:  "Gradle rules - Things I have learned from dfuntest"
date:   2014-12-07 12:00:00
tags: gradle dfuntest java
category: computer science
---
I believe that work should be as automated as possible. Although there are
already many existing tools for all kinds of tasks in programmer's daily life:
compiling, deployment etc. I couldn't find any good tool for writing functional
tests to be run in a distributed environment. What I wanted is a tool that would
be easily configurable and provide reporting capabilities so that a developer
can fire an entire test-suite and get result report identifying possible
problems if any. What I wanted was something like a modern unit-testing
framework, but for functional tests.

I couldn't find anything even similar to that so I wrote my own. I called it
[dfuntest][dfuntest] and since it was general enough I made a decision to write
it well, like a proper open-source project. I didn't mean that a code should be
elegant, that I usually take care of, but all the surrounding fluff which makes
development easy, stuff such as: building, testing, documentation, deployment
architecture. Luckily, in this area, I did find [the perfect tool][gradle].

Gradle
------
<figure style="float: left">
<img src="/images/2014/12/gradle_logo.png" alt="Gradle's logo" />
</figure>

### Basics
On Nebulostore we use Maven. A tool which I found cumbersome, probably due to
its use of XML configuration and reliance on default semantics. It is hard to
properly extend it with custom behaviour.

I had heard about Gradle, the build automation tool used by the cool kids, and
decided to give it a try. It was a love at first sight. First of, Gradle uses a
programming language, called Groovy, for its configuration. Groovy is a dynamic
language based on Java and works on JVM. Any Java programmer should be able
to program in it after minimal introduction. So right from the bat it is easy to
program the desired behaviour directly in the configuration file. It is also
very terse thanks to its dynamic types.

Compare for example dependency declaration in Gradle:
  
    dependencies {
      runtime group: 'group-c', name: 'artifact-b', version: '1.0'
      runtime group: 'group-a', name: 'artifact-b', version: '1.0'
    }
    
to one in `pom.xml`:

    <dependencies>
      <dependency>
        <groupId>group-c</groupId>
        <artifactId>artifact-b</artifactId>
        <version>1.0</version>
        <scope>runtime</scope>
      </dependency>
      <dependency>
        <groupId>group-a</groupId>
        <artifactId>artifact-b</artifactId>
        <version>1.0</version>
        <scope>runtime</scope>
      </dependency>
    </dependencies>

Gradle handles all tasks that Maven can do, such as:

* preparing dependencies, IDE
* building projects (and it's subprojects)
* running tests
* producing reports about code quality
* deploying artifacts

All of this is done in a convenient to a Java's programmer model.

Each `build.gradle` file represent a Project, in fact instructions in
`build.gradle` are run on a Project object. This file configures the build, it
defines variables, available tasks and their configuration as well. As I said
it's easy to extend it. For example to define a task, which will copy all
runtime dependencies of a project to 'lib/' directory we can define:

    task copyRuntimeDependencies(type: Copy) {
      from configurations.runtime
      into "lib/"
    }

Let me explain what these lines mean.

    task // A keyword in Gradle which informs Gradle that we are creating a new
         // task

    copyRuntimeDependencies // Name of the task

    (type: Copy)  // This task will be a subtype of a task class called Copy.
                  // Class Copy is defined inside Gradle's library.

    {             // Beginning of a definition of a closure (something similar
                  // to an anonymous inner class or a lambda function).
                  // Note that this definition is in fact a configuration
                  // instruction which will be called at the time when gradle
                  // configures its build system.

      from configurations.runtime // Call from method in Copy class which
                                  // specifies files to copy.
                                  // configurations.runtime are runtime
                                  // dependencies (jar file paths) of the main
                                  // module.

      into "lib/"                 // Call into method in Copy class
    }

Notice here that the above is not just a task definition, but a task definition
with configuration instructions. To inform Gradle that we want to do something
when the task is executed we would have to do something like:

    copyRuntimeDependencies << { // or copyRuntimeDepedencies.doLast
      println "Copy has been finished";
    } 

Gradle uses closures very extensively, it's important to know how external
variables are resolved. Each closure has 3 special variables defined: `this`,
`owner` and `delegate`. `this` is bound to the instance of the current class, in
this case it is the project. `owner` refers to enclosing closure, since our
closure is on top level, it is equal to `this`. `delegate` is equal to `owner`
on default, but may be changed manually. In the case of a task it is changed to
the calling task. Now Gradle binds the external variables and method calls to
the first found instance in `delegate`, `owner` and `this` searched in that
order.  Each closure also has a default `it` argument, in this case `it` is
equal to the calling task.

### Plugins

#### Java plugin
Gradle comes in with an extensive set of plugins. The most important plugin for
every Java developer will be java. It allows you to define a complete pipeline
from source through build, test to deployment. It uses a concept of
`configurations`, a Gradle's collection binding sources, dependencies and
expected artifacts together. With that plugin I could split my dfuntest project
into 3 parts: main source, unit test and an example implementation, each
separately compiled and packaged with minimal fuss. In fact on default, it is
just enough to write the following:

    apply plugin: 'java'

And calling `gradle build` will build, test and package a standard Java project.

#### Wrapper
In some other languages or with other tools you need to manually install
required dependencies or at least download a proper build tool. Hopefully there
will be no version conflicts and the build tool in your repository is as up to
date as the developer expected it to be. Again, Gradle has these worries
covered. It allows you to create a wrapper, a local `.jar` file and executable
which contains the required version of Gradle. Since Java's motto is run
everywhere, you can include it into your repository.

#### Deployment
If one wants to publish his own jar into Maven repository, he first needs to
find one where they'll accept his contributions. I decided to use sonatype.org.
It's free and available on default. To register one needs to provide his public
PGP key, which will be used to signed his packages. This key needs to be
publicly verifiable, for example by uploading it to [pgp.mit.edu][pgpmit].

Later we can use gradle to automatically package, sign and deploy our jar
library. Here's for example code that handles most of the work connected to
this in dfuntest (uses signing and maven plugin):

    signing {
      required { gradle.taskGraph.hasTask(uploadArchives) }
      sign configurations.archives
    }

    uploadArchives {
      repositories {
        mavenDeployer {
          beforeDeployment {
            MavenDeployment deployment -> signing.signPom(deployment)
          }

          repository(url: "https://oss.sonatype.org/service/local/staging/deploy/maven2") {
            authentication(userName: ossrhUsername)
          }

          snapshotRepository(url: "https://oss.sonatype.org/content/repositories/snapshots") {
            authentication(userName: ossrhUsername)
          }

          pom.project {
            name 'dfuntest'
            description 'Framework for distributed functional tests.'
            url 'http://github.com/gregorias/dfuntest'

            licenses {
              license {
                name 'The BSD 2-Clause License'
                url 'http://opensource.org/licenses/BSD-2-Clause'
              }
            }

            developers {
              developer {
                name 'Grzegorz Milka'
                email 'grzegorzmilka@gmail.com'
              }
            }

            scm {
              connection 'scm:git:git@github.com:gregorias/dfuntest.git'
              developerConnection 'scm:git:git@github.com:gregorias/dfuntest.git'
              url 'git@github.com:gregorias/dfuntest.git'
            }
          }
        }
      }
    }

What's missing in this picture is the declaration of our credentials. I have put
public credentials inside global properties in `~/.gradle/build.properties`.

    signing.keyId=72E1AAD5
    signing.secretKeyRingFile=~/.gnupg/secring.gpg

    ossrhUsername=my_username

While passwords are provided online only when required, thanks to the
programmability of Gradle. In Maven the only solution I know of is to put the
password in a separate file. In my opinion it is a security risk.

    // Fancy getPassword which uses Swing GUI for prompt
    def getPassword = { target ->
      def pass = ''
      def prompt = "\nPlease enter password for ${target}: "
      if (System.console() == null) {
        new SwingBuilder().edt {
          dialog(modal: true,
              title: 'Enter password',
              alwaysOnTop: true,
              resizable: false,
              locationRelativeTo: null,
              pack: true,
              show: true
          ) {
            vbox {
              label(text: prompt)
              input = passwordField()
              button(defaultButton: true, text: 'OK', actionPerformed: {
                pass = input.password;
                dispose();
              })
            }
          }
        }
      } else {
        pass = System.console().readPassword(prompt)
      }
      // This is necessary, because SWT for example does not return real String and
      // may be invalidated.
      pass = new String(pass)
    }

    // before running sign or upload ask for key.
    gradle.taskGraph.beforeTask { taskGraph ->
      if (taskGraph.project.name.equals('dfuntest')) {
        if (taskGraph.equals(signArchives) &&
            gradle.taskGraph.hasTask(uploadArchives)) {
          ext."signing.password" = getPassword("PGP private key")
        } else if (taskGraph.equals(uploadArchives)) {
          def ossrhPassword = getPassword("OSSRH")
          uploadArchives.repositories.mavenDeployer {
            repository.authentication.password = ossrhPassword
            snapshotRepository.authentication.password = ossrhPassword
          }
        }
      }
    }

Pretty neat, isn't it? I wish other languages had a build tool as flexible and
powerful as Gradle

[dfuntest]: https://github.com/gregorias/dfuntest
[pgpmit]: https://pgp.mit.edu
[gradle]: http://gradle.org/
