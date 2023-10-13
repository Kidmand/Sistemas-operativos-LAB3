# Informe Lab 3

## Integrantes:
 - Ramiro Lugo Viola
 - Matias Viola Di Benedetto
 -
 -

## Primera Parte: 
Estudiando el planificador de xv6-riscv y respondiendo preguntas.

#### Preguntas
1. ✅ ¿Qué política de planificación utiliza xv6-riscv para elegir el próximo proceso a ejecutarse? Pista: xv6-riscv nunca sale de la función scheduler por medios “normales”.
2. ✅ ¿Cuánto dura un quantum en xv6-riscv?
3. ✅ ¿Cuánto dura un cambio de contexto en xv6-riscv?
4. ❌ ¿El cambio de contexto consume tiempo de un quantum?
5. ❌ ¿Hay alguna forma de que a un proceso se le asigne menos tiempo? Pista: Se puede empezar a buscar desde la system call uptime.
6. ❌ ¿Cúales son los estados en los que un proceso pueden permanecer en xv6-riscv y que los hace cambiar de estado?

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
   - UNUSED: ???
   - USED:   ???
   - SLEEPING: ???
   - RUNNABLE: El sheduler cambia de RUNNABLE a RUNNING.
   - RUNNING: ???
   - ZOMBIE:  ???

## Segunda Parte: 
Contabilizar las veces que es elegido un proceso por el planificador y anlaizar cómo el planificador afecta a los procesos.

#### 1) Quantum normal:

#### 2) Quantum 10 veces más corto: