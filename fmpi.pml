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

active proctype App(){
    bool states[2];
    for (i: 0..(2 - 1)){
        states[i] = false;
    }
    states[0] = true;

}

active proctype Controller(){
    bool states[5];
    for (i: 0..(5 - 1)){
        states[i] = false;
    }
    states[0] = true;

}

active proctype Channel1(){
    bool states[3];
    for (i: 0..(3 - 1)){
        states[i] = false;
    }
    states[0] = true;

}

active proctype Channel2(){
    bool states[2];
    for (i: 0..(2 - 1)){
        states[i] = false;
    }
    states[0] = true;   
     
}

active proctype Switch(){
    bool states[2];
    for (i: 0..(2 - 1)){
        states[i] = false;
    }
    states[0] = true;
    
}