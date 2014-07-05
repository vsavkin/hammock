# Trying Demo App

1. `cd demo`.
1. Run `dart server.dart`.
2. Open `localhost:3001/main.html`.
3. Open the network tab and check all the requests that have been made.
4. Remove everything from one of the site name fields and click on `Update Name`. You should see an error in the console.
6. Type in something and click on `Update Name` again. You should see `success`.
7. Refresh the page to make sure that the data is saved.
8. Delete one of the posts and refresh the page.

The server script will print all the requests and responses.