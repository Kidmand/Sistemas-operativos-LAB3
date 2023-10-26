# Informe Lab 3

## Integrantes:
 - Ramiro Lugo Viola
 - Matias Viola Di Benedetto
 - Daián García Giménez 
 - Mora Syczyk

## Primera Parte: 
Estudiando el planificador de xv6-riscv y respondiendo preguntas.

#### Preguntas
1. ✅ ¿Qué política de planificación utiliza xv6-riscv para elegir el próximo proceso a ejecutarse?
2. ✅ ¿Cuánto dura un quantum en xv6-riscv?
3. ✅ ¿Cuánto dura un cambio de contexto en xv6-riscv? (TERMINAR)
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
Finalmente, luego de ir cambiando el quantum, obtuvimos que a partir de un quantum de 2000, empieza a fallar algunas veces. Con un quantum menor que 350, deja de funciónar todo. Por lo tanto, el cambio de contexto es aproximadamente de 350.
1. Las interrupciones por tiempo se ejecutan siempre en el mismo intervalo y nunca se detiene. Como nadie interfiere, el cambio de contexto está contenido en el quantum. 
2. Si hay una manera, por ejemplo: si tenemos un quantum de 10 segundos y hay un proceso que se ejecuta por 5 segundos y hay una interrupción, comienza a ejecutarse otro porceso y se le asigna el tiempo que queda al quantum por terminar. 

3. Encontramos en `kernel/proc.h` lo siguiente: <br/>
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
   - RUNNING: El único lugar donde se setea es en el `sheduler` que cambia de RUNNABLE a RUNNING.
   - ZOMBIE: En `exit` se setea el proceso en ZOMBIE.

## Segunda Parte: 
Contabilizar las veces que es elegido un proceso por el planificador y analizar cómo el planificador afecta a los procesos.

¿Cómo lo hicimos?
Agregamos dos campos al `struc proc`, esto son:
   - `cantselect`: Cuenta cada vez que entra el proceso en el sheduler y se inizializa en 0 en `userinit` y se libera en  `freeproc`.
   - `lastexect`: Utilizamos una idea similar a la que se una en iobench y cpubench en la función `time()`.
   - `priority`: No existe en RR.
  
Para realizar los distintos escenarios, lo automatizamos con el programa `mediciones/ejecutar_medicion.sh` y para calcular los promedios usamos `mediciones/calcular_promedios.sh` . 

#### 1) Quantum normal:
Todos los escenarios fueron ejecutados con el comando `make CPUS=1 qemu` y en las siguientes condiciones:

| Hardware                              | Quantum | Politica Scheduler | Cantidad de CPU | Software   |
| ------------------------------------- | ------- | ------------------ | --------------- | ---------- |
| Intel(R) Core(TM) i7-10870H  2.21 GHz | 1000000 | Round Robin        | 1               | Qemu 6.2.0 |

##### ✅**Escenario 1:** <br/>
  El comando ejecutado fue `iobench` y se recopiló la siguiente información:

  | Parámetro          |  Valor  |
  | :----------------- | :-----: |
  | Promedio OPW /100T | 6117.21 |
  | Promedio OPR /100T | 6117.21 |
  | Cant. select       | 383710  |
  | Last exect         |  2009   |

  **Conclusión:** <br/>
  El proceso iobench está ejecutando prácticamente solo en el SO, por lo tanto puede hacer muchas operaciones de R/W. Además tiene sentido que cantselect sea grande porque nunca supera el quantum y se produce una interrupción cada vez que hay un R/W. Además se ve una clara diferencia en la cantidad de operaciones respecto al segundo escenario. <br/>
  **Output del escenario**: `mediciones/medicion_1.txt` .

