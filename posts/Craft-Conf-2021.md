---
title: "CALM Theory"
date: 2021-07-06T09:05:39+02:00
---

Recently, I had the opportunity to attend Craft Conference.
Unfortunately, the event was entirely online (due to the pandemic), which means no free food, but the variety of the talks had compensated for it.
The conference was 3 days long, and featured many well-knows speakers (like Kevlin Henney, Dave Farley, and others).
There were 6 virtual "stages" you could choose from at any given time, and although the organizers tried putting different topics in each segment, so everyone could find their nieche, I was in a constant dilemma, trying to decide which talk to attend.
Fortunately, most of the talks have recordings available for the attendees.
This blogpost is about one of the talks I attended, which was given by Joe Hellerstein, a  professor at UC Berkeley, about the CALM Theory.

## CALM

So what is CALM, and why is it important?
Before answering these questions, let's start first from a broader perspective.
As I will discuss it shortly, CALM is about distributed systems, more specifically some of their attributes, so first we should look at them.
As cloud computing is rapidly becoming the norm these days, the need for large-scale distributed systems is skyrocketing.
As we approach the limit's of Moore's law, single computers are becoming too slow to be used for serious work, hence the need for putting them into a cluster, so they can solve them problem in parallel, drastically reducing the time needed.

## Coordination

This is where the problem of coordination comes in.
For the computers to be able to do anything meaningful, somehow they have to coordinate between themselves.
Alas, the problem of coordination is not a trivial one.
There are existing protocols today, that are proved to be correct, like Paxos, or the Two-Phase Commit, but they are hard to implement, and, consequently, easy to screw up.
The other, arguably bigger problem with them, is that they are very costly.
Coordination can have a tremendous impact on performance, which makes it hard to create scalable systems.
A figure I took from the talk was about modern key-value stores: they can spend 90%(!) percent of their time waiting on coordination.
That's a huge amount of computation power that could be spent elsewhere.

## Monotonicity

One last quick definition, before I start discussing CALM itself: monotonicity.
Monotonicity is the formal definition of the group of problems, that need coordination.
If we can prove that a problem is monotonic, then we can be sure that a coordination-free implementation exists for it, that guarantees consistency.
If the problem is non-monotonic, than it always requires coordination.
I think you can already see where this is going.

## CALM Again

CALM is mainly about avoiding coordination if possible.
It stands for Consistency as Logical Monotonicity, and it shows that monotonicity is what decides if a problem needs coordination or not.
It allows us to formally reason about the given problem, and make sure that if possible, we choose the most optimal implementation, by avoiding coordination.
Before CALM, the literature was mainly occupied with "memory models" and "storage consistency", which was so low-level, that it was mostly irrelevant to application designers.
The question of when is it possible to avoid coordination was never asked.

It's also kind of a "positive" theory: it's about what is possible for a smart engineer to do.
In contrast, the CAP Theorem can be considered as a "negative" one.
The CAP Theorem states that a system can exhibit only two of the following properties: *consistency*, *availability*, *partition-tolerance*.
So it's about what is impossible.
Fortunately, the CAP Theorem only holds true if we consider arbitrary programs.
If we apply some constraints, all 3 of the properties can be achieved, and of course, using CALM, we can achieve all of them.
So CALM provides a formal framework that verifies the intuition, that we can work around CAP.

Using CALM principles with our existing tools can be hard, as they don't provide and easy way to apply them by default.
For example, tradition imperative languages model the world as a collection of named, mutable variables.
In this framework, it can be tricky to apply CALM principles.
If you are thinking now about functional languages, then you are right, it's much easier to apply these principles with them.
Functional languages use immutable variables (at least the *purely* functional ones), which is a monotonic pattern.
Immutable variables then can be generalized to immutable *data structures*.

## Bloom

To make it even easier to apply CALM principles, there is a language called Bloom, created by the same people.
You can check it out [here](http://bloom-lang.net/).
Bloom's goal is to make distributed systems easier to program and reason about.
As bloom is inherently data-centric, it represents the system state and events as named data.
All computation is then expressed as queries over this data.
By doing this, bloom makes monotonic patterns the default, and the easiest constructs to work with.
One consequence of this is that the checking of the monotonicity of the program is as easy as running a syntax check.

Obviously there is much more to this topic, I just barely scratched the surface with this post, so if you are interested, I encourage you to read the [paper](https://arxiv.org/abs/1901.01930).
