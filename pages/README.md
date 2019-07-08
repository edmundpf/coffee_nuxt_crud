# PAGES

This directory contains your Application Views and Routes.
The framework reads all the .vue files inside this directory and creates the router of your application.

More information about the usage of this directory in the documentation:
https://nuxtjs.org/guide/routing

## Included functionality
* Login
* Logout
* Create records
* Update records
	* Includes Set, Push, and Push Unique functionality for array fields
		* Set - sets/overwrites array values via comma-separated-values i.e. `1,2,3`
		* Push - pushes array values onto array
		* Push Unique - pushes values onto array if they don't exist already
			* **NOTE** - this DOES NOT delete existing duplicates, it only applies to the records being pushed
* Delete records
* View records