##### ✅**Escenario 2:**<br/>
  El comando ejecutado fue `cpubench` y se recopiló la siguiente información:

  | Parámetro          |  Valor  |
  | :----------------- | :-----: |
  | Promedio MFLOP100T | 837.562 |
  | Cant. select       |  2121   |
  | Last exect         |  2025   |

  **Conclusión:** <br/>
  El proceso cpubench está ejecutando prácticamente solo en el SO, y al ser cpu-bound siempre consume el quantum. Por esta razón, cantselect es similar a lastexect. Además se ve una clara diferencia en la cantidad de operaciones respecto al caso uno. <br/>
  **Output del escenario**: `mediciones/medicion_2.txt` .

##### ✅**Escenario 3:** <br/>
  El comando ejecutado fue `iobench & ; cpubench &` y se recopiló la siguiente información:

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
  El comando ejecutado fue `cpubench & ; cpubench &` y se recopiló la siguiente información:

  | Parámetro                       |  Valor  |
  | :------------------------------ | :-----: |
  | Promedio MFLOP100T (cpubench-1) | 1014.65 |
  | Promedio MFLOP100T (cpubench-2) | 1021.76 |
  | Cant. select       (cpubench-1) |  1063   |
  | Cant. select       (cpubench-2) |  1053   |
  | Last exect         (cpubench-1) |  2018   |
  | Last exect         (cpubench-2) |  2012   |

  **Conclusión:** <br/>
  Al tener dos procesos cpubench tiene sentido que se consuma constantemente el quantum, por esta razón se da que lastexect sea el doble que cantselect, justamente tenemos dos procesos cpu-bound. Nuevamente, se ve una gran cantidad de operaciones. <br/>
  **Output del escenario**: `mediciones/medicion_4.txt` .

##### ✅**Escenario 5:** <br/>  
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
  Nuevamente tenemos la misma situación que en el escenario 4 respecto a los `cpubench`. Dónde podemos notar algo interesante es en la cantidad de R/W que puede hacer `iobench`, esto sucede por algo similar a lo que pasa en el escenario 3. Nuevamente, para que se ejecute `iobench` tiene que esperar a los procesos `cpubench` que consuman su quantum. Podemos ver que incluso la cantidad de R/W es casi la mitad que en el escenario 3. Esto se debe a que, justamente, hay el doble de procesos. `cpubench`.<br/>
  **Output del escenario**: `mediciones/medicion_5.txt` .


#### 2) Quantum 10 veces más corto: 
Todos los escenarios fueron ejecutados con el comando `make CPUS=1 qemu` y en las siguientes condiciones:

| Hardware                              | Quantum | Politica Scheduler | Cantidad de CPU | Software   |
| ------------------------------------- | ------- | ------------------ | --------------- | ---------- |
| Intel(R) Core(TM) i7-10870H  2.21 GHz | 100000  | Round Robin        | 1               | Qemu 6.2.0 |

Aclaración, para hacer este test se modificó la variable `interval` en `kernel/start.c:69`

##### ✅**Escenario 1:**<br/>
  El comando ejecutado fue `iobench` y se recopiló la siguiente información:

  | Parámetro          |  Valor  |
  | :----------------- | :-----: |
  | Promedio OPW /100T | 6224.84 |
  | Promedio OPR /100T | 6224.84 |
  | Cant. select       | 399548  |
  | Last exect         |  2008   |

  **Conclusión:** <br/>
  Podemos ver que prácticamente no hay diferencias respecto al escenario 1 con el quantum normal. Esto sucede porque, justamente al ser I/O, nunca se termina de consumir el quantum.<br/>
  **Output del escenario**: `mediciones/q-10_medicion_1.txt` .

