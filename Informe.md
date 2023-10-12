# Informe Lab 3

## Integrantes:
 - Ramiro Lugo Viola

## Primera Parte: Estudiando el planificador de xv6-riscv y respondiendo preguntas

#### Preguntas
1. ¿Qué política de planificación utiliza xv6-riscv para elegir el próximo proceso a ejecutarse? Pista: xv6-riscv nunca sale de la función scheduler por medios “normales”.
2. ¿Cuánto dura un quantum en xv6-riscv?
3. ¿Cuánto dura un cambio de contexto en xv6-riscv?
4. ¿El cambio de contexto consume tiempo de un quantum?
5. ¿Hay alguna forma de que a un proceso se le asigne menos tiempo? Pista: Se puede empezar a buscar desde la system call uptime.
6. ¿Cúales son los estados en los que un proceso pueden permanecer en xv6-riscv y que los hace cambiar de estado?

#### Respuestas
1. 