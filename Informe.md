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
3. ❓ ¿Cuánto dura un cambio de contexto en xv6-riscv? (TERMINAR)
4. ✅ ¿El cambio de contexto consume tiempo de un quantum? 
5. ✅ ¿Hay alguna forma de que a un proceso se le asigne menos tiempo?
6. ✅ ¿Cúales son los estados en los que un proceso pueden permanecer en xv6-riscv y que los hace cambiar de estado?

Las interrupciones de tiempo se hacer siempre cada un quantum, sin importar nada, es decir cada 1 segundo por ejemplo hace una interrupción.

#### Respuestas
1. La política de planificación que utliza xv6-riscv Round Robin. <br/>
   Nos dimos cuenta, por la función `void scheduler(void)` implementada en `kernel/proc.c` y la presencia del timer (quantum).
2. Un quantum en xv6-riscv dura 1/10 de segundo. <br/>
   Nos dimos cuenta por la función `void timerinit()` implementada en `kernel/start.c`.
3. Podemos encontrar el tiempo del cambio de contexto sabiendo que el quantum contiene el cambio de contexto. Para ello, vamos reduciendo el quantum hasta que el sistema operativo no pueda ejecutarse: idem, hasta que no pueda ejecutar siquiera una instrucción.<br>
❓Finalmente, luego de ir cambiando el quantum, obtuvimos que a partir de un quantum de 2000, empieza a fallar algunas veces. Con un quantum menor que 350, deja de funcionar todo. Por lo tanto, el cambio de contexto es aproximadamente de 350.❓
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
  
Para realizar los distintos escenarios, lo automatizamos con el programa `mediciones/ejecutar_medicion.sh` y para calcular los promedios usamos `mediciones/calcular_promedios.sh` . 

#### 1) Quantum normal:
Todos los escenarios fueron ejecutados con el comando `make CPUS=1 qemu` y en las siguientes condiciones:

| Hardware                              | Quantum | Politica Scheduler | Cantidad de CPU | Software   |
| ------------------------------------- | ------- | ------------------ | --------------- | ---------- |
| Intel(R) Core(TM) i7-10870H  2.21 GHz | 1000000 | Round Robin        | 1               | Qemu 6.2.0 |

##### ✅ **Escenario 1:** <br/>
  El comando ejecutado fue `iobench` y se recopilo la siguiente información:

  | Parámetro          |  Valor  |
  | :----------------- | :-----: |
  | Promedio OPW /100T | 6117.21 |
  | Promedio OPR /100T | 6117.21 |
  | Cant. select       | 383710  |
  | Last exect         |  2009   |

  **Conclusión:** <br/>
  El proceso iobench está ejecutando prácticamente solo en el SO, por lo tanto puede hacer muchas operaciones de R/W. Además tiene sentido que cantselect sea grande porque nunca supera el quantum y se produce una interrupción cada vez que hay un R/W. Además se ve una clara diferencia en la cantidad de operaciones respecto al segundo escenario. <br/>
  **Output del escenario**: `mediciones/medicion_1.txt` .

##### ✅ **Escenario 2:**<br/>
  El comando ejecutado fue `cpubench` y se recopiló la siguiente información:

  | Parámetro          |  Valor  |
  | :----------------- | :-----: |
  | Promedio MFLOP100T | 837.562 |
  | Cant. select       |  2121   |
  | Last exect         |  2025   |

  **Conclusión:** <br/>
  El proceso cpubench está ejecutando prácticamente solo en el SO, y al ser cpu-bound siempre consume el quantum. Por esta razón, cantselect es similar a lastexect. Además se ve una clara diferencia en la cantidad de operaciones respecto al caso uno. <br/>
  **Output del escenario**: `mediciones/medicion_2.txt` .

##### ✅❓**Escenario 3:** <br/>
  El comando ejecutado fue `iobench & ; cpubench &` y se recopilo la siguiente información:

  | Parámetro               |  Valor  |
  | :---------------------- | :-----: |
  | Promedio OPW /100T      |  36.1   |
  | Promedio OPR /100T      |  36.1   |
  | Promedio MFLOP100T      | 841.438 |
  | Cant. select (iobench)  |  2216   |
  | Cant. select (cpubench) |  2112   |
  | Last exect   (iobench)  |  2018   |
  | Last exect   (cpubench) |  2017   |

  **Conclusión:** <br/>
  Podemos ver que `cpubench` se comporta similar que ejecutando solo, pero `iobench` decrementó mucho la cantidad de R/W.  Esto sucede porque `iobench` tiene que esperar que `cpubench` complete un quantum para poder volver a ejecutar. En el escenario 1 se puede ver como en un intervalo de tiempo `iobench` puede ejecutar muchas R/W porque no tiene que esperar a nadie, simplemente, cuando termina vuelve a ejecutar. <br/>
  **Output del escenario**: `mediciones/medicion_3.txt` .

