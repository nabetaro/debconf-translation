Template: debconf/frontend
Type: select
Choices: Slang, Text, Editor, Dialog, Noninteractive
Choices-es: Slang, Texto, Editor, Dialog, No-interactiva
Default: Slang
Description: What interface should be used for configuring packages?
 Packages that use debconf for configuration share a common look and feel.
 You can select the type of user interface they use. 
 .
 The slang frontend provides a colorful, full-screen, character based
 windowing interface, while the text frontend uses a more traditional plain
 text interface. The editor frontend lets you configure things using your
 favorite text editor. The noninteractive frontend never asks you any
 questions.
Description-es: ¿Qué interfaz debo usar para configurar los paquetes?
 Puede escoger el tipo de interfaz de usuario que usar.
 .
 Slang suministra una interfaz de ventanas de texto, a color, a pantalla
 completa. Texto es una interfaz tradicional, de solo texto. Editor le 
 permite configurar el sistema usando su editor favorito. No-interactiva
 no hace ninguna pregunta.

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

Template: debconf/preconfig
Type: boolean
Default: true
Description: Pre-configure packages before they are installed?
 Debconf can be used to configure packages before they are installed by apt.
 This lets you answer most questions a package would ask at the beginning of
 the install, so you do not need to be around to answer questions during the
 rest of the install. 
Description-es: ¿Preconfigurar los paquetes antes de instalarlos?
 Debconf puede usarse para configurar los paquetes antes de instalarlos
 con apt. Esto le permite contestar al comenzar la instalación a la
 mayoría de las preguntas que le haría un paquete, de manera que no tenga
 que estar atento para responder preguntas durante el resto de la
 instalación.

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

Template: debconf/switch-to-slang
Type: boolean
Default: true
Description: Switch to the new, full-freatured slang frontend?
 You are currently using debconf's dialog frontend. This frontend has been
 superceded by a new frontend, called the slang frontend, that does
 everything the dialog frontend does and more. It lets you see and answer
 multiple questions at a time, and is generally more flexable and pleasant
 to use. If you'd like, you can switch to that frontend now. 
Description-es: ¿Cambiar a la nueva interfaz, basada en slang?
 Actualmente está usando la interfaz dialog de debconf. Esta interfaz ha
 sido suplantada por un nuevo interfaz, llamado interfaz slang, que hace
 todo lo que hace dialog y más. Le permite ver y responder a múltiples
 preguntas a la vez, y es en general más flexible y confortable de usar.
 Si lo desea, puede cambiar a ese interfaz ahora.

Template: debconf/helpvisible
Type: boolean
Default: true
Description: Should debconf display extended help for questions?
 Debconf can display extended help for questions. Some frontends allow this
 display to be turned off, which may make them run a bit faster, or be less
 cluttered. This is mostly useful for experts. 
Description-es: ¿Debe debconf mostrar ayuda extendida para las preguntas?
 Debconf puede mostrar ayuda extendida para las preguntas. Algunos
 interfaces permiten desactivar esto, lo que hara que se ejecuten algo
 más rápido o estén menos congestionados. Esto es útil principalmente
 para los expertos.
