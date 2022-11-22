This is my article for publishing on [Medium.com](https://medium.com):

# How can I monitor my integration application? - The question behind the question!

*Profiling and Tracing*, *Monitoring and Alerting* as well as *Exception Tracking* or *Tracing* of individual calls on their way through a bunch of microservices (mesh) are becoming more important then ever if a company decideds to move all IT resources to the cloud. What das *Cloud* mean in that context can be quite different. Often its a synonym for a virtual private cloud environment hosted at one of the hyper scalers like AWS, Azure, GCP or infrastructure providers like Linode, Hetzner to just name a view. In other context the strategy behind a move to cloud initiative is much broader. Often enterprises do have a need to support a range of different infrastructure or cloud service providers. And that's the tricky part, as one cannot rely on any pre-built monitoring, alerting and tracing features provided by an individual vendor. Therefore specialized providers emerged to solve the problem with another cloud SaaS offering.

Recently the developers of a customer approached us with the question how to enable applications running on our specialized integration application server for supervision of such a cloud monitoring provider. More specific, the question was how to add a library provided by their cloud monitoring vendor to include the integration services into the same centralized monitoring infrastructure. The expectation of the DevOps seemed to be that adding the library would already solve their monitoring problem. Here is where I started to explore things.

I'm working for [Cloud Software Group](https://www.cloud.com/), a newly formed software vendor integrating [TIBCO](https://www.tibco.com/) and [Citrix](https://www.citrix.com/). Therefore, the integration server in question here is [TIBCO BusinessWorks Container Edition](https://www.tibco.com/resources/datasheet/tibco-businessworks-container-edition). But the story and considerations also apply to other solutions in the integration space as well.

## What is Monotoring?

..ideas from [What is the difference between Logging, Tracing & Profiling?](https://greeeg.com/en/issues/differences-between-logging-tracing-profiling)
..or [Tracing vs Logging vs Monitoring: What’s the Difference?](https://www.bmc.com/blogs/monitoring-logging-tracing/)
..or [Distributed tracing vs. application monitoring](https://www.sumologic.com/blog/distributed-tracing-vs-application-monitoring/)

..Application Performance Management - [Wikipedia APM](https://en.wikipedia.org/wiki/Application_performance_management) incl. the APM conceptual framework...


## What was really needed?


## What options do we have?

solution already built into product
solution by adding 3rd party code and instrument
solution by vendor - propriatory but integrated

## Solutions

..app server runs on a JVM
..proven solution since many years
..orginally not made for containers, but reacently extendended for the container world

### Instrumenting a JVM


### How does it work in Container land?


### OMG, we get so many details!

..automatic instrumentation gives insight to everything going on on the JVM..

### OpenTelemtry is already built in!

..OpenTelemtry was built into the application server [TIBCO BusinessWorks Container Edition]() already..
..shows metrics relevant to the business oriented developer

#### Jaeger: Tracing calls trough a Mervice Mesh

..tooling to trace / follow handling of integration requests to understand problems or even get notified if importantd metrics reveal bottlenecks on some dependend microservices or important resources

#### Tracing calls via Cloud Monotoring Solution

..same is available on a central place, nice!


### Performance Tracing is already built-in!

..integration application server already comes with a monitoring and call tracing component.
..better suited for the integration developer as it shows metrics on the same level as the developer tooling is using it


# Conclusion

A combination of of 

It is important to ask the *question behind the question" to understand why you are following an approach you told to follow. Is it the right thing? As my investigation and tests showed, it will show more options and reveal more requirements by other personas that would not be covered by just following the one requirement. By investing a bit more time to understand the requirements a better solution could be designed. So it was worth to ask the question behind the (technical) requirement.