##### ✅**Escenario 2:**<br/>
  El comando ejecutado fue `cpubench` y se recopiló la siguiente información:

  | Parámetro          | Valor |
  | :----------------- | :---: |
  | Promedio MFLOP100T |  837  |
  | Cant. select       | 21169 |
  | Last exect         | 2027  |

  **Conclusión:** <br/>
  En este escenario sí podemos notar una diferencia respecto al escenario 2 del quantum normal. Tenemos que se aumentó en un factor de 10 aproximadamente la cantidad de veces que fue seleccionado.  Esto sucede porque el proceso es cpu-bound y consume constantemente el quantum, el cual se redujo en un factor de 10. <br/>
  **Output del escenario**: `mediciones/q-10_medicion_2.txt` . 

##### ✅**Escenario 3:** <br/>
  El comando ejecutado fue `iobench & ; cpubench &` y se recopiló la siguiente información:

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
  Podemos ver respecto al escenario 3 del quantum normal que el proceso `cpubench` se ejecuta muy parecido aunque hay una leve reducción de operaciones debido a que ejecuta más iobench justamente el mayor cambio se observan en el proceso `iobench`, el cual aumentó en un factor de 10 la cantidad de R/W, esto sucede porque como tiene que esperar al proceso `cpubench` complete un quantum, esta vez tendrá que esperar 10 veces menos. <br/>
  **Output del escenario**: `mediciones/q-10_medicion_3.txt` .

##### ✅**Escenario 4:** <br/>
  El comando ejecutado fue `cpubench & ; cpubench &` y se recopiló la siguiente información:

  | Parámetro                       |  Valor  |
  | :------------------------------ | :-----: |
  | Promedio MFLOP100T (cpubench-1) | 1000.94 |
  | Promedio MFLOP100T (cpubench-2) | 996.333 |
  | Cant. select       (cpubench-1) |  10528  |
  | Cant. select       (cpubench-2) |  10567  |
  | Last exect         (cpubench-1) |  2016   |
  | Last exect         (cpubench-2) |  2020   |

  **Conclusión:** <br/>
  Podemos ver que los resultados en el "Promedio MFLOP100T" de los procesos `cpubench` prácticamente no cambiaron respecto al escenario 4 del quantum normal, pero si cambiaron en la cantidad de veces que fue selecionado, similar al escenario 2 aumentaron en un factor de 10 y lo interesante es que mantentiene que lastexect * 10 es el doble que los cantselect como en el escenario del quantum normal. <br/> 
  **Output del escenario**: `mediciones/q-10_medicion_4.txt` .

##### ✅**Escenario 5:** <br/>  
  El comando ejecutado fue `cpubench & ; cpubench & ; iobench &` y se recopiló la siguiente información:

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
  Podemos ver que los datos se relacionan bastante con lo ocurrido en los otros escenarios. Los `cpubench` se ejecutan similar al escenario 5 con quantum normal, solo que se aumentó en un factor de 10 la cantidad de veces que fue seleccionado. Con el proceso `iobench` simplemente aumentaron los datos en un factor de 10 respecto a la ejecución del escenario 5 con quantum normal, justamente debido a que se redujo el quantum y se ejecuta más veces. <br/>
  **Output del escenario**: `mediciones/q-10_medicion_5.txt` .


## Tercera Parte:
**Rastreando la prioridad de los procesos**

### Aclaraciónde nuestra implementación:
Consideramos a `0` como la mayor prioridad (en este inician todos los procesos) y los numeros mayores a `0` como menor prioridad (ejemplo: 2 tiene menor prioridad que 1).

### ✅Implementando la regla 3: 
**MLFQ regla 3:** Cuando un proceso se inicia, su prioridad será minima. <br/>
Esto se puede hacer en `kernel/proc.c` en la función `allocproc()` luego de que el proceso se asigne en la tabla de procesos.
``` c
found:
p->pid = allocpid();
p->state = USED;
p->priority = 0;
```
Luego en `freeproc()` también se agrego que la prioridad cambie a 0, para que luego inicie en 0.

### ✅Implementando la regla 4:
**MLFQ regla 4:**
1) Ascender de prioridad cada vez que el proceso pasa todo un quantum realizando cómputo. 
2) Descender de prioridad cada vez que el proceso se bloquea antes de terminar su quantum.

