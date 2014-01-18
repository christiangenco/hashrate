* hashrate calculator object
* set tmp directory for raw json with class variable
  * initialize in rails as `Rails.root.join('tmp')`
* look in tmp directory for json
  * if it doesn't exist OR if the most recent difficulty is >15 days old, download it
* when accessing `@difficulties`, extrapolate data 2 years in the future if it doesn't already exist
* all methods are class methods
