# Movie Queues Services
A JSON service for a Netflix-like DVD rental company to manage users’ movie queues.  

API Features include:
- retrieve a list of movies in rank order of next delivery 
- add/remove movie queues
- add/edit/remove movies from a customer’s queue
- queues can be sorted base on a movie’s title, genre, or year

System Features include:
- Pre-loadable Movie data cache ([Movies are stored in a remote service](https://github.com/edithau/movie_services))
- Pre-loadable User data cache ([Users are stored in a remote service](https://github.com/edithau/movie_services))
- In-memory Movie Queue database, backed by disk storage

## Design
The design is aimed to support the following work load:
- [10 million users](https://www.statista.com/statistics/250940/quarterly-number-of-netflix-dvd-subscribers-in-the-us/)
- [15K movies + tv shows](https://usa.newonnetflix.info/catalog/year/all/2017)
- Max of 200 movies in a user’s delivery queue

![Design Diagram](/images/mqs_design.png?raw=true "Design Diagram")

## Service Endpoints
##### Create a movie queue for a user
```
POST /movie_queues
param: user_id 
param: movie_ids    # a list of movie ids in delivery order 
```
##### Get a user's movie queue
```
GET /movie_queues/<user_id>
param: sort_by      # sort by rank(default), or a movie field (year, genre, name)
param: order        # a list of movie ids in delivery order 
```

##### Update a user's movie queue
```
PUT /movie_queues/<user_id>
param: movie_id     # the movie to add/reorder/remove from user's queue
param: new_rank     # new position in the queue (see below for re-rank rules)
```

##### Delete a user's movie queue
```
DELETE /movie_queues/<user_id>
```

## Try it out on AWS
*note: user and movie ids are sequential.  There are 1000 users & 500 movies in total.  The service is pre-cached with 200 users from `User Services` and 200 movies from `Movie Services`*

To create a movie queue for an existing user (user id = 36) using `httpie`
```
http POST http://54.193.41.195:3000/movie_queues user_id=36 movie_ids=1,2,99
```
To access the newly created movie queue, sorted by year in descending order (optional).  Default sort method is by movie delivery order (aka rank)
```
http http://54.193.41.195:3000/movie_queues/36 sort_by==year order==1
```

To adjust the movie queue delivery order (rank).  The following example will add or move movie id 302 to the top of the queue (depends if the movie exists in the queue or not).  For the full set of re-ranking rules, see the bottom of this doc
```
http PUT http://54.193.41.195:3000/movie_queues/36  movie_id==302 new_rank==0 
```


## Installation instruction (single machine deployment)

### Prerequisites
- Ruby 2.4
- Rails 5
- Redis 4 

### Steps
1. Start redis-server with default settings.  Make sure database 0 to 4 are not used or they will be wiped out!!
2. download & install [UserServices](https://github.com/edithau/user_services) and start the server at localhost:3001
3. download & install [MovieServices](https://github.com/edithau/movie_services) and start the server at localhost:3002
4.  download & install [MovieQueueServices](https://github.com/edithau/movie_queue_services) and start the server at localhost:3000
5. Try the httpie examples above with your MovieQueueServices (localhost:3000)!

## Running the tests
In the root directory of the downloaded [MovieQueueServices](https://github.com/edithau/movie_queue_services), run
```
bin/rails test
```

### Movie Queue re-rank rules
To adjust movie delivery order in a queue, use the following API
```
http PUT <site>/movie_queues/<user_id>  movie_id==<movie_to_rerank> new_rank==<new_pos_in_queue>
```
The `new_rank` parameter set the new rank of the specified movie:
```
    new_rank < 0                    ----> remove movie from queue if present
    new_rank == 0                   ----> move movie to first in the queue
    new_rank > 0 && <= queue size   ----> move movie to new_rank position
    new_rank > queue size           ----> move movie to end of queue
```