Para hacer esto usamos una aritmetica con los ticks, que cuentan la cantida de interrupciones. En la función `sheduler`, cuando iniciamos el proceso almacenamos el valor de los ticks (en `ticks_first_run`) y finalmente despues de que se ejecutó comparamos con los tiks actuales.
Si son iguales es porque no hubo interrupciones de tiempo, por lo tanto cedió el cpu y le subimos la prioridad.
Si son diferentes es porque hubieron interrupciones de tiempo, por lo tanto consumió todo un quantum y le bajamos la prioridad. 
``` c
  /* Manejo de prioridades */
  if (ticks == ticks_first_run)
    p->priority = p->priority != 0 ? p->priority - 1 : p->priority; // Que tenga mayor prioridad porque no hubo interrupciones.
  else
    p->priority = p->priority < NPRIO - 1 ? p->priority + 1 : p->priority; // Que tenga menor prioridad porque supero el quantum.
```

Otra opción para la implementación la encontramos al buscar en `kernel/trap.c` para encontrar como detectar si fue una interrupciónde tiempo u otra cosa.
Logramos ver que en las funciónes `usertrap` y `kerneltrap` del archivo `kernel/trap.c`, revisan que hacer si fue un interrupciónde tiempo o de una system call desde espacio de usuario.  Casualmente cuando hay una interupciónde tiempo, se usa la función `yield()`, aca podriamos implementar la reduciónde la prioridad.
Luego para saber si un proceso hizo un cambio de contexto sin consumir el quantum, es lo hecho anteriorimente.
Finalmente decidimos no usar esta porque nos parecia más clara la mencionada al principio.

## Cuarta Parte: 
**Implementamos la planificación para que nuestro xv6-riscv utilice MLFQ.**

### ✅Implementamos la regla 1: 
**MLFQ regla 1:** Si el proceso A tiene mayor prioridad que el proceso B, corre A. (y no B) <br/>
Para esto modificamos en `kernel/proc.c` la función `scheduler` agregando un ciclo que recorre desde los procesos de prioridad más baja a los procesos de prioridada más alta (Como primero se recorren los de prioridad más baja, seran los primeros en consideraciónpara ser seleccionados aplicando la regla 1) una y otra vez hasta que pueda seleccionar a través de la función `select_p` un proceso a ejecutar. <br/>
La función `select_p` por ahora basta decir que se encarga de seleccionar un proceso con la prioridad especificada listo para correr (RUNNABLE).
``` c
void scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  int seguir;

  c->proc = 0;
  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    int priority;
    seguir = 1; // TRUE
    for (priority = 0; priority < NPRIO && seguir; priority++)
    {
      p = select_p(priority); // Selecionamos el proceso con la prioridad especificada.
      if (p != 0) // Si se devolvio un proceso lo corremos.
      {
        execute(c, p); // Ejecutamos el proceso.
        seguir = 0;    // FALSE, termina el while y vuelve mirar los procesos con mayor prioridad.
        release(&p->lock);
      }
    }
  }
}
```

### ✅ Implementamos la regla 2: 
**MLFQ regla 2:** Si dos procesos A y B tienen la misma prioridad, corre el que menos veces fue elegido por el planificador. <br/>

