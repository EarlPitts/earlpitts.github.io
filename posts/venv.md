---
title: "Python Environment"
date: 2020-03-07T22:09:41+01:00
draft: false
toc: false
images:
tags:
  - python 
  - pip
  - virtual
  - env
  - environment
---

For making your life a lot easier while developing with python, it's important that you know about the concept of virtual environments.
With virtual environments, you won't clutter your global environment, and you can even use different versions of specific packages.

Before we can discuss the topic of virtual environments, we have to know about package management in python.

## PIP

Pip stands for Pip Installs Packages (recursive acronyms are apparently very popular among tech people). When you install a package with pip, it places it inside the current namespace, so you can import it in your scripts.  
Using pip is really simple, you just write `pip install`, then the package you want. Pip can write the packages installed in the current environment with their version number into a file, that can be used to install the same packages elsewehere. To do this, just do:

`pip freeze > requirements.txt`

This will create a requirements.txt file with the name and version number of all of your packages. (Or overwrite the old file if you have one.)

So now that we know how to use pip, we can create our virtual environment.

There are a number of ways to create virtual environments (pew, pipenv, virtualenv, just to name a few). I'll use venv, but everything should work with other methods. 

To create a virtual environment named *venv*, issue the command:

`python -m venv venv`

This will generate a bunch of file in a folder named venv.  

*It's a good practice to make a line with the folder's name in your .gitignore, because (most of the time) you don't want to track your packages in version control.*

To "activate" your environment, you can source the activate file inside venv/bin/activate (assuming *venv* is your folder's name):

`source venv/bin/activate`

Now your environment's name will appear inside your propmt, and you're ready to go. Everything you install with pip and every environmental variable you set will be inside this environment.

## .env

It's good practice to save your env variables in a .env file. This will contain passwords and local endpoints, and you probably don't want to put it in version control.  
When you start developing, you can just source it, and the variables will be set in your environment.