Template: debconf/showold
Type: boolean
Default: false
Description: Show all old questions again and again?
 Debconf normally only asks you any given question once. Then it remembers
 your answer and never asks you that question again. If you prefer, debconf
 can ask you questions over and over again, each time you upgrade or
 reinstall a package that asks them.
 .
 Note that no matter what you choose here, you can see old questions again
 by using the dpkg-reconfigure program.
Description-ru: Всегда задавать старые вопросы?
 Debconf  обычно  задает  конкретный  вопрос  только один раз. Затем он
 запоминает  ответ на него и больше не задает этот вопрос. Если хотите,
 то  debconf может задавать одни и те же вопросы при каждых обновлениях
 или переустановках пакетов.

Template: debconf/priority
Type: select
Choices: critical, high, medium, low
Default: medium
Description: Ignore questions with a priority less than..
 Packages that use debconf for configuration prioritize the questions they
 might ask you. Only questions with a certain priority or higher are
 actually shown to you; all less important questions are skipped.
 .
 You can select the lowest priority of question you want to see:
   - 'critical' is for items that will probably break the system
     without user intervention.
   - 'high' is for items that don't have reasonable defaults.
   - 'medium' is for normal items that have reasonable defaults.
   - 'low' is for trivial items that have defaults that will work in the
     vast majority of cases.
 .
 For example, this question is of medium priority, and if your priority
 were already 'high' or 'critical', you wouldn't see this question.
 .
 If you are new to the Debian GNU/Linux system choose 'critical' now, so
 you only see the most important questions.
Choices-ru: критичный, высокий, средний, низкий
Description-ru: Игнорировать вопросы с приоритетом меньше, чем..
 Пакеты,  которые  используют  debconf,  используют систему приоритетов
 вопросов,  которые  они вам задают. Вам будут показаны только вопросы,
 имеющие  приоритет  равный  или  выше  указанного;  вопросы  с меньшим 
 приоритетом будут пропущены.
 .
 Вы можете выбирать приоритеты:
   - 'критичный' - это те пункты, которые могут навредить  системе  без
     вмешательства пользователя.
   - 'высокий' - для пунктов, не имеющие разумных значений по умолчанию.
   - 'средний' - пункты, которые имеют разумные значения по умолчанию.
   - 'низкий' - пункты,  которые имеют разумные значения  по  умолчанию,
     работоспособные в подавляющем большинстве случаев.
 .
 Например, этот вопрос имеет средний  приоритет,  и  если  вы  выберете
 приоритет  'высокий'  или  'критичный',  то  этот  вопрос вы впредь не 
 увидите.
 .
 Если вы новичок в Debian GNU/Linux, то сейчас выберите 'критичный',  и
 вам будут показаны только наиболее важные вопросы.

Template: debconf/frontend
Type: select
Choices: Dialog, Readline, Gnome, Editor, Noninteractive
Default: Dialog
Description: What interface should be used for configuring packages?
 Packages that use debconf for configuration share a common look and feel.
 You can select the type of user interface they use.
 .
 The dialog frontend is a full-screen, character based interface, while the
 readline frontend uses a more traditional plain text interface, and the
 gnome frontend is a modern X interface. The editor frontend lets you
 configure things using your favorite text editor. The noninteractive
 frontend never asks you any questions.
Choices-ru: диалог, строка ввода, Gnome, редактор, неинтерактивный
Description-ru: Какой интерфейс нужно использовать для настройки пакетов?
 Пакеты,  которые  используют debconf, для настройки будут использовать
 единый интерфейс. Вы можете выбрать наиболее подходящий.
 .
 Диалоговая  оболочка  -  полноэкранная,  в то время как "строка ввода"
 использует более  традиционный  простой текстовый интерфейс, а Gnome -
 современный  X интерфейс.  Редактор  позволит вам задавать настройки в
 вашем   любимом   редакторе.  Неинтерактивный  режим  избавит  вас  от
 необходимости отвечать на какие-либо вопросы.
