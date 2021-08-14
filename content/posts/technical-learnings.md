+++ 
draft = false
date = 2021-08-09T19:50:54-05:00
title = "Java Learnings"
description = ""
slug = ""
authors = []
tags = []
categories = []
externalLink = ""
series = []
+++

## Assembly Management: 

`Assembly`: An "assembly" is a group of files, directories, and dependencies that are assembled into an archive format and distributed.

* `WAR`: A Web application Archive. For the purpose of this workshop, we will be using this in our tutorials.

* `JAR`: A Java Archive which include a Java specific manifest file. They are built on the ZIP (file format) and typically have the .jar file extension.

* `EAR`: A Enterprise Application Archive. These types of assemblies are used with Java EE applications


### Dependency Analysis:
Many libraries that an assembly will manage are implementations of APIs. For example, slf4j is a widely-used logging API, but requires an implementation at runtime for the logging events to be output. Not including an implementation for some APIs may result in failures at runtime. These may manifest as `NoClassDefFoundError` or `AbstractMethodError`, but will often be a subtype of `LinkageError`


## Dependency Resolution

To determine the dependencies of your project, Maven will examine the pom, then query the configured remote repositories for all of your direct dependencies, and include their direct dependencies as dependencies of your project. It then repeats this process each time a new dependency is encountered until all dependencies have been discovered.

