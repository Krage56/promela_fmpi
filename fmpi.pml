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


short flow_entry_cont = 0;
short flow_entry_switch = 0;

bool states_app[2], states_controller[5], states_channel1[3], states_channel2[2], states_switch[2]; 

inline print_state(){
    printf("f_cont = %h, f_switch = %h\n", flow_entry_cont, flow_entry_switch);
}

proctype App(chan out){
    do
    ::((states_app[0])) -> atomic {
        flow_entry_cont = 1;
        out!PostFlow_App;
        states_app[0] = false;
        states_app[1] = true;
        print_state();
    }
    ::((states_app[1]) && (flow_entry_cont == 1)) -> atomic {
        flow_entry_cont = 0;
        out!DeleteFlow_App;
        states_app[1] = false;
        states_app[0] = true;
    }
    ::((states_app[1]) && (flow_entry_cont <= 10)) -> atomic {
        flow_entry_cont = flow_entry_cont + 1;
        out!PostFlow_App;
    }
    ::((states_app[1]) && (flow_entry_cont > 1)) -> atomic {
        flow_entry_cont = flow_entry_cont - 1;
        out!DeleteFlow_App;
    }
    od
}

proctype Controller(chan in1, in2, out){
    do
    ::((states_controller[0])) -> atomic {
        in1?PostFlow_App;
        states_controller[0] = false;
        states_controller[1] = true;
    }
    ::((states_controller[0])) -> atomic {
        in1?DeleteFlow_App;
        states_controller[0] = false;
        states_controller[3] = true;
    }
    ::(states_controller[1]) -> atomic {
        out!PostFlow_Cont;
        states_controller[1] = false;
        states_controller[2] = true;
    }
    // T transition
    ::(states_controller[2]) -> atomic {
        states_controller[2] = false;
        states_controller[1] = true;
    }
    ::((states_controller[2])) -> atomic {
        in2?ACK_Channel2;
        states_controller[2] = false;
        states_controller[0] = true;
    }
    ::(states_controller[3]) -> atomic {
        out!DeleteFlow_Cont;
        states_controller[3] = false;
        states_controller[4] = true;
    }
    // T transition
    ::(states_controller[4]) -> atomic {
        states_controller[4] = false;
        states_controller[3] = true;
    }
    ::((states_controller[4])) -> atomic {
        in2?ACK_Channel2;
        states_controller[4] = false;
        states_controller[0] = true;
    }
    od
}

proctype Channel1(chan in, out){
    do
    ::((states_channel1[0])) -> atomic {
        in?PostFlow_Cont;
        states_channel1[0] = false;
        states_channel1[1] = true;
    }
    ::((states_channel1[0])) -> atomic {
        in?DeleteFlow_Cont;
        states_channel1[0] = false;
        states_channel1[2] = true;
    }
    ::(states_channel1[1]) -> atomic {
        // LOSS
        states_channel1[1] = false;
        states_channel1[0] = true;
    }
    ::(states_channel1[1]) -> atomic {
        out!PostFlow_Channel1;
        states_channel1[1] = false;
        states_channel1[0] = true;
    }
    ::(states_channel1[2]) -> atomic {
        // LOSS
        states_channel1[2] = false;
        states_channel1[0] = true;
    }
    ::(states_channel1[2]) -> atomic {
        out!DeleteFlow_Channel1;
        states_channel1[1] = false;
        states_channel1[0] = true;
    }
    od
}

proctype Channel2(chan in, out){   
    do
    ::((states_channel2[0])) -> atomic {
        in?ACK_Switch;
        states_channel2[0] = false;
        states_channel2[1] = true;
    }
    ::(states_channel2[1]) -> atomic {
        // LOSS
        states_channel2[1] = false;
        states_channel2[0] = true;
    }
    ::(states_channel2[1]) -> atomic {
        out!ACK_Channel2;
        states_channel2[1] = false;
        states_channel2[0] = true;
    }
    od
}

proctype Switch(chan in, out){
    do
    ::(states_switch[0]) -> atomic {
        in?PostFlow_Channel1;
        flow_entry_switch = flow_entry_switch + 1;
        states_switch[0] = false;
        states_switch[1] = true;
    }
    ::(states_switch[0]) -> atomic {
        in?DeleteFlow_Channel1;
        flow_entry_switch = flow_entry_switch - 1;
        states_switch[0] = false;
        states_switch[1] = true;
    }
    ::(states_switch[1]) -> atomic {
        out!ACK_Switch;
        states_switch[1] = false;
        states_switch[0] = true;
    }
    od
}


// proctype watchdog(){
//     do
//     ::timeout -> assert(false)
//     odPostFlow_App
// }

init {

    chan one = [N] of {mtype};
    chan two = [N] of {mtype};
    chan three = [N] of {mtype};
    chan four = [N] of {mtype};
    chan five = [N] of {mtype};
    
    /* Init process for all system states before corresponding processes will be started */
    byte i;
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
        run App(one);
        run Controller(one, five, two);
        run Channel1(two, three);
        run Channel2(four, five);
        run Switch(three, four);
    }
}
/* Anti deadlock rule */
ltl allRight {[]<>(1)}

/* Checking if control values are not negative */
ltl notNeg {[]((flow_entry_cont >= 0) && (flow_entry_switch >= 0))}