/**************** 
This is the model of an elevator that does the following:
1. go to the called floor
2. open/close doors (?)
3. go to the destination floor
****************/

/*****************
*   Variables    *
*****************/
#define NUM_FLOORS 5

mtype = {MOVING, ARRIVED};

mtype elevator_state = ARRIVED;
int current_floor = 0;
int target_floor = 0;
int passenger_floor = 0;

/*****************
*   Channels     *
*****************/
chan elevator_control = [0] of {int, int}; // channel for passenger to tell the elevator which floor to go to
chan elevator_status = [0] of {mtype, int}; // channel that shows status of elevator : STATUS at FLOOR

/*****************
*   Proctypes    *
*****************/
proctype Passenger (int start_floor, int destination_floor) {
    passenger_floor = start_floor;
    printf("Passenger at floor %d calls the elevator to go to floor %d \n", start_floor, destination_floor);
    elevator_control!start_floor, destination_floor; // signal the elevator
};

active proctype Elevator() {
    do
        :: elevator_status?MOVING, target_floor ->
            printf("Elevator is moving from floor %d to %d \n", current_floor, target_floor);
            current_floor = target_floor;
            elevator_state = ARRIVED;
            elevator_status!ARRIVED, current_floor; // notify that the elevator has arrived
        :: elevator_status?ARRIVED,_ ->
            printf("Elevator has arrived at floor %d \n", current_floor);
        :: elevator_control?passenger_floor, current_floor ->
            printf("Elevator received a call from floor %d \n", passenger_floor);
            elevator_state = MOVING;
            target_floor = passenger_floor;
            elevator_status!MOVING, target_floor; // signal the elevator to move
    od;
}

init {
    run Passenger(0, 4);
}