If multiple versions of a transitive dependency are found, Maven will use the [nearest definition](http://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Transitive_Dependencies)
(i.e. selecting the shallowest instance of that dependency in the dependency tree). So if project `A` has the following dependency chains `A -> B -> C -> D 2.0`
and `A -> E -> D 1.0`, maven will resolve to version 1.0 of dependency D since there is shorter path version 1.0 of dependency D.

### Dependency Scopes

Not all of the declared dependencies will be pulled in transitively, the [scope](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Scope)
of the dependency determines if and how it is pulled in. Only `compile` or `runtime` dependencies are included transitively in the final assembly.


### Using the jar command to examine dependencies 
The simplest way to examine the dependencies of you war is to use the [jar command](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/jar.html) to list or extract the contents of the war

Try the following command:

```bash
jar -tvf target/example-war-1.0-SNAPSHOT.war
```

### Using the dependency plugin

The [dependency plugin](http://maven.apache.org/plugins/maven-dependency-plugin/) is a maven supported plugin that provides several helpful goals for inspecting your dependencies

#### Dependency Tree 
```bash
mvn dependency:tree
mvn dependency:tree -Dverbose -Dincludes=commons-io
```
#### Graph

You can get a similar representation from the dependency plugin, by generating a visualization of the graph. This
can be accomplished by using the [depgraph-maven-plugin](https://ferstl.github.io/depgraph-maven-plugin/). This
plugin will generate a Graphviz (.dot) file, which you can then render into an image. 

## Dependency Management

### Dependency Analyze

The dependency analyze command (`mvn dependency:analyze`) looks at your projects imports and reports any dependencies that should be inlcuded in your pom and are not, or that are listed in the pom but do not need to be.

One caveat to the analyze report, because it is examing imports it may have false positives in the unused but declared section for dependencies which are injected or discovered at runtime.

### Dependency Conflicts

Once we're able to analyze our dependencies we need to be able to take action when a problem is encountered.

It is possible for dependencies to conflict, either because a class definition exists in multiple dependencies
or because the resolved version of a transitive dependency is incompatible with one or more other dependencies.

A common cause of a class definition existing in multiple dependencies is if a project or artifact or
group id is changed as part of a release. Examples of this are:

* guava vs google-collections
* spring vs spring-core
* hibernate vs hibernate-core

Dependency conflicts can be difficult to identify because they often don't occur till runtime, and even then
may only occur intermittently or depend on the runtime environment.

### Class Loaders

[Class loading](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html#jvms-5.3.2) is a very complicated subject, however for the
purposes of assemblies the things to keep in mind are:
* Multiple classloaders may exist and are applied in a hierarchy
* For assemblies the class loading behavior is generally controlled by the container which is running the assembly (ex. [Jetty](http://www.eclipse.org/jetty/) for a web application assembly). As such, your assembly should be resilient to the class loading behavior changing if the container changes.

For the [Jetty](http://www.eclipse.org/jetty/documentation/9.3.x/jetty-classloading.html) container, the defined behavior is that for non-system classes it will examine your war, looking in
/WEB-INF/classes for a definition, and then check all of the included JARs in the /WEB-INF/lib directory. If
muliple JARs contain the same class definition the loader will simply select the first one it finds.

### Dependency Management
In the event of a version mismatch you can tell maven what version to resolve by specifying a [dependency management](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Management)
section in the pom.

### Excluding Dependencies

In the event multiple implementations exist it will be necessary to [exclude](https://maven.apache.org/guides/introduction/introduction-to-optional-and-excludes-dependencies.html)
one or more of the transitive dependencies. A depedency is excluded by adding an `exclusions` section to the dependency
declaration in either the `dependencies` or `dependencyManagment` sections of the pom. During resolution maven will skip
any excluded dependencies and will not evaluate any transitive dependencies of the exluded artifact. If your using
a parent pom, exclusions in the parent pom will be honored in the child modules.

Note that because exclusions are tied to a specific direct dependency, it may be necessary to exclude the same artifact multiple times if it is a transitive dependency of multiple direct dependencies. For this reason it is generally a good idea to use the enforcer plugin to ban any dependencies that you are excluding.

The [versions plugin](http://www.mojohaus.org/versions-maven-plugin/) can be used to identify candidates
for upgrade

### Configuration

Every application we build is configurable. When it comes to
configuration, it is important that we evaluate what we should
include in the assembly, and what we shouldn't. 

One way of describing configuration is following the definition
provided by [Twelve-Factor App](https://12factor.net/config):

> An app’s config is everything that is likely to vary between deploys (staging, production, developer environments, etc). This includes:

* Resource handles to the database, Memcached, and other backing services
* Credentials to external services such as Amazon S3 or Twitter
* Per-deploy values such as the canonical hostname for the deploy

Configuration can be quite broad, but if focus on what configuration
we want to flex per deployment (in an environment) and what we don't
want to flex per deployment, it will help us categorize what
configuration should be included in the assembly.

### Configuration Sources

There are many different sources of configuration in our Java
applications. Here is an exmaple of some of the common configuration types.

### Java Properties

You will find that a vast array of Java projects are configurable through
Java properties. This simple key-value organization of configuration makes
it easy to set configuration through either an argument to the JVM (`-D`)
or by a `.properties` file. For the purpose of assemblies, the one of 
interest is the `.properties` files, as these are state files which
can influence the configuration of the application, which may be a control
that shouldn't be applied in the assembly, but rather at the point of deployment. You should always be weary of `.properties` files being
included in your assembly, understand what it is configuring, and if
it should really be included.

### Environment Entries

Environment entries are key-value properties that can be communicated
through the deployment descriptor (`web.xml`). As the name implies, the
deployment descriptor has configuration which is of iterest at the point
of deployment. You can assign default values. It is imperative that if you
do have any defaults assigned, they are **NOT** environment specific
examples.


### Logging

Many different logging implementations exist, all of which may have
different logging files that control its configuration. Examples:

* [JDK logger](https://docs.oracle.com/cd/E19717-01/819-7753/gcblo/): `logging.properties`
* [log4j-1.x](https://logging.apache.org/log4j/1.2/faq.html): 
`log4j.properties`, `log4j.xml`
* [log4j-2.x](https://logging.apache.org/log4j/2.x/manual/configuration.html): 
`log4j2.yaml`, `log4j2.json`, `log4j2.xml`
* [logback](http://logback.qos.ch/manual/configuration.html): 
`logback.xml`

`Note:` Many of the logging providers have multiple ways of being
configured. The examples provided above was done to simply show that
there are different files for these providers._

### Common Mistake

A common mistake that is generally encountered, is that someone builds
some new class in a project, and then they want to test it. When testing
it, they realize they need some configuration, and put the configuration
in `src/main/resources` vs. `src/test/resources`. As a result, that
artifact assembles configuration into its end-state, when it many times
it is intended for the consumer to configure.


## Logging

When logging dependencies are misconfigured it is likely that no events will be logged. When events can not be logged you lose insight into the state of your service.

### Options

| Interface | Implementation | Bridge |
|---|---|---|
| [Java Util Logging (JUL)](https://docs.oracle.com/javase/8/docs/api/java/util/logging/package-summary.html) | JDK | jul-to-slf4j
| [Apache Commons Logging (JCL)](https://commons.apache.org/proper/commons-logging/) | commons-logging | jcl-over-slf4j
| [slf4j](http://www.slf4j.org/) | log4j</br>logback |
| [log4j](http://logging.apache.org/log4j/2.x/) | log4j | log4j-over-slf4j
| [logback](http://logback.qos.ch/) | logback | log4j-over-slf4j
| [Instrument SDK](http://wiki.apparch.cerner.corp/index.php/Instrument_SDK) | system-instrument | system-instrument-logging-slf4j</br>system-instrument-logging-jdk</br>system-instrument-logging-log4j |

### Configuration

When many different logging implementations are used concurrently it becomes difficult to properly and confidently configure the log levels across all use cases. By managing all the dependencies to converge on a single implementation a single configuration can be supplied.

### Recommendation

It is recommended to use slf4j for the logging interface. The implementation should be decided based your deployment considerations.

### Bridge Examples

These examples demonstrate some items to consider when choosing a logging interface when the runtime implementation will be logback.

* slf4j > logback
* jul > jul-to-slf4j > slf4j > logback
* jcl > jcl-over-slf4j > slf4j > logback
* log4j > log4j-over-slf4j > slf4j > logback

### Diagnostics Context

[slf4j](http://www.slf4j.org/api/org/slf4j/MDC.html) have the concept of a diagnostic context which can attach additonal meta data to a log event. The example below shows the correlation identifier **b76f5bb7-327e-47c4-8795-008a6b11c476** attached to the log events. This is achieved by setting the value into the diagnostic context and configuring the log format pattern to extract this value for each log event.


### slf4j

The two primary slf4j providers [logback](http://logback.qos.ch/manual/mdc.html) and [log4j](https://logging.apache.org/log4j/2.x/manual/thread-context.html) supply runtime implementations of the MDC(Map Diagnostic Context).


## Dependency Vulnerabilities

In this section we will go into identifying security vulnerabilities that are tied to dependencies
in your assembly.

### Common Vulnerabilities and Exposures

One of the shared ways of publically identifying vulnerabilities with software dependencies is in
the [National Vulnerability Database (NVD)](https://nvd.nist.gov/). This database indexes
vulnerabilities tied to software artifacts by using CVE (Common Vulnerabilities and Exposures)
identifiers. Tooling and consumers that wish to correlate vulnerability data about software libaries
generally reference feeds from the NVD, and then reference vulnerabilities by using the CVE
identifiers.

CVEs are tied to products, which have their own set of identifiers by using Common Platform
Enumerations (CPEs). CPEs are used to identify products, which for the topic of Java assemblies, are
Java artifact names. Here is an example of a CPE identifier (using the 2.3 format) for
jackson-databind-2.9.9:

```
cpe:2.3:a:fasterxml:jackson-databind:2.9.9:*:*:*:*:*:*:*
```

From this scheme, you can recognize common Maven identifiers (groupId: `fasterxml`, artifactId:
`jackson-databind`, and `version`: `2.9.9`).

### OWASP Dependency Check

As an assembly owner, we want to utilize tooling that can do this type of assessment of Java
dependencies to CVE information. Luckily, there is an open-source project that does that for you! The OWASP Dependency Check project has a [Maven plugin](https://jeremylong.github.io/DependencyCheck/dependency-check-maven/) and CLI that can help on doing assessments of your projects.

### CLI

You can install the CLI locally and run a scan of the example service with the following steps. This approach may be desirable as you can quickly assess existing assemblies without necessarily changing their Maven plugins:

```bash
# Download the OWASP Dependency Check CLI install
wget -O owasp-cli.jar https://dl.bintray.com/jeremy-long/owasp/dependency-check-4.0.2-release.zip
unzip owasp-cli.jar
```
### Maven Dependency Plugin

You can then include the Maven plugin in your builds to fail builds when CVEs with a CVSS score that is too high. In a later section, we will highlight how we leverage this in our build as part of leveraging maven-base-pom.

### Automating your dependency updates

As part of managing your dependencies in your assembly, a common goal is just keeping your dependencies up-to-date. With te case of security vunlerabilities, you generally are in a better position when you are up-to-date on your Java dependencies as you have included more fixes and you have less older versions which have had time to identify CVEs. To automate this task you can:

* Leverage the Maven [Versions plugin](https://www.mojohaus.org/versions-maven-plugin/) to update your dependencies on a routine schedule (ex. every Monday morning)
* Create a pull request to your project with the changes proposed
* Allow your normal CI flow to validate the PR and to post the status

Example of leveraging the the versions plugin to prep what changes are possible to be applied:

```bash
mvn org.codehaus.mojo:versions-maven-plugin:2.7:display-dependency-updates -N -U -l candidates.txt
```

## Versioning

It's important to version both your assembly and any reusuable components that you own in a
way that is consistent and communicates their compatability with existing versions.
  
The accepted industry standard is known as [semantic versioning](http://semver.org/)
and expects version numbers be generally be in the form of `MAJOR.MINOR.PATCH` 

A core tenant of semver is that once a versioned artifact is released it
must not be modified. This has been communicated as _immutable artifacts_, which
means once an artifact is released into the wild, it cannot ever change for that version.
For more information on this topic, and why you should never release over an existing
version, see: [[RFC] Artifact immutability in release repositories](https://connect.ucern.com/thread/2199121).

### PATCH

The patch version is incremented when there is a bug fix which does not impact any of
the public APIs.  It should not require changes on behalf of the consumer.  It should
be passive and safe to use without any unexpected results.

### MINOR

The minor version should be incremented when there is a **passive** or backwards compatible
change made:

* Adding a new method or new API
* Adding a new required dependency that didn't exist before
* Deprecating old methods/classes

### MAJOR

The major version should be incremented whenever there is a **non-passive** or potentially
breaking change to an API, some examples of changes which necessitate a major version bump:

* Adding a method to a interface public interface (if no default implementation is provided)
* Removing, moving or renaming a method or class.
  * :boom: WARNING: _"Public APIs, like diamonds, are forever"_. -Joshua Bloch
* Taking a new major version of a dependency
* Bumping a required technology minimum (e.g. compiling with a newer Java version)
* Major functionality changes that would require a consumer to change their code to correctly use the project.

Generally it is better to over report the compatability risk of a new version than to
under report.  *Focus on the user*. 

### QUALIFIER

Releases tagged with a qualified version (e.g. 3.0.0-alpha, 1.0.0-RC2, 2.0.0-TP23, 1.0.0-jdk5) should be treated with caution.
Only use them when you have a specific reason for doing so.
Particularly in production settings, it can be confusing.  Tooling that has to sort/analyze based on versions can
break with qualifiers.  Please, avoid perpetual alpha/beta versions.

### 0.y.z VERSIONS

There is an exception for projects still in version 0.y.z.  Many **non-passive** changes can and do occur in this range
at every release increment.  That being said, once your software is being used in production, it should probably be 1.0.0.

### x.y VERSIONS

Many projects omit the third PATCH version.  It is preferred to include the PATCH version in all cases.  Release with version 1.0.0 instead of 1.0.

### Troubleshooting tips:

Many times it is helpful to evaluate the classes being loaded, and what artifact they are originating from. To do this, you can utilize the the -verbose:class:

To view the contents of the example project, you can do the following:

```bash
# -t: list table of contents for archive 
# -f: specify archive file name
jar tf target/example-war-1.0-SNAPSHOT.war
```

### maven-shade-plugin
The maven shade plugin supports combining all dependencies into a single jar. When duplicate classes are discovered only one can survive, the highlander version of the class may not include all the methods required.

# Java Basics: (Java8-Jav16 Features)
* [Java8-Java15 blog](https://medium.com/swlh/from-java-8-to-java-15-in-ten-minutes-f42d422a581e)
* [Java Features and versions](https://www.marcobehler.com/guides/a-guide-to-java-versions-and-features)

# Maven: 
* [Basics](https://www.baeldung.com/maven) 
* [Dependency Scope](http://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Scope)
* [Dependency Management](http://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#dependency-management)
* [Plugins](http://maven.apache.org/plugins/index.html)

# Java Heap Analysis: 
* [Workshop](https://jvmperf.net/docs/jmc/memory/)
* [GC easy](https://gceasy.io/)
* [Java Stack Heap](https://www.baeldung.com/java-stack-heap)
* [dzone Java memory management ](https://dzone.com/articles/java-memory-management)
* [Javatpoint heap](https://www.javatpoint.com/java-heap)

# Java Logging best practices:

### Log levels

Different logging abstractions have slightly different definitions
of log levels, and their intention. 

* **Tracing**: The tracing facility is designed for developers and those who provide development support. Traces are usually fine-grained messages indicating flows of control through algorithms, but a tracing facility is always disabled by default in production deployments. Tracing should yield the greatest benefit during development with diminishing returns as the software nears production. This is not to preclude the use of tracers in production deployments, as they prove useful when engineers must get involved with issue investigation and isolation.
* **Logging**: The logging facility is designed for those who administer systems. Such a person is not to be confused with a sophisticated developer, which is too often the case. Logging is perhaps the most visible indicator of the absence of manageability requirements during software design, because most messages are not useful to those for which they are intended to serve. To no surprise, past observations have shown that the majority of log messages actually serve the developer, even though the system administrator is the most deserving of crucial information. In order to change behavior, developers will notice that the logging facility requires a resource key, which not only deters ad hoc logging (which is better served through the tracing facility) but also establishes the foundation for the localization of messages.
* **Error Reporting** : The error reporting facility is similar to the logging facility, but is designed to report exceptions. Developers will notice that the traditional level qualifier associated with popular logging systems is not present in this specification. This was an intentional design decision, rooted in the fact that developers are often not equipped to determine the severity of events without some context. This led to the first-class distinction between logging and error reporting.

#### SLF4J abstraction

We will learn more about [this abstraction](https://www.slf4j.org/) in an upcoming section, as this is the most 
popular logging abstraction. However, it doesn't contain as much documentation or guidance on 
its levels, as it defers to the logging implementation's guidance for the levels that it maps to.

#### commons-logging abstraction

[commons-logging](http://commons.apache.org/proper/commons-logging/guide.html#Message%20Priorities/Levels) has some guidance on log levels, as it is trying to accomodate
many different implementations.

* **Fatal** - Severe errors that cause premature termination. Expect these to be immediately visible on a status console. See also Internationalization.
* **Error** - Other runtime errors or unexpected conditions. Expect these to be immediately visible on a status console. See also Internationalization.
* **Warn** - Use of deprecated APIs, poor use of API, 'almost' errors, other runtime situations that are undesirable or unexpected, but not necessarily "wrong". Expect these to be immediately visible on a status console. See also Internationalization.
* **Info** - Interesting runtime events (startup/shutdown). Expect these to be immediately visible on a console, so be conservative and keep to a minimum. See also Internationalization.
* **Debug** - detailed information on the flow through the system. Expect these to be written to logs only.
* **Trace** - more detailed information. Expect these to be written to logs only.

Another note of guidance from commons-logging:

> When Info Level Instead of Debug?
> 
> You want to have exception/problem information available for first-pass problem determination in a production level enterprise application without turning on debug as a default log level. There is simply too much information in debug to be appropriate for day-to-day operations.

#### Log4j implementation

[Log4j](https://logging.apache.org/log4j/2.x/) is a logging implementation rather than abstraction, but a very common one. Here are some of the levels that
are utilized, with [short guidance](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/Level.html) on the types:

* TRACE: A fine-grained debug message, typically capturing the flow through the application.
* DEBUG: A general debugging event.
* INFO: An event for informational purposes.
* WARN: An event that might possibly lead to an error.
* FATAL: A severe error that will prevent the application from continuing.
* ERROR: An error in the application, possibly recoverable.

## slf4j
It is recommended to use slf4j for the logging interface. 
The two primary `slf4j` providers [logback](http://logback.qos.ch/manual/mdc.html) and [log4j](https://logging.apache.org/log4j/2.x/manual/thread-context.html) supply runtime implementations of the MDC interface.

## Be aware of log level differences with implementations

Since your logging configuration is specific to the logging implementation, you need to be
aware of the specifics of the implementation. Many different logging implementations exist, 
all of which may have different logging files that control its configuration. Examples:

* [JDK logger](https://docs.oracle.com/cd/E19717-01/819-7753/gcblo/): `logging.properties`
* [log4j-1.x](https://logging.apache.org/log4j/1.2/faq.html): 
`log4j.properties`, `log4j.xml`
* [log4j-2.x](https://logging.apache.org/log4j/2.x/manual/configuration.html): 
`log4j2.yaml`, `log4j2.json`, `log4j2.xml`
* [logback](http://logback.qos.ch/manual/configuration.html): 
`logback.xml`

` _Note` Many of the logging providers have multiple ways of being
configured. The examples provided above was done to simply show that
there are different files for these providers._

## TIPS

### Avoid the Java System Library

You should not write directly to System.out or System.err, or rely on methods that do, such as
[Throwable.printStackTrace()](https://docs.oracle.com/javase/8/docs/api/java/lang/Throwable.html#printStackTrace--). 
Relying directly on the System library to write to the console can result in critical
information or context being lost. Even if a process redirects standard out and error to a file,
information may be lost if that link is broken (e.g Log Rotation).

If you use a logging abstraction, then your runtime can choose an implementation that directs logs
appropriately based on their needs.

### Exceptions should be logged or propagated

When an exception occurs it is important to capture the full context of the exception, including the
stack trace. If the exception is going to be re-thrown be sure to include the original exception as
the cause of the new exception. If the exception is not being propogated then be sure that the details
of the exception is included in the log message. **NEVER** just catch and eat an exception or just log
a generic statement such as "exception occurred".

### Not using Static Code Analysis

Both [PMD](http://pmd.sourceforge.net/pmd-4.3.0/rules/logging-java.html) and [findbugs](http://findbugs.sourceforge.net/)
provide rulesets which can catch common logging bugs. Using these static analysis tools
can help ensure that you are utilizing the logger framework effectively and prevent incorrectly
formatted messages from appearing in your log stream. 

We will cover more of this in the next section: [Testing](../007-testing/README.md), on how to use these tools
and the details of what they can provide.

### Logs causing errors

When constructing log messages exercise care that the log message itself does not cause an error.
Errors in logging can be particulary problematic because they may not be exposed until long after
it's written, e.g. we turn the log level up to troubleshoot an issue and expose an NPE on a
request that may have completed successfully before.

### Logging in loops or collections

When dealing with collections or loops we need to be careful that we don't create noise in the logs
by writting very large messages or a mass of nearly identical messages. Generally we should avoid
including collections in a log message if we aren't confident it will contain a reasonable number
of items and when working with loops we should try to only log events that we would not expect to
occur frequently.

### Over reliance on the toString method

When including an object in a log message we must be sure that the final log will be meaningful.
Care should be exercised when relying on the toString method of an object to add context to
the the log event. There are two potential pitfalls in doing so:

1. All objects inherit the base toString implementation, so there is no guarantee that
the textual representation will be helpful or meaningful. This is especially true when dealing
with interfaces where you may not know the actual implementation(s) that will be
encountered at runtime.
2. Even if you are confident that the object provides a well formatted toString implementation you may
still wish to avoid relying on it. If the object is very large or contains PHI then including
the entire object in the log messages exposes your consumers to extraneous or potentially
sensitive information.
