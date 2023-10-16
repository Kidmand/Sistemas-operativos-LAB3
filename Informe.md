# Informe Lab 3

## Integrantes:
 - Ramiro Lugo Viola
 - Matias Viola Di Benedetto
 - Daián García Giménez 

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
6. ✅ ❓ ¿Cúales son los estados en los que un proceso pueden permanecer en xv6-riscv y que los hace cambiar de estado?

❓ Preguntar si siempre las interupciones de tiempo se hacer siempre cada un quantum, sin impprtar nada, es decir cada 1 segundo por ejemplo hace una interrupcion.

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
4. ❓ (¿Si esta contenido al principio de la ejecución?) <br/>
   En otro caso es absurdo pensar esto. Supongamos un proceso cpu-bound (consume el quantum siempre), por lo tanto tenemos un cambio de contexto una vez que el proceso haya consumido todo el quantum, si el cambio de contexto estuviera contenido en el quantum cómo lo haces.
5. ❓
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
   - `lastexect`: ❓ Utilizamos una idea similar a la que se una en iobench y cpubench en la funcio time. <br> 
                   Sino la otra opcion en setea despues de la ejecucion la cantidad de ticks.
                    
<br>
❓Puede ser el indice de la tabla de procesos sea su prioridad?

#### 1) Quantum normal: (`make CPUS=1 qemu`)
- ✅ Caso 1: (un solo iobench)
  ```sh
  $ iobench
  ```
  El proceso iobench esta ejecutando practicamente solo en el SO, por lo tanto puede hacer muchas operaciones de R/W. Ademas tiene sentido que cantselect sea grande porque nunca supera el quantum y  se produce una interrupcion cada vez que hay un R/W. Ademas se ve una clara diferencia en la cantidad de operaciones respecto al caso dos.
- ✅ Caso 2 (un solo cpubench):
  ```sh
  $ cpubench
  ```
  El proceso cpubench esta ejecutando practicamente solo en el SO, y al ser cpu-bound siempre consume el quantum. Por esta razon es que cantselect es similar a lastexect. Ademas se ve una clara diferencia en la cantidad de operaciones respecto al caso uno.
- ✅❌ ❓ Caso 3 (un iobench y un cpubench):
  ```sh
  $ iobench & ; cpubench & 
  ```
  Encontramos en cpubench que se esta guradando en memoria las operaciones de la matriz y esto consume I/O, dejandole menos I/O al iobench, por esta razon se reducen las R/W.
- ✅ Caso 4 (dos cpubench):
  ```sh
  $ cpubench & ; cpubench & 
  ```
  Al tener dos procesos cpubench tiene sentido que se consume constantemente el quantum, por esta razon se da que lastexect sea el doble que cantselect, justamenete tenemos dos procesos cpu-bound. Nuevamente se ve una gran cantidad de operaciones.
- ❌ ❓ Caso 5 (dos cpubench y un iobench):  
  ```sh
  $ cpubench & ; cpubench & ; iobench &
  ```
  Completar ...

#### 2) Quantum 10 veces más corto: 
❓ COMO CALCULAR EL `lastexect`.
Aclaración, para hacer este test se modificio la varaible `interval` en `kernel/start.c:69`
- Caso 1: (un solo iobench)
  ```sh
  $ iobench
  ```
Aumento el lastexect respecto a la prueba anteriro del caso uno por un factor de 10, pero es analgo porque lastexect cuenta la cantida de ticks y estos depende del quantum.
- Caso 2 (un solo cpubench):
  ```sh
  $ cpubench
  ```
Aumento en un factor de 10 el cantselect respecto a la prueba anteriro del caso dos y tiene senido porque se consume el quantum 10 veces mas rapido.
- Caso 3 (un iobench y un cpubench):
  ```sh
  $ iobench & ; cpubench & 
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
