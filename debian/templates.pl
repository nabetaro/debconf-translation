Template: debconf/frontend
Type: select
Choices: Dialog, Readline, Gnome, Editor, Noninteractive
Choices-pl: Dialog, Readline, Gnome, Edytor, Nieinteraktywny
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
Description-pl: Który interfejs ma byæ u¿ywany do konfigurowania pakietów?
 Konfiguracja pakietów u¿ywaj±cych do tego celu debconf-a ma spójny wygl±d.
 Mo¿esz wybraæ rodzaj interfejsu u¿ytkownika, jaki bêdzie u¿ywany.
 .
 Interfejs dialog to pe³noekranowy interfejs tekstowy, natomiast readline
 u¿ywa bardziej tradycyjnego, zwyk³ego interfejsu tekstowego. Z kolei gnome
 to nowoczesny interfejs u¿ywaj±cy X. Interfejs edytor pozwala konfigurowaæ
 system przy pomocy Twojego ulubionego edytora. Interfejs nieinteraktywny
 nigdy nie zadaje ¿adnych pytañ.

Template: debconf/priority
Type: select
Choices: critical, high, medium, low
Choices-pl: najwy¿szy, wysoki, ¶redni, niski
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
Description-pl: Ignoruj pytania o priorytecie ni¿szym ni¿..
 Pakiety u¿ywaj±ce do konfiguracji systemu debconf nadaj± ka¿demu pytaniu,
 na które wymagaj± odpowiedzi, pewien priorytet. W rzeczywisto¶ci zobaczysz
 tylko pytania o priorytecie wy¿szym lub równym pewnemu ustalonemu;
 wszystkie mniej wa¿ne s± pomijane.
 .
 Mo¿esz ustaliæ najni¿szy priorytet pytañ, które chcesz widzieæ:
   - 'najwy¿szy' obejmuje pytania, od odpowiedzi na które zale¿y poprawna
     praca systemu.
   - 'wysoki' obejmuje pytania, które nie maj± sensownych warto¶ci
     domy¶lnych.
   - '¶redni' obejmuje zwyk³e pytania, które maj± sensowne warto¶ci
     domy¶lne.
   - 'niski' obejmuje ma³o istotne rzeczy, których warto¶ci domy¶lne bêd±
     dzia³aæ w prawie wszystkich przypadkach.
 .
 Na przyk³ad to pytanie ma priorytet ¶redni, wiêc je¶li
 wybra³by¶/wybra³aby¶ wcze¶niej priorytet 'wysoki' albo 'najwy¿szy', nie
 ukaza³oby siê ono.
 .
 Je¶li jeste¶ pocz±tkuj±cym u¿ytkownikiem systemu Debian GNU/Linux wybierz
 poziom 'najwy¿szy', aby widzieæ tylko najwa¿niejsze pytania.

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
Description-pl: Pokazywaæ stare pytania za ka¿dym razem?
 Debconf zazwyczaj zadaje dane pytanie tylko raz. Pó¼niej pamiêta Twoj±
 odpowied¼ i nigdy nie zadaje wiêcej tego samego pytania. Je¶li jednak
 wolisz, debconf mo¿e zadawaæ pytania przy ka¿dej aktualizacji lub
 reinstalacji danego pakietu.
 .
 Zwróæ uwagê, ¿e niezale¿nie od tego jak teraz odpowiesz, zawsze mo¿esz
 zobaczyæ stare pytania przy pomocy komendy dpkg-reconfigure.
