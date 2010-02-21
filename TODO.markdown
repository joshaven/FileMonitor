* Add a per directory seconds-between-scans setting so that it isn't possible for a 
  directory to be scanned for changes 1,000,000 times a second or some crazy such thing.
* remove file\_name\_regexp & callback variables from the :files\_recursive method.  The
  :files\_recursive method should not be calling add, it should only return a collection of files.