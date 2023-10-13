# Informe Lab 3

## Integrantes:
 - Ramiro Lugo Viola
 - Matias Viola Di Benedetto
 -

---
Despues borrar esto:
 - ✅ Significa que esta bien.
 - ✅❌ Significa que podria esta bien pero no sabemos.
 - ❌ No esta hecho o probablemente mal.
 - ❓ Preguntar a los profes.
---

## Primera Parte: 
Estudiando el planificador de xv6-riscv y respondiendo preguntas.

#### Preguntas
1. ✅ ¿Qué política de planificación utiliza xv6-riscv para elegir el próximo proceso a ejecutarse?
2. ✅ ¿Cuánto dura un quantum en xv6-riscv?
3. ✅ ❓ ¿Cuánto dura un cambio de contexto en xv6-riscv?
4. ❌ ❓ ¿El cambio de contexto consume tiempo de un quantum?
5. ❌ ❓ ¿Hay alguna forma de que a un proceso se le asigne menos tiempo? Pista: Se puede empezar a buscar desde la system call uptime.
6. ✅❌ ❓ ¿Cúales son los estados en los que un proceso pueden permanecer en xv6-riscv y que los hace cambiar de estado?

#### Respuestas
1. La politica de planificación que utliza xv6-riscv Round Robin. <br/>
   Nos dimos cuenta, por la funcion `void scheduler(void)` implementada en `kernel/proc.c` y la presencia del timer (quantum).
2. Un quantum en xv6-riscv dura 1/10 de segundo. <br/>
   Nos dimos cuenta por la funcion `void timerinit()` implementada en `kernel/start.c`.
3. Pareciera ser que el tiempo del cambio de contexto esta acotado por la cantida de procesos maximos que soporta el SO. Vemos esto en la función `void scheduler(void)` implementada en `kernel/proc.c` y podemos extraer esta sección de la función: <br/> 
    ``` c 
    for(p = proc; p < &proc[NPROC]; p++) {
        acquire(&p->lock);
        if(p->state == RUNNABLE) {
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
            c->proc = 0;
        }
        release(&p->lock);
    }
    ```
    Podemos contar la cantida de intrucciones que se van ejecutar despues de volver del `swtch`, esto conlleva la asignacion `c->proc = 0;` y todas las iteraciones del bucle hasta encontrar un proceso en estado `RUNNABLE`.
4. Es absurdo pensar esto. <br/> ???? (¿Si esta contenido al principio de la ejecución?)
   Supongamos un proceso cpu-bound (consume el quantum siempre), por lo tanto tenemos un cambio de contexto una vez que el proceso haya consumido todo el quantum, si el cambio de contexto estuviera contenido en el quantum cómo lo haces.
5. ??????????????????
   Suponindo que se habla del tiempo de quantum, si se puede porque cuando se hace una llamada a una syscall se produce una intrrupción `yield()` y cambia de contexto.
6. Encontramos en `kernel/proc.h` lo siguiente: <br/>
   ```c
   enum procstate { UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };
   ```
   Por lo tanto tenemos 6 estados posibles y estos cambian en: 
   - UNUSED: En `procinit` setea todos en UNUSED.
   - USED: En `allocproc` se cambia de UNUSED a USED.
   - SLEEPING: En `sleep` setea el proceso en SLEEPING.
   - RUNNABLE: 
     - En `userinit` se setea el proceso en RUNNABLE.
     - En `fork` se setea el nuevo proceso en RUNNABLE.
     - En `yield` se setea el proceso en RUNNABLE.
     - En `wakeup` se setea el proceso de SLEEPING a RUNNABLE.
     - En `kill` se setea el proceso si esta SLEEPING a RUNNABLE.
   - RUNNING: El unico lugar donde se setea es en el `sheduler` que cambia de RUNNABLE a RUNNING.
   - ZOMBIE: En `exit` se setea el proceso en ZOMBIE.

## Segunda Parte: 
Contabilizar las veces que es elegido un proceso por el planificador y anlaizar cómo el planificador afecta a los procesos.

