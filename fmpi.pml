#define N 10

mtype = {
    PostFlow_App, 
    DeleteFlow_App, 
    PostFlow_Cont, 
    DeleteFlow_Cont,
    TIME_TRANSITION, 
    PostFlow_Channel1, 
    DeleteFlow_Channel1,
    LOSS_Channel1, 
    ACK_Channel2, 
    LOSS_Channel2, 
    ACK_Switch 
}

chan one = [N * 2] of {mtype}
chan two = [N * 2] of {mtype}
chan three = [N * 2] of {mtype}
chan four = [N * 2] of {mtype}
chan five = [N * 2] of {mtype}

short flow_entry_cont = 0;
short flow_entry_switch = 0;

bool states_app[2], states_controller[5], states_channel1[3], states_channel2[2], states_switch[2]; 

inline print_state(){
    printf("f_cont = %h, f_switch = %h\n", flow_entry_cont, flow_entry_switch);
}

proctype App(){
    do
    ::((states_app[0])) -> atomic {
        flow_entry_cont = 1;
        one!PostFlow_App;
        states_app[0] = false;
        states_app[1] = true;
        print_state();
    }
    ::((states_app[1]) && (flow_entry_cont == 1)) -> atomic {
        flow_entry_cont = 0;
        one!DeleteFlow_App;
        states_app[1] = false;
        states_app[0] = true;
    }
    ::((states_app[1]) && (flow_entry_cont <= 10)) -> atomic {
        flow_entry_cont = flow_entry_cont + 1;
        one!PostFlow_App;
    }
    ::((states_app[1]) && (flow_entry_cont > 1)) -> atomic {
        flow_entry_cont = flow_entry_cont - 1;
        one!DeleteFlow_App;
    }
    od
}

proctype Controller(){
    do
    ::(states_controller[0] && one?PostFlow_App) -> atomic {
        states_controller[0] = false;
        states_controller[1] = true;
    }
    ::(states_controller[0] && one?DataFlow_App) -> atomic {
        states_controller[0] = false;
        states_controller[3] = true;
    }
    ::(states_controller[1]) -> atomic {
        two!PostFlow_Cont;
        states_controller[1] = false;
        states_controller[2] = true;
    }
    // T transition
    ::(states_controller[2]) -> atomic {
        states_controller[2] = false;
        states_controller[1] = true;
    }
    ::(states_controller[2] && five?<ACK_Channel2>) -> atomic {
        five?ACK_Channel2;
        states_controller[2] = false;
        states_controller[0] = true;
    }
    ::(states_controller[3]) -> atomic {
        two!DataFlow_Cont;
        states_controller[3] = false;
        states_controller[4] = true;
    }
    // T transition
    ::(states_controller[4]) -> atomic {
        states_controller[4] = false;
        states_controller[3] = true;
    }
    ::(states_controller[4] && five?<ACK_Channel2>) -> atomic {
        five?ACK_Channel2;
        states_controller[4] = false;
        states_controller[0] = true;
    }
    od
}

proctype Channel1(){
    do
    ::((states_channel1[0]) && (two?PostFlow_Cont)) -> atomic {
        states_channel1[0] = false;
        states_channel1[1] = true;
    }
    ::((states_channel1[0]) && (two?DataFlow_Cont)) -> atomic {
        states_channel1[0] = false;
        states_channel1[2] = true;
    }
    ::(states_channel1[1]) -> atomic {
        // LOSS
        states_channel1[1] = false;
        states_channel1[0] = true;
    }
    ::(states_channel1[1]) -> atomic {
        three!PostFlow_Channel1;
        states_channel1[1] = false;
        states_channel1[0] = true;
    }
    ::(states_channel1[2]) -> atomic {
        // LOSS
        states_channel1[2] = false;
        states_channel1[0] = true;
    }
    ::(states_channel1[2]) -> atomic {
        three!DataFlow_Channel1;
        states_channel1[1] = false;
        states_channel1[0] = true;
    }
    od
}

proctype Channel2(){   
    do
    ::((states_channel2[0]) && (four?ACK_Switch)) -> atomic {
        states_channel2[0] = false;
        states_channel2[1] = true;
    }
    ::(states_channel2[1]) -> atomic {
        // LOSS
        states_channel2[1] = false;
        states_channel2[0] = true;
    }
    ::(states_channel2[1]) -> atomic {
        five!ACK_Channel2;
        states_channel2[1] = false;
        states_channel2[0] = true;
    }
    od
}

proctype Switch(){
    do
    ::(states_switch[0] && three?PostFlow_Channel1) -> atomic {
        flow_entry_switch = flow_entry_switch + 1;
        states_switch[0] = false;
        states_switch[1] = true;
    }
    ::(states_switch[0] && three?DataFlow_Channel1) -> atomic {
        flow_entry_switch = flow_entry_switch - 1;
        states_switch[0] = false;
        states_switch[1] = true;
    }
    ::(states_switch[1]) -> atomic {
        four!ACK_Switch;
        states_switch[1] = false;
        states_switch[0] = true;
    }
    od
}


// proctype watchdog(){
//     do
//     ::timeout -> assert(false)
//     od
// }

init {
    /* Init process for all system states before corresponding processes will be started */
    for (i: 0..(2 - 1)){
        states_app[i] = false;
    }
    states_app[0] = true;

    for (i: 0..(5 - 1)){
        states_controller[i] = false;
    }
    states_controller[0] = true;

    for (i: 0..(3 - 1)){
        states_channel1[i] = false;
    }
    states_channel1[0] = true;

    for (i: 0..(2 - 1)){
        states_channel2[i] = false;
    }
    states_channel2[0] = true;

    for (i: 0..(2 - 1)){
        states_switch[i] = false;
    }
    states_switch[0] = true;

    atomic {
        run App();
        run Controller();
        run Channel1();
        run Channel2();
        run Switch();
    }
}
/* Anti deadlock rule */
ltl allRight {[]<>(1)}

/* Checking if control values are not negative */
ltl notNeg {[]((flow_entry_cont >= 0) && (flow_entry_switch >= 0))}