De esta regla se encarga la función antes mencionada `select_p` que no solo busca un proceso de la prioridad pedida listo para correr, si no que también, busca el proceso que menos veces haya sido seleccionado por el planificador (aplicando la regla 2).
``` c
struct proc *select_p(int priority)
{
  struct proc *p, *res_p = 0;
  int min_cantselect = 2147483647; // Inicializamos la variable en el INT MAX

  for (p = proc; p < &proc[NPROC]; p++) // Recorre todos los procesos de la tabla de procesos proc.
  {
    acquire(&p->lock);
    if (p->state == RUNNABLE && p->priority == priority && p->cantselect < min_cantselect)
    {
      if (res_p != 0)
        release(&res_p->lock);
      res_p = p;
      min_cantselect = p->cantselect;
    }
    else
    {
      release(&p->lock);
    }
  }
  return res_p;
}
```
Fue importante en esta función lograr manejar correctamente los locks. Esto lo conseguimos haciendo que la función `select_p()` siempre consulte de forma atómica los procesos, pero que además al único proceso que no se le hace `release` es al que fue selecionado. Por esta razón es importante saber que cuando se sale de esta función ya fue llamada la función `acquire` con el lock del procesos selecionado y en algun momento se va a tener que llamar a `release` de este mismo lock.

### Repetimos las mediciones de la segunda parte para ver las propiedades del nuevo planificador. <br/>

#### 1) Quantum normal:
Todos los escenarios fueron ejecutados con el comando `make CPUS=1 qemu` y en las siguientes condiciones:

| Hardware                              | Quantum | Politica Scheduler | Cantidad de CPU | Software   |
| ------------------------------------- | ------- | ------------------ | --------------- | ---------- |
| Intel(R) Core(TM) i7-10870H  2.21 GHz | 1000000 | MLFQ               | 1               | Qemu 6.2.0 |

##### ✅ **Escenario 1:** <br/>
  El comando ejecutado fue `iobench` y se recopiló la siguiente información:

| Parámetro                       |  Valor  |
| :------------------------------ | :-----: |
| Promedio de OPW100T (iobench-3) | 5401.68 |
| Promedio de OPR100T (iobench-3) | 5401.68 |
| Cant. select        (iobench-3) | 338378  |
| Last exect          (iobench-3) |  2009   |

  **Conclusión:** <br/>
  El proceso iobench esta ejecutando practicamente solo en el SO, por lo tanto puede hacer muchas operaciones de R/W pero no tantas como con el viejo planificador. Esto sucede debido a que el código que requiere el planificador MLFQ es de mayor extensión y complejidad. Luego las demás conclusiones son practicamente idénticas, no hay más cambios. <br/>
  **Output del escenario**: `mediciones/mlfq_medicion_1.txt` .

##### ✅ **Escenario 2:**<br/>
  El comando ejecutado fue `cpubench` y se recopiló la siguiente información:

| Parámetro                       |  Valor  |
| :------------------------------ | :-----: |
| Promedio MFLOP100T (cpubench-3) | 813.312 |
| Cant. select       (cpubench-3) |  2109   |
| Last exect         (cpubench-3) |  2014   |

  **Conclusión:** <br/>
  El proceso cpubench esta ejecutando prácticamente solo en el SO, al ser cpu-bound siempre consume el quantum y baja su prioridad, pero eso no le afecta ya que es el único proceso. El único cambio que hay es la leve disminusión de la cantidad de operaciones con respecto al viejo planificador, esto ocurre nuevamente por el mayor cómputo del nuevo planificador mlfq.  <br/>
  **Output del escenario**: `mediciones/mlfq_medicion_2.txt` .

##### ✅**Escenario 3:** <br/> 
  El comando ejecutado fue `iobench & ; cpubench &` y se recopiló la siguiente información:

| Parámetro                       |  Valor  |
| :------------------------------ | :-----: |
| Promedio de OPW100T (iobench-5) |  35.5   |
| Promedio de OPR100T (iobench-5) |  35.5   |
| Promedio MFLOP100T (cpubench-6) | 831.125 |
| Cant. select        (iobench-5) |  2236   |
| Cant. select       (cpubench-6) |  2112   |
| Last exect          (iobench-5) |  2018   |
| Last exect         (cpubench-6) |  2017   |

  **Conclusión:** <br/>
  Vemos conclusiones iguales al ejercicio dos salvo por: <br/>
  En general hubo una leve disminución de las operaciones, esto sucede nuevamente por el mayor cómputo del planificador MLFQ en comparación al RR. <br/>
  Luego, gracias al planificador, el `iobench` fue seleccionado un par más de veces. Aun así, no fueron demasiadas ya que aunque el `iobench` tiene más prioridad solo hay dos procesos y al ceder el cpu, generalmente no estará listo para correr inmediatamente por lo que se elegirá el `cpubench`. <br/>
  **Output del escenario**: `mediciones/mlfq_medicion_3.txt` .