¿Como lo hicimos?
Agreamos dos campos al `struc proc` esto son:
   - `cantselect`: Cuenta cada vez que entra el proceso en el sheduler y se inizializa en 0 en `userinit` y se libera en  `freeproc`. (¿ procinit ?) 
   - `lastexect` : Setea despues de la ejecucion la cantidad de ticks.

#### 1) Quantum normal: (`make CPUS=1 qemu`)
- ✅ Caso 1: (un solo iobench)
  ```sh
  $ iobench
                                        3: 6272 OPW100T
                                        3: 6272 OPR100T
                                        3: 6083 OPW100T
                                        3: 6083 OPR100T
                                        3: 6209 OPW100T
                                        3: 6209 OPR100T
                                        3: 6208 OPW100T
                                        3: 6208 OPR100T
                                        3: 6272 OPW100T
                                        3: 6272 OPR100T
                                        3: 6272 OPW100T
                                        3: 6272 OPR100T
                                        3: 6272 OPW100T
                                        3: 6272 OPR100T
                                        3: 6208 OPW100T
                                        3: 6208 OPR100T
                                        3: 6080 OPW100T
                                        3: 6080 OPR100T
                                        3: 6144 OPW100T
                                        3: 6144 OPR100T
                                        3: 6208 OPW100T
                                        3: 6208 OPR100T
                                        3: 6208 OPW100T
                                        3: 6208 OPR100T
                                        3: 6016 OPW100T
                                        3: 6016 OPR100T
                                        3: 6208 OPW100T
                                        3: 6208 OPR100T
                                        3: 6208 OPW100T
                                        3: 6208 OPR100T
                                        3: 6272 OPW100T
                                        3: 6272 OPR100T
                                        3: 6208 OPW100T
                                        3: 6208 OPR100T
                                        3: 6144 OPW100T
                                        3: 6144 OPR100T
                                        3: 6144 OPW100T
                                        3: 6144 OPR100T
  pid: 3, cantselect: 387776, lastexect: 2111
  ```
  El proceso iobench esta ejecutando practicamente solo en el SO, por lo tanto puede hacer muchas operaciones de R/W. Ademas tiene sentido que cantselect sea grande porque nunca supera el quantum y  se produce una interrupcion cada vez que hay un R/W.
- ✅ Caso 2 (un solo cpubench):
  ```sh
  $ cpubench
  3: 890 MFLOP100T
  3: 867 MFLOP100T
  3: 883 MFLOP100T
  3: 890 MFLOP100T
  3: 898 MFLOP100T
  3: 898 MFLOP100T
  3: 906 MFLOP100T
  3: 915 MFLOP100T
  3: 906 MFLOP100T
  3: 906 MFLOP100T
  3: 906 MFLOP100T
  3: 915 MFLOP100T
  3: 906 MFLOP100T
  3: 906 MFLOP100T
  3: 915 MFLOP100T
  3: 906 MFLOP100T
  3: 915 MFLOP100T
  pid: 3, cantselect: 2112, lastexect: 2118
  ```
  El proceso cpubench esta ejecutando practicamente solo en el SO, y al ser cpu-bound siempre consume el quantum. Por esta razon es que cantselect es similar a lastexect.
- ✅❌ ❓ Caso 3 (un iobench y un cpubench):
  ```sh
  $ iobench & ; cpubench & 
    6: 875 MFLOP100T
    6: 890 MFLOP100T
    6: 883 MFLOP100T
                                            5: 64 OPW100T
                                            5: 64 OPR100T
    6: 890 MFLOP100T
    6: 898 MFLOP100T
                                            5: 33 OPW100T
                                            5: 33 OPR100T
    6: 875 MFLOP100T
                                            5: 33 OPW100T
                                            5: 33 OPR100T
    6: 875 MFLOP100T
    6: 883 MFLOP100T
                                            5: 33 OPW100T
                                            5: 33 OPR100T
    6: 883 MFLOP100T
    6: 890 MFLOP100T
                                            5: 33 OPW100T
                                            5: 33 OPR100T
    6: 860 MFLOP100T
                                            5: 33 OPW100T
                                            5: 33 OPR100T
    6: 875 MFLOP100T
    6: 890 MFLOP100T
                                            5: 33 OPW100T
                                            5: 33 OPR100T
    6: 883 MFLOP100T
    6: 883 MFLOP100T
                                            5: 33 OPW100T
                                            5: 33 OPR100T
    6: 883 MFLOP100T
                                            5: 33 OPW100T
                                            5: 33 OPR100T
    6: 875 MFLOP100T
    pid: 6, cantselect: 2112, lastexect: 2120
    
                                            5: 33 OPW100T
                                            5: 33 OPR100T
    pid: 5, cantselect: 2216, lastexect: 2120
  ```
  Encontramos en cpubench que se esta guradando en memoria las operaciones de la matriz y esto consume I/O, dejandole menos I/O al iobench, por esta razon se reducen las R/W.
