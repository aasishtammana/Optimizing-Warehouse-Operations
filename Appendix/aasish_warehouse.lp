% Defines the location of a node using its ID and X, Y coordinates
locationofnode(NODEID, pair(X, Y)) :-
    init(object(node, NODEID), value(at, pair(X, Y))).

% Defines a pair of coordinates X, Y
pair(X, Y) :-
    init(object(node, NODEID), value(at, pair(X, Y))).

% Defines a node with a given ID
node(NODEID) :-
    init(object(node, NODEID), value(at, pair(X, Y))).

% Defines the location of a pickup station by its ID and associated node ID
locationofpickupstation(PICKUPSTATIONID, NODEID) :-
    init(object(pickingStation, PICKUPSTATIONID), value(at, pair(X, Y))),
    init(object(node, NODEID), value(at, pair(X, Y))).

% Defines a pickup station with a given ID
pickingStation(PICKUPSTATIONID) :-
    init(object(pickingStation, PICKUPSTATIONID), value(at, pair(X, Y))),
    init(object(node, NODEID), value(at, pair(X, Y))).

locationofrobot(ROBOTID, object(node, NODECOUNT), 0) :-
    init(object(robot, ROBOTID), value(at, pair(X, Y))),
    locationofnode(NODECOUNT, pair(X, Y)).

shelfOn(SHELFID, object(node, NODECOUNT), 0) :-
    init(object(shelf, SHELFID), value(at, pair(X, Y))),
    locationofnode(NODECOUNT, pair(X, Y)).

orderAt(ORDERID, object(node, NODECOUNT), contains(PRODUCTID, PRODUCTQUANTITY), 0) :-
    init(object(order, ORDERID), value(pickingStation, STATIONKEY)),
    locationofpickupstation(STATIONKEY, NODECOUNT),
    init(object(order, ORDERID), value(line, pair(PRODUCTID, PRODUCTQUANTITY))).

numColumns(ROWCOUNT) :-
    ROWCOUNT = #count{X: init(object(node, I), value(at, pair(X, Y)))}.

numRows(COLUMNCOUNT) :-
    COLUMNCOUNT = #count{Y: init(object(node, I), value(at, pair(Y, X)))}.

numNodes(NODECOUNT) :-
    NODECOUNT = #count{I: init(object(node, I), value(at, pair(X, Y)))}.

{deliver(ROBOT, ORDERID, with(SHELFID, PR, DELIVERYQUANTITY), T) :
    orderAt(ORDERID, object(node, NODECOUNT), contains(PR, ORDERQUANTITY), T),
    productOn(PR, object(shelf, SHELFID), with(quantity, PRODUCTQUANTITY), T),
    DELIVERYQUANTITY = 1..PRODUCTQUANTITY}1 :-
    ROBOT = 1..ROWCOUNT,
    numRobots(ROWCOUNT),
    T = 0..TN,
    TN = n-1.

:- locationofrobot(ROBOTID, object(node, NODECOUNT), T), 
   robotMove(ROBOT, move(DELTAX, DELTAY), T), 
   locationofnode(NODECOUNT, pair(X, Y)), 
   X + DELTAX < 1.

:- locationofrobot(ROBOTID, object(node, NODECOUNT), T), 
   robotMove(ROBOT, move(DELTAX, DELTAY), T), 
   locationofnode(NODECOUNT, pair(X, Y)), 
   Y + DELTAY < 1.

:- locationofrobot(ROBOTID, object(node, NODECOUNT), T), 
   robotMove(ROBOT, move(DELTAX, DELTAY), T), 
   locationofnode(NODECOUNT, pair(X, Y)), 
   X + DELTAX > COLUMNCOUNT, 
   numColumns(COLUMNCOUNT).

:- locationofrobot(ROBOTID, object(node, NODECOUNT), T), 
   robotMove(ROBOT, move(DELTAX, DELTAY), T), 
   locationofnode(NODECOUNT, pair(X, Y)), 
   Y + DELTAY > ROWCOUNT, 
   numRows(ROWCOUNT).

:- pickUpShelf(ROBOTID, S, T), 
   shelfOn(S, object(node, NODECOUNT), T), 
   not locationofrobot(ROBOTID, object(node, NODECOUNT), T).

:- putDownShelf(ROBOTID, S, T), 
   locationofrobot(ROBOTID, object(node, NODECOUNT), T), 
   highway(NODECOUNT).

:- deliver(ROBOT, ORDERID, with(_, PR, _), T), 
   orderAt(ORDERID, object(node, NODECOUNT), contains(PR, _), T), 
   not locationofrobot(ROBOT, object(node, NODECOUNT), T).

:- deliver(ROBOT, ORDERID, with(SHELFID, PR, DELIVERYQUANTITY), T), 
   orderAt(ORDERID, object(node, NODECOUNT), contains(PR, ORDERQUANTITY), T), 
   DELIVERYQUANTITY > ORDERQUANTITY.

:- shelfOn(S, object(node, NODEID), _), 
   highway(NODEID).

:- 2{locationofrobot(ROBOT, object(node, NODECOUNT), T) : node(NODECOUNT)}, 
   robot(ROBOT), 
   T = 0..n.