##### ✅**Escenario 4:** <br/>
  El comando ejecutado fue `cpubench & ; cpubench &` y se recopiló la siguiente información:

| Parámetro                       |  Valor  |
| :------------------------------ | :-----: |
| Promedio MFLOP100T (cpubench-5) | 1027.88 |
| Promedio MFLOP100T (cpubench-6) | 1029.59 |
| Cant. select       (cpubench-5) |  1058   |
| Cant. select       (cpubench-6) |  1055   |
| Last exect         (cpubench-5) |  2017   |
| Last exect         (cpubench-6) |  2013   |

  **Conclusión:** <br/>
  Misma conclusion que en el ejercicio 2. Esto sucede porque al ser solo dos procesos cpubench hay menos cambios de contexto, por esta razón no se nota mucho cambio en los datos y además, al tener la misma prioridad el planificador funciona como un RR. <br/>
  **Output del escenario**: `mediciones/mlfq_medicion_4.txt` .

##### ✅**Escenario 5:** <br/>  
  El comando ejecutado fue `cpubench & ; cpubench & ; iobench &` y se recopiló la siguiente información:

| Parámetro                       |  Valor  |
| :------------------------------ | :-----: |
| Promedio MFLOP100T (cpubench-5) | 995.353 |
| Promedio MFLOP100T (cpubench-7) | 1000.65 |
| Promedio de OPW100T (iobench-8) |  35.5   |
| Promedio de OPR100T (iobench-8) |  35.5   |
| Cant. select       (cpubench-5) |  1060   |
| Cant. select       (cpubench-7) |  1057   |
| Cant. select        (iobench-8) |  2237   |
| Last exect         (cpubench-5) |  2019   |
| Last exect         (cpubench-7) |  2017   |
| Last exect          (iobench-8) |  2020   |

  **Conclusión:** <br/>
  En este escenario se puede apreciar un aumento en la cantidad de veces que se seleccionó el `iobench`, repercutiendo a su vez en el aumento de las operaciones de R/W del mismo. Esto sucede gracias al planificador (por la regla 1 siempre elige el que tiene la mayor prioridad) y a que hay más procesos (a diferencia del escenario 3). <br/> 
  Al haber más de dos procesos, ahora si se puede planificar más pudiendo elegir al `iobench` siempre luego de que termine el `cpubench` duplicando las veces en las que es elegido. 

  **Output del escenario**: `mediciones/mlfq_medicion_5.txt` .

#### 2) Quantum disminuido:

Todos los escenarios fueron ejecutados con el comando `make CPUS=1 qemu` y en las siguientes condiciones:

| Hardware                              | Quantum | Politica Scheduler | Cantidad de CPU | Software   |
| ------------------------------------- | ------- | ------------------ | --------------- | ---------- |
| Intel(R) Core(TM) i7-10870H  2.21 GHz | 1000000 | MLFQ               | 1               | Qemu 6.2.0 |

##### ✅**Escenario 1:** <br/>
  El comando ejecutado fue `iobench` y se recopiló la siguiente información:

| Parámetro                       |  Valor  |
| :------------------------------ | :-----: |
| Promedio de OPW100T (iobench-3) | 5451.05 |
| Promedio de OPR100T (iobench-3) | 5451.05 |
| Cant. select        (iobench-3) | 349830  |
| Last exect          (iobench-3) |  2008   |

  **Conclusión:** <br/>
  Al ser `iobench` nunca termina el quantum y su prioridad se mantiene alta por lo que tenemos el mismo resultado que al ejecutar el escenario con RR, unicamente se dismunyen un poco las operaciones de R/W por el cómputo de la ejecución del planificador MLFQ.  <br/>
  **Output del escenario**: `mediciones/mlfq_q-10_medicion_1.txt` .