##### ✅ **Escenario 4:** <br/>
  El comando ejecutado fue `cpubench & ; cpubench &` y se recopilo la siguiente información:

  | Parámetro                       |  Valor  |
  | :------------------------------ | :-----: |
  | Promedio MFLOP100T (cpubench-1) | 1014.65 |
  | Promedio MFLOP100T (cpubench-2) | 1021.76 |
  | Cant. select       (cpubench-1) |  1063   |
  | Cant. select       (cpubench-2) |  1053   |
  | Last exect         (cpubench-1) |  2018   |
  | Last exect         (cpubench-2) |  2012   |

  **Conclusión:** <br/>
  Al tener dos procesos cpubench iene sentido que se consuma constantemente el quantum, por esta razón se da que lastexect sea el doble que cantselect, justamente tenemos dos procesos cpu-bound. Nuevamente, se ve una gran cantidad de operaciones. <br/>
  **Output del escenario**: `mediciones/medicion_4.txt` .

##### ✅❓**Escenario 5:** <br/>  
  El comando ejecutado fue `cpubench & ; cpubench & ; iobench &` y se recopiló la siguiente información:

  | Parámetro                       |  Valor  |
  | :------------------------------ | :-----: |
  | Promedio MFLOP100T (cpubench-1) | 1021.18 |
  | Promedio MFLOP100T (cpubench-2) | 1004.35 |
  | Promedio OPW /100T (iobench)    |  18.6   |
  | Promedio OPR /100T (iobench)    |  18.6   |
  | Cant. select       (cpubench-1) |  1057   |
  | Cant. select       (cpubench-2) |  1061   |
  | Cant. select       (iobench)    |  1237   |
  | Last exect         (cpubench-1) |  2012   |
  | Last exect         (cpubench-2) |  2020   |
  | Last exect         (iobench)    |  2021   |

  **Conclusión:** <br/>
  Nuevamente tenemos la misma situación que en el escenario 4 respecto a los `cpubench`. Dónde podemos notar algo interesante es en la cantidad de R/W que puede hacer `iobench`. sto sucede por algo similar a lo que pasa en el escenario 3. Nuevamente, para que se ejecute `iobench` tiene que esperar a los procesos `cpubench` que consuman su quantum. Podemos ver que incluso la cantidad de R/W es casi la mitad que en el escenario 3. Esto se debe a que, justamente, hay el doble de procesos. `cpubench`.<br/>
  **Output del escenario**: `mediciones/medicion_5.txt` .


#### 2) Quantum 10 veces más corto: 
Todos los escenarios fueron ejecutados con el comando `make CPUS=1 qemu` y en las siguientes condiciones:

| Hardware                              | Quantum | Politica Scheduler | Cantidad de CPU | Software   |
| ------------------------------------- | ------- | ------------------ | --------------- | ---------- |
| Intel(R) Core(TM) i7-10870H  2.21 GHz | 100000  | Round Robin        | 1               | Qemu 6.2.0 |

Aclaración, para hacer este test se modificó la variable `interval` en `kernel/start.c:69`

##### ✅❓**Escenario 1:**<br/>
  El comando ejecutado fue `iobench` y se recopilo la siguiente información:

  | Parámetro          |  Valor  |
  | :----------------- | :-----: |
  | Promedio OPW /100T | 6224.84 |
  | Promedio OPR /100T | 6224.84 |
  | Cant. select       | 399548  |
  | Last exect         |  2008   |

  **Conclusión:** <br/>
  Podemos ver que prácticamente no hay diferencias respecto al escenario 1 con el quantum normal. Esto sucede porque, justamente al ser I/O, nunca se termina de consumir el quantum..<br/>
  **Output del escenario**: `mediciones/q-10_medicion_1.txt` .

##### ✅❓**Escenario 2:**<br/>
  El comando ejecutado fue `cpubench` y se recopilo la siguiente información:

  | Parámetro          | Valor |
  | :----------------- | :---: |
  | Promedio MFLOP100T |  837  |
  | Cant. select       | 21169 |
  | Last exect         | 2027  |

  **Conclusión:** <br/>
  En este escenario sí podemos notar una diferencia al escenario 2 del quantum normal. Tenemos que se aumentó en un factor de 10 aproximadamente la cantidad de veces que fue seleccionado.  Esto sucede porque el proceso es cpu-bound y consume constantemente el quantum, el cual se redujo en un factor de 10. <br/>
  **Output del escenario**: `mediciones/q-10_medicion_2.txt` . 

##### ✅❓**Escenario 3:** <br/>
  El comando ejecutado fue `iobench & ; cpubench &` y se recopilo la siguiente información:

  | Parámetro               |  Valor  |
  | :---------------------- | :-----: |
  | Promedio OPW /100T      | 337.176 |
  | Promedio OPR /100T      | 337.176 |
  | Promedio MFLOP100T      | 796.579 |
  | Cant. select (iobench)  |  21035  |
  | Cant. select (cpubench) |  21168  |
  | Last exect   (iobench)  |  2016   |
  | Last exect   (cpubench) |  2029   |

  **Conclusión:** <br/>
  Podemos ver respecto al escenario 3 del quantum normal que el proceso `cpubench` se ejecuta muy parecido, los cambios se observan en el proceso `iobench`, el cual aumentó en un factor de 10 la cantidad de R/W, esto sucede porque como tiene que esperar al proceso `cpubench` complete un quantum, esta vez tendrá que esperar 10 veces menos.<br/>
  **Output del escenario**: `mediciones/q-10_medicion_3.txt` .