:- 2{locationofrobot(ROBOT, object(node, NODECOUNT), T) : robot(ROBOT)}, 
   node(NODECOUNT), 
   T = 0..n.

:- locationofrobot(R1, object(node, ND1), T), 
   locationofrobot(R1, object(node, ND2), T + 1), 
   locationofrobot(R2, object(node, ND2), T), 
   locationofrobot(R2, object(node, ND1), T + 1), 
   R1 != R2.

:- 2{shelfOn(S, object(node, NODECOUNT), T) : node(NODECOUNT)}, 
   shelf(S), 
   T = 0..n.

:- 2{shelfOn(S, object(node, NODECOUNT), T) : shelf(S)}, 
   node(NODECOUNT), 
   T = 0..n.

:- shelfOn(S, object(node, _), T), 
   shelfOn(S, object(robot, _), T).

locationofrobot(ROBOT, object(node, NEW_ND), T + 1) :- 
   locationofrobot(ROBOT, object(node, NODECOUNT), T), 
   locationofnode(NODECOUNT, pair(X, Y)), 
   locationofnode(NEW_ND, pair(X + DELTAX, Y + DELTAY)), 
   robotMove(ROBOT, move(DELTAX, DELTAY), T).

shelfOn(S, object(robot, ROBOTID), T + 1) :- 
   pickUpShelf(ROBOTID, S, T), 
   shelfOn(S, object(node, NODECOUNT), T), 
   locationofrobot(ROBOTID, object(node, NODECOUNT), T).

shelfOn(S, object(node, NODECOUNT), T + 1) :- 
   putDownShelf(ROBOTID, S, T), 
   shelfOn(S, object(robot, ROBOTID), T), 
   locationofrobot(ROBOTID, object(node, NODECOUNT), T).

orderAt(ORDERID, object(node, NODECOUNT), contains(PR, OU - DELIVERYQUANTITY), T + 1) :- 
   deliver(ROBOT, ORDERID, with(SHELFID, PR, DELIVERYQUANTITY), T), 
   orderAt(ORDERID, object(node, NODECOUNT), contains(PR, OU), T).

locationofrobot(ROBOT, object(node, NODECOUNT), T + 1) :- 
   locationofrobot(ROBOT, object(node, NODECOUNT), T), 
   not robotMove(ROBOT, move(_, _), T), 
   T < n.

shelfOn(S, object(node, NODECOUNT), T + 1) :- 
   shelfOn(S, object(node, NODECOUNT), T), 
   not pickUpShelf(_, S, T), 
   T < n.

orderAt(ORDERID, object(node, NODECOUNT), contains(PR, OU), T + 1) :- 
   orderAt(ORDERID, object(node, NODECOUNT), contains(PR, OU), T), 
   productOn(PR, object(shelf, SHELFID), with(quantity, PRODUCTQUANTITY), T), 
   not deliver(_, ORDERID, with(SHELFID, PR, _), T), 
   T < n.

:- not orderAt(ORDERID, object(node, _), contains(PR, 0), n), 
   orderAt(ORDERID, object(node, _), contains(PR, _), 0).

highway(NODEID) :- 
   init(object(highway, NODEID), value(at, pair(X, Y))).

:- putDownShelf(ROBOTID, S, T), 
   locationofrobot(ROBOTID, object(node, NODECOUNT), T), 
   highway(NODECOUNT).

:- locationofpickupstation(_, NODEID), 
   highway(NODEID).

locationofpickupstation(PICKUPSTATIONID, NODEID) :- 
   init(object(pickingStation, PICKUPSTATIONID), value(at, pair(X, Y))), 
   init(object(node, NODEID), value(at, pair(X, Y))). 
   % Defines the location of a pickup station by its ID and associated node ID

pickingStation(PICKUPSTATIONID) :- 
   init(object(pickingStation, PICKUPSTATIONID), value(at, pair(X, Y))), 
   init(object(node, NODEID), value(at, pair(X, Y))). 
   % Defines a pickup station with a given ID

orderAt(ORDERID, object(node, NODECOUNT), contains(PRODUCTID, PRODUCTQUANTITY), 0) :- 
   init(object(order, ORDERID), value(pickingStation, STATIONKEY)), 
   locationofpickupstation(STATIONKEY, NODECOUNT), 
   init(object(order, ORDERID), value(line, pair(PRODUCTID, PRODUCTQUANTITY))). 

order(ORDERID) :- 
   init(object(order, ORDERID), value(pickingStation, STATIONKEY)). 

numPickingStation(NODECOUNT) :- 
   NODECOUNT = #count{I : init(object(pickingStation, I), value(at, pair(X, Y)))}. 

numOrders(NODECOUNT) :- 
   NODECOUNT = #count{I : init(object(order, I), value(pickingStation, J))}. 

:- locationofpickupstation(_, NODEID), 
   highway(NODEID).

robot(ROBOTID) :- 
   init(object(robot, ROBOTID), value(at, pair(X, Y))). 

shelf(SHELFID) :- 
   init(object(shelf, SHELFID), value(at, pair(X, Y))). 