##### ✅**Escenario 2:**<br/>
  El comando ejecutado fue `cpubench` y se recopiló la siguiente información:

| Parámetro                       | Valor  |
| :------------------------------ | :----: |
| Promedio MFLOP100T (cpubench-3) | 846.25 |
| Cant. select       (cpubench-3) | 21193  |
| Last exect         (cpubench-3) |  2029  |

  **Conclusión:** <br/>
  Al ser `cpubench` su prioridad se disminuye pero al estar solo tenemos el mismo resultado que al ejecutarlo en el escenario con RR, únicamente se reducen un poco las MFLOP100T por el cómputo de la ejecución del planificador MLFQ. <br/>
  **Output del escenario**: `mediciones/mlfq_q-10_medicion_2.txt` .

##### ✅**Escenario 3:** <br/> 
  El comando ejecutado fue `iobench & ; cpubench &` y se recopiló la siguiente información:

| Parámetro                       |  Valor  |
| :------------------------------ | :-----: |
| Promedio de OPW100T (iobench-5) | 337.529 |
| Promedio de OPR100T (iobench-5) | 337.529 |
| Promedio MFLOP100T (cpubench-6) | 794.474 |
| Cant. select        (iobench-5) |  21038  |
| Cant. select       (cpubench-6) |  20958  |
| Last exect          (iobench-5) |  2009   |
| Last exect         (cpubench-6) |  2009   |


  **Conclusión:** <br/>
  Podemos ver que no hay cambios respecto al RR y eso sucede por la misma razón que se dice en el escenario 3 sin el quantum reducido, aunque el `iobench` tiene más prioridad solo hay dos procesos y al ceder el cpu, generalmente no estará listo para correr inmediatamente por lo que se elegirá el `cpubench` y asi sucesivamente. 
  Por otra parte vemos que aumentó la cantidad de R/W, ya que el proceso `cpubench` ejecuta menos tiempo e inmediatamente ejecuta el `iobench`. A su vez el `cpubench` se ve un poco reducido porque se ejecutan más `iobench`. Un comportamiento similar al caso de RR con el quantum reducido. <br/>
  
  **Output del escenario**: `mediciones/mlfq_q-10_medicion_3.txt` .

##### ✅**Escenario 4:** <br/>
  El comando ejecutado fue `cpubench & ; cpubench &` y se recopiló la siguiente información:

| Parámetro                       |  Valor  |
| :------------------------------ | :-----: |
| Promedio MFLOP100T (cpubench-5) | 1003.28 |
| Promedio MFLOP100T (cpubench-6) | 1007.5  |
| Cant. select       (cpubench-5) |  10499  |
| Cant. select       (cpubench-6) |  10575  |
| Last exect         (cpubench-5) |  2011   |
| Last exect         (cpubench-6) |  2018   |

  **Conclusión:** <br/>
  Respecto a RR, se comporta de la misma forma poque tenemos dos procesos `cpubench` que se mantienen en la misma prioridad. Por otra parte al reducir quantum genera que se hagan menos operaciones MFLOP100T, incluso hay una diferencia con RR por el cómputo de la ejecución del planificador MLFQ. <br/>

  **Output del escenario**: `mediciones/mlfq_q-10_medicion_4.txt` .

##### ✅**Escenario 5:** <br/>  
  El comando ejecutado fue `cpubench & ; cpubench & ; iobench &` y se recopiló la siguiente información:

