# dinode

Dependency Injection framework for Node.js (and JavaScript in general)



### Getting started

The very basics are shown here. First, an instance of the injector is created. Then the creation of a shape-module depending on the constants-module. Then the creation of a constants-module, without dependencies. Finally an anonymous module depending on the shapes-module.

    var dinode = require('dinode');

    var di = dinode.construct();

    di.registerModule('shapes', ['constants'], function(deps) {
      var constants = deps.constants;
      return {
        sphereVolume: function(radius) {
          return 4 * constants.PI * radius / 3;
        }
      };
    });

    di.registerModule('constants', [], function() {
      return {
        PI: 3.1415
      };
    });

    di.registerModule(null, ['shapes'], function(deps) {
      var shapes = deps.shapes;
      var vol = shapes.sphereVolume(4000);
      console.log("The volume of the earth is " + vol + " liters");
    });

By default, anonymous modules are the only ones that triggers execution. They can't be depended on, so they must do something with side-effects to be of interest. Named modules on the other hand are only loaded if they're needed to run an anonymous module.



## Features

* Detects circular dependencies
* Allow both sync and async module definitions
* Lazy module execution - execute only what is needed
* Detect missing modules on startup - OR - wait for them to be defined later
* Many convenient sugar methods for creating modules
* Made for extra simple usage using coffee-script
* Automatic dependency detection


### Async module definitions

Here the connection to the database is registered as a module. It helps prevent callback-hell by letting modules that needs the open connection depend on that connection. The dependants does not need to know whether their dependencies are sync or async; they will simply wait for the result to become available.

This makes for very easy refactoring when going from sync to async implementations. It also gives very clean and sync-looking modules, even when there are many async things being depended on the background.

    var dinode = require('dinode');
    var someDatabase = require('some-db');

    var di = dinode.construct();

    di.registerModule('dbConnection', [], function(deps, callback) {
      someDatabase.open('foo.bar@localhost/myDb', function(err, db) {
        callback(err, db);
      });
    });

    di.registerModule(null, ['dbConnection'], function(deps) {
      var db = deps.dbConnection;
      db.query('SELECT * FROM something", function(err, result) {
        console.log(err, result);
      })
    });



### More feature descriptions

To be written...



## Introspection

Sometimes it can be hard to figure out what the dependency tree looks like or why it is not resolving like it should. Luckily there's a method for peeking at the internal state of dinode; `introspect`



### Example

To be written...



### There are five statuses:

* **Referred**: the module has not yet been defined, but it has been referred to as a dependency from some defined module. It will not have any dependencies (those are unknown), but all modules that have declared a dependency on it will be listed as dependants.
* **Waiting**: the module has been defined, but no module that is set to resolve depends on it. Unless such a module is defined, this one will remain "waiting" and will never resolve. It may have both dependencies and dependants. All its dependants will also be "waiting" (or else this one would not be). When running in "eager mode", no module will ever be waiting, since they are all set to resolve.
* **Ready**: the module has been defined and it is set to resolve as soon as all its dependencies are resolved.
* **Resolving**: the module has been defined, all its dependencies have resolved and it is currently being resolved.
* **Resolved**: the module has been defined and resolved.
