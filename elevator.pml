/**************** 
This is the model of an elevator that does the following:
1. go to the called floor
2. TODO open/close doors (?)
3. go to the destination floor
****************/

/*****************
*   Variables    *
*****************/
//#define NUM_FLOORS 5
#define EQ1 (elevator_current_floor == passenger_current_floor)
#define EQ2 (elevator_current_floor == passenger_target_floor)

// Possible states of elevator
mtype = {MOVING, ARRIVED};

// Initial state of elevator
mtype elevator_state = ARRIVED;
int elevator_current_floor = 0;
int elevator_target_floor = 0;
int passenger_current_floor = 0;
int passenger_target_floor = 0;

/*****************
*   Channels     *
*****************/

// channel for passenger to tell the elevator which floor the passenger wants to
// - to go to. from A to B
chan elevator_control = [4] of {int, int};
// channel that shows status of elevator : STATUS at FLOOR
chan elevator_status = [1] of {mtype};

/*****************
*   Proctypes    *
*****************/

// Passenger is at floor [start_floor] and wants to go to floor [destination_floor]
proctype Passenger (int start_floor; int destination_floor) {
    passenger_current_floor = start_floor;
    passenger_target_floor = destination_floor;

    printf("Passenger at floor %d called the elevator to go to floor %d \n", start_floor, destination_floor);

    elevator_control!passenger_current_floor, passenger_target_floor; // signal the elevator
};

active proctype Elevator() {
    do
        :: elevator_status?MOVING ->
            if
                :: (EQ1) ->
                    printf("Elevator is already at passenger floor %d \n", passenger_current_floor);
                    printf("Elevator is moving to passenger target floor %d \n", passenger_target_floor)
                :: (!EQ1) ->
                    printf("Elevator is moving from floor %d to %d \n", elevator_current_floor, elevator_target_floor);
            fi
            // Move the elevator
            elevator_current_floor = elevator_target_floor;
            elevator_state = ARRIVED;
            elevator_status!ARRIVED; // notify that the elevator has arrived
        :: elevator_status?ARRIVED ->
            printf("Elevator has arrived at floor %d \n", elevator_current_floor);
            if
                // We have succesfully transported the passenger
                :: (EQ2) ->
                    passenger_current_floor = passenger_target_floor
                // We have arrived at passenger's floor to board them
                // and take them to their target floor
                :: (!EQ2) ->
                    elevator_control!elevator_current_floor,passenger_target_floor
            fi
        :: elevator_control?_, _ ->
            printf("Elevator at floor %d received a call from passenger at floor %d \n", elevator_current_floor, passenger_current_floor);
            if
                // elevator is already at passenger's floor
                :: (EQ1) ->
                    elevator_target_floor = passenger_target_floor
                :: (EQ2) ->
                    elevator_target_floor = passenger_current_floor
            fi
            elevator_state = MOVING;
            elevator_status!MOVING; // signal the elevator to move
    od;
}

/*****************
*      LTL       *
*****************/

/*****************
G((elevator_status == MOVING) -> F(elevator_status == ARRIVED && elevator_current_floor == elevator_target_floor))
G(elevator is called(Passenger proctype) -> N(elevator_status == MOVING))
G(elevator_current_floor == destination_floor -> (elevator_status == ARRIVED))
G(!(elevator_status == MOVING) && (elevator_status == ARRIVED) || !(elevator_status == ARRIVED) && (elevator_status == MOVING))
*****************/

ltl p1 { [](
            // Always if elevator is moving then Finally elevator will arrive at some floor
            // - and the current of elevator floor will be the target floor
            ((elevator_status == MOVING) -> <>(elevator_status == ARRIVED && elevator_current_floor == elevator_target_floor))
            && ((elevator_current_floor == elevator_target_floor) -> ( elevator_status == ARRIVED ))
            // FIXME how to say "if proctype Passenger is active"?
            // Always if the elevator is called (by Passenger) then elevator will immediately start to move
            //&& (active(Passenger) -> X(elevator_status == MOVING))
            // NOTE: A XOR B === !AB || !BA
            // Elevator can be either MOVING or ARRIVED
            && ((!(elevator_status == MOVING) && elevator_status == ARRIVED) || (elevator_status == ARRIVED && elevator_status == MOVING))
    )
}

init {
    // TODO: loop over 0..FLOOR and run Passenger with all possible floor combinations
        run Passenger(0, 4);
        //run Passenger(2,3);
}