productOn(PRODUCTID, object(shelf, SHELFID), with(quantity, PRODUCTQUANTITY), 0) :- 
   init(object(product, PRODUCTID), value(on, pair(SHELFID, PRODUCTQUANTITY))). 

product(PRODUCTID) :- 
   init(object(product, PRODUCTID), value(on, pair(SHELFID, PRODUCTQUANTITY))). 

numShelves(NODECOUNT) :- 
   NODECOUNT = #count{I : init(object(shelf, I), value(at, pair(X, Y)))}. 

numProducts(NODECOUNT) :- 
   NODECOUNT = #count{I : init(object(product, I), value(on, pair(X, Y)))}. 

numRobots(NODECOUNT) :- 
   NODECOUNT = #count{I : init(object(robot, I), value(at, pair(X, Y)))}. 

#const n = 50.

move(0, 1; 0, -1; -1, 0; 1, 0).   
                                  
% Robot movement
{robotMove(ROBOT, move(DELTAX, DELTAY), T) : move(DELTAX, DELTAY)} 1 :-
    ROBOT = 1..ROWCOUNT,
    numRobots(ROWCOUNT),
    T = 0..TN, TN = n - 1.

% Picking up a shelf
{pickUpShelf(ROBOT, SHELFID, T) : shelf(SHELFID)} 1 :-
    ROBOT = 1..ROWCOUNT,
    numRobots(ROWCOUNT),
    T = 0..TN, TN = n - 1.

% Putting down a shelf
{putDownShelf(ROBOT, SHELFID, T) : shelf(SHELFID)} 1 :-
    ROBOT = 1..ROWCOUNT,
    numRobots(ROWCOUNT),
    T = 0..TN, TN = n - 1.

% Defining occurrences
occurs(object(robot, ROBOT), move(DELTAX, DELTAY), T) :-
    robotMove(ROBOT, move(DELTAX, DELTAY), T).

occurs(object(robot, ROBOT), pickup, T) :-
    pickUpShelf(ROBOT, _, T).

occurs(object(robot, ROBOT), putdown, T) :-
    putDownShelf(ROBOT, _, T).

occurs(object(robot, ROBOT), deliver(ORDERID, PRODUCTID, DELIVERYQUANTITY), T) :-
    deliver(ROBOT, ORDERID, with(SHELFID, PRODUCTID, DELIVERYQUANTITY), T).

% Constraints
:- occurs(object(robot, ROBOT), A1, T), occurs(object(robot, ROBOT), A2, T), A1 != A2.

:- 2 {pickUpShelf(ROBOT, S, T) : robot(ROBOT)}, shelf(S).

:- pickUpShelf(ROBOTID, S1, T), shelfOn(S2, object(robot, ROBOTID), T).

:- pickUpShelf(R1, S, T), shelfOn(S, object(robot, R2), T).

:- 2 {putDownShelf(ROBOT, S, T) : robot(ROBOT)}, shelf(S).

:- putDownShelf(ROBOTID, S, T), not shelfOn(S, object(robot, ROBOTID), T).

:- deliver(ROBOT, ORDERID, with(SHELFID, PR, _), T), productOn(PR, object(shelf, SHELFID), with(quantity, _), T), not shelfOn(SHELFID, object(robot, ROBOT), T).

:- deliver(ROBOT, ORDERID, with(SHELFID, PR, DELIVERYQUANTITY), T), productOn(PR, object(shelf, SHELFID), with(quantity, PRODUCTQUANTITY), T), DELIVERYQUANTITY > PRODUCTQUANTITY.

:- 2 {shelfOn(S, object(robot, ROWCOUNT), T) : robot(ROWCOUNT)}, shelf(S), T = 0..n.

:- 2 {shelfOn(S, object(robot, ROWCOUNT), T) : shelf(S)}, robot(ROWCOUNT), T = 0..n.

% Updating product and shelf status
productOn(PR, object(shelf, SHELFID), with(quantity, PRODUCTQUANTITY - DELIVERYQUANTITY), T + 1) :-
    deliver(ROBOT, ORDERID, with(SHELFID, PR, DELIVERYQUANTITY), T),
    productOn(PR, object(shelf, SHELFID), with(quantity, PRODUCTQUANTITY), T).

shelfOn(S, object(robot, ROBOTID), T + 1) :-
    shelfOn(S, object(robot, ROBOTID), T), 
    not putDownShelf(ROBOTID, S, T), 
    T < n.

productOn(PR, object(shelf, SHELFID), with(quantity, PRODUCTQUANTITY), T + 1) :-
    productOn(PR, object(shelf, SHELFID), with(quantity, PRODUCTQUANTITY), T),
    not deliver(_, _, with(SHELFID, PR, _), T),
    T < n.

% Additional predicates
numActions(N) :- N = #sum {1, O, A, T : occurs(O, A, T)}.

timeTaken(N - 1) :- N = #count {T : occurs(O, A, T)}.

% Optimization statements
#minimize {1, O, A, T : occurs(O, A, T)}.
#minimize {T : occurs(O, A, T)}.

% Show statements
#show occurs/3.
#show numActions/1.
#show timeTaken/1.