| Parámetro                       |  Valor  |
| :------------------------------ | :-----: |
| Promedio MFLOP100T (cpubench-5) | 871.421 |
| Promedio MFLOP100T (cpubench-7) |   824   |
| Promedio de OPW100T (iobench-8) | 337.529 |
| Promedio de OPR100T (iobench-8) | 337.529 |
| Cant. select       (cpubench-5) |  10492  |
| Cant. select       (cpubench-7) |  10564  |
| Cant. select        (iobench-8) |  21034  |
| Last exect         (cpubench-5) |  2011   |
| Last exect         (cpubench-7) |  2018   |
| Last exect          (iobench-8) |  2014   |

  **Conclusión:** <br/>
  Podemos ver un comportamiento similar al escenario ejecutado con el quantum original, los `iobench` tiene mayor prioridad y ejecutan más veces por el planificador MLFQ. La principal difrencia se ve en la reducción de MFLOP100T en los procesos `cpubench`. Esto sucede porque al tener el quantum más chico ejecutan durente menos tiempo y ejecutan más veces el `iobench`, lo cual es otra razón por la que aumentan las R/W de estos procesos. <br/>

  **Output del escenario**: `mediciones/mlfq_q-10_medicion_5.txt` .


### Análisis: ¿Se puede producir starvation en el nuevo planificador?
La *starvation* o *"inanición"* es un problema de planificación de procesos en el que un proceso no recibe tiempo de CPU durante un período prolongado de tiempo. Esto ocurre cuando el planificador de procesos selecciona siempre otros procesos para ejecutarse, dejando al proceso hambriento sin tiempo de CPU.

En esta implementación de reglas se encuentra el problema de *starvation*. Esto es debido a que siempre que existe un proceso listo para correr de mayor prioridad, no se ejecutará ningún proceso listo para correr de menor prioridad por la *regla 1*.<br/>
Por lo tanto, siempre que haya procesos que se mantengan en la prioridad más alta (como por ejemplo los io-bound) listos para correr, los procesos con prioridad más baja (como por ejemplo los cpu-bound) se morirán de hambre. Habran procesos que nunca accederan al CPU luego de consumir por primera vez su quantum subiendo de prioridad por la *regla 4.1*.

Para demostrarlo probamos ejecutar el escenario `cpubench & ;  iobench & ;  iobench & ; iobench &`, en teoria el proceso `cpubench` debria morirse de hambre porque se encuentran ejecutando los procesos `iobench`. Lo ejeuctamos y se recopiló la siguiente información:

| Parámetro                        |  Valor  |
| :------------------------------- | :-----: |
| Promedio de OPW100T (iobench-9)  |  54,8   |
| Promedio de OPR100T (iobench-9)  |  54,8   |
| Promedio de OPW100T (iobench-5)  |    0    |
| Promedio de OPR100T (iobench-5)  |    0    |
| Promedio de OPW100T (iobench-7)  |    0    |
| Promedio de OPR100T (iobench-7)  |    0    |
| Promedio MFLOP100T (cpubench-10) | 848,118 |
| Cant. select        (iobench-9)  |  2210   |
| Cant. select        (iobench-5)  |   396   |
| Cant. select        (iobench-7)  |   427   |
| Cant. select       (cpubench-10) |  2164   |
| Last exect          (iobench-9)  |  2032   |
| Last exect          (iobench-5)  |  2033   |
| Last exect          (iobench-7)  |  2033   |
| Last exect         (cpubench-10) |  2032   |

  **Conclusión:** <br/>
  En la practica podemos ver que no se cumple nuestra hipótesis teorica. Por ejemplo, el `cpubench` no es el ultimo proceso en terminar y esto no deberia ser asi. A su vez, solo uno de los tres iobench logra hacer operaciones de R/W, este suceso es inesperado ya que dos cambian su estado a sleep permanentemente y quizas por esto no se cumple la hipótesis propuesta. 

  **Output del escenario**: `mediciones/mlfq_medicion_6.txt` .