##### ✅❓**Escenario 4:** <br/>
  El comando ejecutado fue `cpubench & ; cpubench &` y se recopilo la siguiente información:

  | Parámetro                       |  Valor  |
  | :------------------------------ | :-----: |
  | Promedio MFLOP100T (cpubench-1) | 1000.94 |
  | Promedio MFLOP100T (cpubench-2) | 996.333 |
  | Cant. select       (cpubench-1) |  10528  |
  | Cant. select       (cpubench-2) |  10567  |
  | Last exect         (cpubench-1) |  2016   |
  | Last exect         (cpubench-2) |  2020   |

  **Conclusión:** <br/>
  Podemos ver que los resultados en el "Promedio MFLOP100T" de los procesos `cpubench` prácticamente no cambiaron respecto al escenario 4 del quantum normal, pero si cambiaron en la cantidad de veces que fue selecionado, similar al escenario 2 aumentaron en un factor de 10 y lo interesante es que se sigue manteniendo que una proporción de que lastexect * 10 sea el doble que los lastexet como en el escenario del quantum normal. <br/> 
  **Output del escenario**: `mediciones/q-10_medicion_4.txt` .

##### ✅❓**Escenario 5:** <br/>  
  El comando ejecutado fue `cpubench & ; cpubench & ; iobench &` y se recopilo la siguiente información:

  | Parámetro                       |  Valor  |
  | :------------------------------ | :-----: |
  | Promedio MFLOP100T (cpubench-1) | 870.722 |
  | Promedio MFLOP100T (cpubench-2) | 948.412 |
  | Promedio OPW /100T (iobench)    | 169.529 |
  | Promedio OPR /100T (iobench)    | 169.529 |
  | Cant. select       (cpubench-1) |  10482  |
  | Cant. select       (cpubench-2) |  10551  |
  | Cant. select       (iobench)    |  10638  |
  | Last exect         (cpubench-1) |  2009   |
  | Last exect         (cpubench-2) |  2016   |
  | Last exect         (iobench)    |  2016   |

  **Conclusión:** <br/>
  Podemos ver que los datos se relacionan bastante con lo ocurrido en los otros escenarios. Los `cpubench` se ejecutan similar al escenario 5 con quantum normal, solo que se aumentó, en un factor de 10, la cantidad de veces que fue seleccionado. Con el proceso iobench simplemente aumentó la cantidad en un factor de 10 respecto a la ejecución del escenario 5 con quantum normal.<br/>
  **Output del escenario**: `mediciones/q-10_medicion_5.txt` .


## Tercera Parte:
**Rastreando la prioridad de los procesos**

### Implementando la regla 3: 
**MLFQ regla 3:**
Cuando un proceso se inicia, su prioridad será mínima.
Esto se puede hacer en `kernel/proc.c` en la función `allocproc()` luego de que el proceso se asigne en la tabla de procesos.
```
found:
p->pid = allocpid();
p->state = USED;
p->priority = 0;
```

### Implementando la regla 4:
**MLFQ regla 4:**
1) Ascender de prioridad cada vez que el proceso pasa todo un quantum realizando cómputo. 
2) Descender de prioridad cada vez que el proceso se bloquea antes de terminar su quantum.

Para hacer esto, usamos una aritmética con los ticks, que cuentan la cantidad de interrupciones. En la función `scheduler`, cuando iniciamos el proceso, almacenamos el valor de los ticks (en `ticks_first_run`) y finalmente, después de que se ejecutó, comparamos con los ticks actuales.
Si son iguales, es porque no hubo interrupciones de tiempo, por lo tanto, cedió el CPU y le subimos la prioridad.
Si son diferentes, es porque hubo interrupciones de tiempo, por lo tanto, consumió todo un quantum y le bajamos la prioridad. 
``` c
  /* Manejo de prioridades */
  if (ticks == ticks_first_run)
  p->priority = p->priority != 0 ? p->priority - 1 : p->priority; // Que tenga mayor prioridad porque no hubo interrupciones.
  else
  p->priority = p->priority < NPRIO - 1 ? p->priority + 1 : p->priority; // Que tenga menor prioridad porque supero el quantum.
```
ANDA SI TENEMOS VARIAS CPUS ❓❓❓❓ (revisar).

Otra opción la encontramos al buscar en `kernel/trap.c` para encontrar cómo detectar si fue una interrupción de tiempo o otra cosa.
Logramos ver que en las funciones `usertrap` y `kerneltrap` del archivo `kernel/trap.c`, revisan qué hacer si fue una interrupción de tiempo o de una system call desde espacio de usuario. Casualmente, cuando hay una interrupción de tiempo, se usa la función `yield()`.
Luego, para saber si un proceso hizo un cambio de contexto sin consumir el quantum, es lo hecho anteriormente.

## Cuarta Parte: 