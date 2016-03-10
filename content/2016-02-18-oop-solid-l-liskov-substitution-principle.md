---
title: OOP SOLID Principles "L" - Liskov Substitution Principle
date: 2016-02-18
tags: oop
type: post
---

According to the [Wikipedia](https://en.wikipedia.org/wiki/Liskov_substitution_principle) the Liskov Substitution Principle (LSP) is defined as:

```
Subtype Requirement:
Let f(x) be a property provable about objects x of type T.
Then f(y) should be true for objects y of type S where S is a subtype of T.
```

The basic idea - if you have an object of type `T` then you can also use objects of its subclasses instead of it.

Or, in other words: the subclass should behave the same way as the base class. It can add some new features on top of the base class (that's the purpose of inheritance, right?), but it can not break expectations about the base class behavior.

<!-- more -->

The expectations about the base class can include:

- input parameters for class methods
- returned values of the class methods
- exceptions are thrown by the class methods
- how method calls change the object state
- other expectations about what the object does and how

Some of these expectations can be enforced by the programming language, but some of them can only be expressed as the documentation.

This way to follow the LSP it is not only important to follow the coding rules, but also to use common sense and do not use the inheritance to turn the class into something completely different.

Let's see what rules do we need to follow in the code.

# Methods Signature Requirements

Signature requirements are requirements for input argument types and return type of the class methods.

Let's imagine we have following class hierarchy:

```text
   .------------.          .------------.          .-------------.
   | LiveBeing  |          |   Animal   |<|--------|     Cat     |
   |------------|<|--------|------------|          |-------------|
   | + breeze() |          | + eat()    |<|---.    | + mew()     |
   '------------'          '------------'     |    '-------------'
                                              |
                                              |     .------------.
                                              |     |    Dog     |
                                              '-----|------------|
                                                    | + bark()   |
                                                    '------------'
```

Here the `LiveBeing` is the base class which is inherited by `Animal` which in turn is inherited by `Cat` and `Dog`.

I will use this hierarchy to explain the signature rules.

## Covariance (Parent -> Child -> ...) of return types in the subtype

This rule means that the child class can override a method to return a more specific type (`Cat` instead of `Animal`).

Of course, it can return the same type, but it can not return more generic type (like `LiveBeing` instead of `Animal`) and it can not return a completely different type (`House` instead of `Animal`).

This rule is easy to understand and it feels natural.
Here is an example in pseudo-code:

```python

class Owner
  Animal findPet()
      return new Animal()

class CatOwner extends Owner
  Cat findPet()
      # Covariance - subclass returns more specific type
      return new Cat()

class BadOwner extends Owner
  LiveBeing findPet()
      # Contravariance - breaks the rule and returns more generic type
      return new LiveBeing()

function doAction(Owner owner)
    # OK for Owner, we can put an Animal object into the `animal` variable.
    # OK for CatOwner, we can put a Cat object into the `animal` variable.
    # Problem for a BadOwner object, a LiveBeing object can not use be used
    # the same way as Animal object.
    Animal animal = owner->findPet();
    amimal->eat();
```

The `doAction` function demonstrates a possible use case.
It is OK if `owner` is a `CatOwner`, because both `Animal` and `Cat` should behave the same.

But the `BadOwner` returns a `LiveBeing` and it is a problem. There is no guarantee that `LiveBeing` object behaves the same as `Animal`.

For example, if we call `animal->eat()` this will not work for the `LiveBeing` (it doesn't have such a method).

## Contravariance (Child -> Parent -> ...) of method arguments in the subtype

This means that a child class can override the method to accept a more generic argument type than the method in the base class (like accept the `LiveBeing` instead of `Animal`).


```python
class Owner
  void feed(Animal animal)
    ...

class GoodOwner extends Owner
  # Contravariance - subclass accepts more generic type
  void feed(LiveBeing being)
    ...

class BadCatOwner extends Owner
  void feed(Cat cat)
    ...

function doAction(Owner owner)
  owner->feed(new Dog) # OK for Owner, he accepts any Animal, including the Dog
                       # OK for GoodOwner, he accepts any LiveBeing, including the Dog
                       # Problem for CatOwner, he doesn't expect the Dog
```

In practice, it may feel tempting to break this rule and define the class like `BadCatOwner` above.

But, as we can see, the `BadCatOwner` breaks LSP and we can not use it in the same case where we can use the `Owner` object.

Note that although using the more generic type in the subclass is OK in terms of method signature, it may be problematic logically:

```python
class Owner
  void feed(Animal animal)
    animal->eat(this->findFood());

class GoodOwner extends Owner
  void feed(LiveBeing being)
    # Problem: LiveBeing doesn't have the `eat` method
    being->eat(this->findFood());

```

There is a problem here - the `GoodOnwer::feed` can not call the `being->eat()` method because `LiveBeing` doesn't have the `eat` method.

And this way, `GoodOwner` also can not just forward the execution to the parent method with something like `parent::feed(being)`.

By the way, if the method doesn't use parent implementation, it may [indicate the LSP violation](http://stackoverflow.com/q/35070912/4612064) - potentially we can have a different behavior for this subtype than in the parent class.

## Exceptions should be same or subtypes of the base method exceptions

No new exceptions should be thrown by methods of the subtype, except where those exceptions are themselves subtypes of exceptions thrown by the methods of the parent type.

```python
class BadFoodException

class BadCatFoodException extends BadFoodException

class LowQualityFoodException


class Owner
  void feed(Animal animal, Food food)
    if (not this->isGoodFood(food))
      throw BadFoodException()
    ...

class BadOwner extends Owner
  void feed(Animal animal, Food food)
    if (not this->isHighQualityFood(food))
      throw LowQualityFoodException()
    ...

function doAction(Owner owner)
  try
    owner->feed(new Dog, new SomeFood)
  catch (BadFoodException error)
    # OK for Owner, it can raise BadFoodException
    # OK for CatOwner, it can raise BadCatFoodException (subclass of BadFoodException)
    # Problem for BadOwner, it can raise LowQualityFoodException and it will not be
    # caught here
    ...

```

If we don't follow the rule about exception types, the client code written for the base class `Owner` will fail for the subclass `BadOwner` and this way we violate the `LSP`.

# Inheritance requirements

These requirements describe additional rules for inherited methods related to the [Design by contract](https://en.wikipedia.org/wiki/Design_by_contract) concept. It defines the "contract" for each method which includes preconditions, postconditions and invariants:

- [Precondition](https://en.wikipedia.org/wiki/Precondition) is a condition or predicate that must always be true just prior to the execution of some section of code.
- [Postcondition](https://en.wikipedia.org/wiki/Postcondition) is a condition or predicate that must always be true just after the execution of some section of code
- [Invariant][1] is a condition that can be relied upon to be true during execution of a program, or during some portion of it.  For example, a loop invariant is a condition that is true at the beginning and end of every execution of a loop.

## Preconditions cannot be strengthened in a subtype

In most cases preconditions are expectations about method input arguments, also an object's internal state can be a part of the precondition.

This is a more generic rule of the contravariance rule for method arguments. The contravariance rule says that subclass can accept more generic argument type (`LiveBeing` instead of `Animal`), this is a weaker precondition (subclass accepts a wider range of arguments).

The same logic applies not only to the types of arguments but to the other kind of expectations as well, such as a range of the integer argument:

```python
class The24Hours
  void setHour(int hour)
    # hour should be between 0 and 23
    assert (0 <= hour and hour <=23)
    ...

class TheDay extends The24Hours
  void setHour (int hour)
    # breaks the rule and strengthens the precondition
    # day hour should be between 8 and 16
    assert (8 <= hour and hour <= 16)
   ...

function doAction(The24Hours hours)
  hours->setHour(3); # OK for `The24Hours` object
                     # Problem for `TheDay` - it will raise an error
```

So the stronger precondition in the child class broke the client code which worked for the parent class.

At the same time, if we make the precondition weaker (or even remove it), the client code will work the same way as for parent class.

## Postconditions cannot be weakened in a subtype

Postconditions are usually expectations related to the method return value.

Again, this the more generic rule similar to the covariance rule (method can return `Cat` instead of `Animal`), the postcondition is strengthened.

An example of postcondition rule violation:

```python
class The24Hours
  number setHour(number hour)
    ...
    assert (this.hour is integer)
    return this.hour

class TheTime extends The24Hours
  number setHour(number hour, number hourFraction)
    this.hour = hour + hourFraction / 100
    # the postcondition is weaker (float is a wider area than integer)
    assert (this.hour is float)
    return this.hour

function doAction(The24Hours hours)
  int result = hours->setHour(3); # OK for The24Hours
                                  # Problem for TheTime, it returns float
```

So again, due to `LSP` violation, we can not use the child class instead of the parent.

## Invariants of the parent type must be preserved in a subtype

Invariant is something that is not changed during the method execution. It can be the whole or part of the object internal state:

```python
class The24Hours
  # invariant: this.hour is not changed
  number getHour()
    return this.hour

class TheCounter extends The24Hours
  # invariant violation: this.hour is changed
  number getHour()
    result = this.hour
    this.hour += 1
    return result

function doAction(The24Hours hours)
  if (hours->getHour() <= 12)
     # OK for The24Hours
     # Problem for TheTime, now getHour() can return value > 12
     print 'First half of the day', hours->getHour()
```

## History constraint (the "history rule")

The subtypes should not introduce new methods that will allow modifying the object state in a way that is not possible for the parent class.

The internal object state should be modifiable only through their methods (encapsulation) and the client code can have some expectations as of the possible ways to modify the internal state.

For example:

```python
class Time
  # it is immutable, once time is set, there is no way to change it
  constructor(int hour, int minute)
  getTime()

class FlexibleTime extends Time
  # violates the "history" rule
  # it allows changing the object state
  # but the clients who use Time can be broken due to this
  setTime(int hour, int minute)

doAction(Time time)
  print 'Now it is: ', time->getTime()
  doOtherAction(time)
  # OK for Time, it can not be changed, so value is the same
  # Problem for FlexibleTime, the `doOtherAction` could change it
  print 'Now it is still: ', time->getTime()

```

# Links

[Wikipedia:Liskov substitution principle](https://en.wikipedia.org/wiki/Liskov_substitution_principle)

[Agile Design Principles: The Liskov Substitution Principle](http://www.engr.mun.ca/~theo/Courses/sd/5895-downloads/sd-principles-3.ppt.pdf)

[Wikipedia: Covariance and contravariance][2]

[1]: https://en.wikipedia.org/wiki/Invariant_(computer_science)
[2]: https://en.wikipedia.org/wiki/Covariance_and_contravariance_(computer_science)#Inheritance_in_object-oriented_languages
