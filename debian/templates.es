Template: debconf/priority
Type: select
Choices: critical, high, medium, low
Choices-es: crítica, alta, media, baja
Default: medium
Description: Ignore questions with a priority less than..
 Packages that use debconf for configuration prioritize the questions they
 might ask you. Only questions with a certain priority or higher are actually
 shown to you; all less important questions are skipped.
 .
 You can select the lowest priority of question you want to see:
   - `critical' is for items that will probably break the system 
     without user intervention.
   - `high' is for items that don't have reasonable defaults.
   - `medium' is for normal items that have reasonable defaults.
   - `low' is for trivial items that have defaults that will work in the
     vast majority of cases.
 For example, this question is of medium priority, and if your priority were
 already `high' or `critical', you wouldn't see this question. 
 .
 If you are new to the Debian GNU/Linux system choose `critical' now,
 so you only see the most important questions. 
Description-es: No mostrar preguntas con una prioridad mejor que..
 Los que paquetes que usan debconf para la configuración le asignan una
 prioridad a las preguntas que hacen. Sólo se mostrarán las preguntas con
 una cierta prioridad o superior; no se mostrarán las preguntas menos
 importantes.
 .
 Puede escoger la prioridad más baja para las preguntas que desea ver:
   - `crítica' es para asuntos que probablemente romperán el sistema si
     el usuario no interviene. 
   - `alta' es para asuntos para los que no hay valores predeterminados
     razonables. 
   - `media' es para asuntos normales, que tienen valores predeterminados
     razonables.
   - `baja' es para asuntos triviales, que tienen valores predeterminados que
     funcionarán en la inmensa mayoría de casos.
 Por ejemplo, esta pregunta es de prioridad media, y si el valor escogido
 para la prioridad fuese `alta' o `crítica', usted no habría visto esta
 pregunta.
 .
 Si usted es un principiante en el sistema Debian GNU/Linux, escoja
 `crítica' por ahora, para ver sólo las preguntas más importantes.

Template: debconf/showold
Type: boolean
Default: false
Description: Show all old questions again and again?
 Debconf normally only asks you any given question once. Then it remembers
 your answer and never asks you that question again. If you prefer, debconf
 can ask you questions over and over again, each time you upgrade or reinstall
 a package that asks them. 
 .
 Note that no matter what you choose here, you can see old questions again by
 using the dpkg-reconfigure program. 
Description-es: ¿Mostrar las preguntas antiguas una y otra vez?
 Normalmente debconf hace una determinada pregunta una sola vez. A partir
 de ahí recuerda su respuesta y no vuelve a repetir la pregunta más. Si
 usted prefiere, debconf puede repetir las preguntas una y otra vez cada
 vez que actualice o reinstale un paquete que las haga.
 .
 Observe que independiente de lo que escoja aquí, puede ver las preguntas
 antiguas de nuevo usando dpkg-reconfigure .
