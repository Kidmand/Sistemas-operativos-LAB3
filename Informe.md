# Informe Lab 3

## Integrantes:
 - Ramiro Lugo Viola
 - Matias Viola Di Benedetto
 - Daián García Giménez 
 - Mora Syczyk

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
3. ❌ ¿Cuánto dura un cambio de contexto en xv6-riscv? (TERMINAR)
4. ✅ ¿El cambio de contexto consume tiempo de un quantum? 
5. ✅ ¿Hay alguna forma de que a un proceso se le asigne menos tiempo?
6. ✅ ¿Cúales son los estados en los que un proceso pueden permanecer en xv6-riscv y que los hace cambiar de estado?

Las interrupciones de tiempo se hacer siempre cada un quantum, sin importar nada, es decir cada 1 segundo por ejemplo hace una interrupcion.

#### Respuestas
1. La politica de planificación que utliza xv6-riscv Round Robin. <br/>
   Nos dimos cuenta, por la funcion `void scheduler(void)` implementada en `kernel/proc.c` y la presencia del timer (quantum).
2. Un quantum en xv6-riscv dura 1/10 de segundo. <br/>
   Nos dimos cuenta por la funcion `void timerinit()` implementada en `kernel/start.c`.
3. La manera en la  que pudimos encontrar el tiempo del cambio de contexto es: sabiendo que el quantum contiene el cambio de contexto. Podemos ir     reduciéndolo hasta que deje de ejecutar el propio sistema operativo: idem, hasta que no pueda ejecutar siquiera una instrucción.
  Finalmente el cambio de contexto es aproximadamente:  --❓--
4. Las interrupciones por tiempo se ejecutan siempre en el mismo intervalo y nunca se detiene. Como nadie interfiere, el cambio de contexto está contenido en el quantum. 
5. Si hay una manera, por ejemplo: si tenemos un quantum de 10 segundos y hay un proceso que se ejecuta por 5 segundos y hay una interrupción, comienza a ejecutarse otro porceso y se le asigna el tiempo que queda al quantum por terminar. 

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
Contabilizar las veces que es elegido un proceso por el planificador y analizar cómo el planificador afecta a los procesos.

¿Cómo lo hicimos?

Agregamos dos campos al `struc proc`, esto son:
   - `cantselect`: Cuenta cada vez que entra el proceso en el sheduler y se inizializa en 0 en `userinit` y se libera en  `freeproc`. (¿ procinit ?) 
   - `lastexect`: Utilizamos una idea similar a la que se una en iobench y cpubench en la función `time()`.
   - `priority`: No existe en RR.

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