- ✅ Caso 4 (dos cpubench):
  ```sh
  $ cpubench & ; cpubench & 
   5: 580 MFLOP100T
   6: 586 MFLOP100T
   5: 1098 MFLOP100T
   6: 1088 MFLOP100T
   5: 1108 MFLOP100T
   6: 1118 MFLOP100T
   5: 1108 MFLOP100T
   6: 1108 MFLOP100T
   5: 1108 MFLOP100T
   6: 1098 MFLOP100T
   5: 1098 MFLOP100T
   6: 1098 MFLOP100T
   5: 1108 MFLOP100T
   6: 1108 MFLOP100T
   5: 1108 MFLOP100T
   6: 1108 MFLOP100T
   5: 1118 MFLOP100T
   6: 1118 MFLOP100T
   5: 1088 MFLOP100T
   6: 1098 MFLOP100T
   5: 1108 MFLOP100T
   6: 1108 MFLOP100T
   6: 1108 MFLOP100T
   5: 1098 MFLOP100T
   5: 1128 MFLOP100T
   6: 1108 MFLOP100T
   5: 1098 MFLOP100T
   6: 1098 MFLOP100T
   5: 1098 MFLOP100T
   6: 1108 MFLOP100T
   5: 1118 MFLOP100T
   6: 1108 MFLOP100T
   5: 1108 MFLOP100T
   6: 1108 MFLOP100T
   5: 1059 MFLOP100T
   6: 1059 MFLOP100T
   pid: 5, cantselect: 1057, lastexect: 2112
   
   pid: 6, cantselect: 1054, lastexect: 2114
  ```
  Al tener dos procesos cpubench tiene sentido que se consume constantemente el quantum, por esta razon se da que lastexect sea el doble que cantselect, justamenete tenemos dos procesos cpu-bound.
- ❌ ❓ Caso 5 (dos cpubench y un iobench):  
  ```sh
  $ cpubench & ; cpubench & ; iobench &
    5: 444 MFLOP100T
    7: 437 MFLOP100T
    5: 440 MFLOP100T
    7: 428 MFLOP100T
    5: 434 MFLOP100T
    7: 434 MFLOP100T
    5: 1032 MFLOP100T
    7: 1023 MFLOP100T
    5: 1059 MFLOP100T
    7: 1041 MFLOP100T
    5: 1078 MFLOP100T
    7: 1032 MFLOP100T
                                            8: 29 OPW100T
                                            8: 29 OPR100T
    5: 1088 MFLOP100T
    7: 1041 MFLOP100T
    5: 1078 MFLOP100T
    7: 1041 MFLOP100T
    5: 1068 MFLOP100T
    7: 1032 MFLOP100T
    5: 1088 MFLOP100T
                                            8: 16 OPW100T
                                            8: 16 OPR100T
    7: 1041 MFLOP100T
    5: 1078 MFLOP100T
    7: 1041 MFLOP100T
    5: 1050 MFLOP100T
    7: 1015 MFLOP100T
    5: 1041 MFLOP100T
                                            8: 16 OPW100T
                                            8: 16 OPR100T
    7: 1023 MFLOP100T
    5: 1041 MFLOP100T
    7: 996 MFLOP100T
    5: 1032 MFLOP100T
    7: 1015 MFLOP100T
    5: 1078 MFLOP100T
    7: 1023 MFLOP100T
                                            8: 16 OPW100T
                                            8: 16 OPR100T
    pid: 5, cantselect: 1057, lastexect: 2117
    
    pid: 7, cantselect: 1053, lastexect: 2118
    
                                            8: 16 OPW100T
                                            8: 16 OPR100T
    pid: 8, cantselect: 1236, lastexect: 2119
  ```

#### 2) Quantum 10 veces más corto: 
❓ COMO CALCULAR EL `lastexect`.
Aclaración, para hacer este test se modificio la varaible `interval` en `kernel/start.c:69`
- Caso 1: (un solo iobench)
  ```sh
  $ iobench
                                          3: 6656 OPW100T
                                        3: 6656 OPR100T
                                        3: 6528 OPW100T
                                        3: 6528 OPR100T
                                        3: 6528 OPW100T
                                        3: 6528 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6656 OPW100T
                                        3: 6656 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6528 OPW100T
                                        3: 6528 OPR100T
                                        3: 6528 OPW100T
                                        3: 6528 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6592 OPW100T
                                        3: 6592 OPR100T
                                        3: 6336 OPW100T
                                        3: 6336 OPR100T
                                        3: 5824 OPW100T
                                        3: 5824 OPR100T
                                        3: 6080 OPW100T
                                        3: 6080 OPR100T
    pid: 3, cantselect: 417099, lastexect: 21137
  ```
Aumento el lastexect respecto a la prueba anteriro del caso uno por un factor de 10, pero es analgo porque lastexect cuenta la cantida de ticks y estos depende del quantum.
- Caso 2 (un solo cpubench):
  ```sh
  $ cpubench
  3: 875 MFLOP100T
  3: 860 MFLOP100T
  3: 860 MFLOP100T
  3: 838 MFLOP100T
  3: 831 MFLOP100T
  3: 845 MFLOP100T
  3: 867 MFLOP100T
  3: 867 MFLOP100T
  3: 838 MFLOP100T
  3: 860 MFLOP100T
  3: 845 MFLOP100T
  3: 860 MFLOP100T
  3: 860 MFLOP100T
  3: 845 MFLOP100T
  3: 838 MFLOP100T
  3: 838 MFLOP100T
  pid: 3, cantselect: 21103, lastexect: 21225
  ```
Aumento en un factor de 10 el cantselect respecto a la prueba anteriro del caso dos y tiene senido porque se consume el quantum 10 veces mas rapido.
- Caso 3 (un iobench y un cpubench):
  ```sh
  $ iobench & ; cpubench & 
    6: 818 MFLOP100T
                                            5: 386 OPW100T
                                            5: 386 OPR100T
    6: 838 MFLOP100T
                                            5: 336 OPW100T
                                            5: 336 OPR100T
    6: 831 MFLOP100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
    6: 831 MFLOP100T
                                            5: 336 OPW100T
                                            5: 336 OPR100T
    6: 825 MFLOP100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
    6: 838 MFLOP100T
                                            5: 336 OPW100T
                                            5: 336 OPR100T
    6: 831 MFLOP100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
    6: 838 MFLOP100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
    6: 831 MFLOP100T
                                            5: 336 OPW100T
                                            5: 336 OPR100T
    6: 831 MFLOP100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
    6: 831 MFLOP100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
    6: 838 MFLOP100T
                                            5: 336 OPW100T
                                            5: 336 OPR100T
    6: 838 MFLOP100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
    6: 798 MFLOP100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
    6: 789 MFLOP100T
                                            5: 336 OPW100T
                                            5: 336 OPR100T
    6: 818 MFLOP100T
                                            5: 333 OPW100T
                                            5: 333 OPR100T
    pid: 5, cantselect: 21035, lastexect: 21193
    
    pid: 6, cantselect: 21154, lastexect: 21311
  ```
Completar ...
- Caso 4 (dos cpubench):
  ```sh
  $ cpubench & ; cpubench & 
  ```
Completar ...
- Caso 5 (dos cpubench y un iobench):  
  ```sh
  $ cpubench & ; cpubench & ; iobench &
  ```
